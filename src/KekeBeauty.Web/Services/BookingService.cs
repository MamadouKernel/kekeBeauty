using Npgsql;

namespace KekeBeauty.Web.Services;

public record Booking(long Id, long SalonId, string Salon, string TimeZone, string State, DateTime? Start, bool IsClient, bool CanDecide, bool CanReschedule, long[] Versions);
public record BookingNotification(long Id, long BookingId, string Kind, DateTime OccurredAt, string? Reason);

public sealed class BookingService(NpgsqlDataSource db)
{
    public async Task<List<Booking>> List(long account)
    {
        await using var command = db.CreateCommand("""
            SELECT r.rdv_id,e.etablissement_id,e.nom,e.fuseau,r.etat,(SELECT min(debut) FROM kb.ligne_rdv l WHERE l.rdv_id=r.rdv_id),r.client_id=$1,
                EXISTS(SELECT 1 FROM kb.gerant g JOIN kb.permission_gestion pg USING(gerant_id)
                    WHERE g.compte_id=$1 AND pg.etablissement_id=e.etablissement_id AND pg.permission_code='rdv_decider'),
                r.client_id=$1 AND p.report_client AND r.etat IN ('en_attente_salon','accepte')
                    AND (SELECT min(debut) FROM kb.ligne_rdv l WHERE l.rdv_id=r.rdv_id)>now()+make_interval(mins=>p.delai_report_minutes),
                ARRAY(SELECT l.version_variante_id FROM kb.ligne_rdv l WHERE l.rdv_id=r.rdv_id ORDER BY l.numero)
            FROM kb.rendez_vous r JOIN kb.politique_rdv p USING(politique_id) JOIN kb.etablissement e USING(etablissement_id)
            WHERE EXISTS(SELECT 1 FROM kb.compte WHERE compte_id=$1 AND etat='actif')
              AND (r.client_id=$1 OR EXISTS(SELECT 1 FROM kb.gerant g JOIN kb.permission_gestion pg USING(gerant_id)
                WHERE g.compte_id=$1 AND pg.etablissement_id=e.etablissement_id AND pg.permission_code='rdv_decider'))
            ORDER BY r.cree_le DESC LIMIT 100
            """);
        command.Parameters.AddWithValue(account);
        var rows = new List<Booking>();
        await using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync()) rows.Add(new(reader.GetInt64(0),reader.GetInt64(1),reader.GetString(2),reader.GetString(3),reader.GetString(4),reader.IsDBNull(5)?null:reader.GetDateTime(5),reader.GetBoolean(6),reader.GetBoolean(7),reader.GetBoolean(8),reader.GetFieldValue<long[]>(9)));
        return rows;
    }

    public async Task<List<BookingNotification>> Notifications(long account)
    {
        await using var command = db.CreateCommand("""
            SELECT n.notification_id,ev.rdv_id,ev.nature,ev.survenu_le,ev.motif
            FROM kb.notification n
            JOIN kb.evenement_rdv ev USING(evenement_id)
            WHERE n.destinataire_id=$1 AND n.canal='in_app'
              AND EXISTS(SELECT 1 FROM kb.compte c WHERE c.compte_id=$1 AND c.etat='actif')
            ORDER BY ev.survenu_le DESC,n.notification_id DESC LIMIT 20
            """);
        command.Parameters.AddWithValue(account);
        List<BookingNotification> rows = [];
        await using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync()) rows.Add(new(reader.GetInt64(0), reader.GetInt64(1), reader.GetString(2), reader.GetDateTime(3), reader.IsDBNull(4) ? null : reader.GetString(4)));
        return rows;
    }

    public async Task Act(long booking, long account, string action, string key, string reason)
    {
        var sql = action switch
        {
            "accepter" => "SELECT kb.accepter_rdv($1,$2)",
            "refuser" => "SELECT kb.refuser_rdv($1,$2,$3)",
            "annuler" => "SELECT kb.annuler_rdv($1,$2,$3)",
            _ => throw new ArgumentException("Action inconnue")
        };
        await using var command = db.CreateCommand(sql);
        command.Parameters.AddWithValue(booking); command.Parameters.AddWithValue(account);
        if (action == "annuler") command.Parameters.AddWithValue(key);
        if (action == "refuser") command.Parameters.AddWithValue(reason);
        await command.ExecuteScalarAsync();
    }

    public async Task Reschedule(long booking, long account, DateTime localStart, string key)
    {
        await using var context = db.CreateCommand("SELECT e.fuseau FROM kb.rendez_vous r JOIN kb.politique_rdv p USING(politique_id) JOIN kb.etablissement e USING(etablissement_id) WHERE r.rdv_id=$1");
        context.Parameters.AddWithValue(booking);
        var timeZoneName = (string?)await context.ExecuteScalarAsync() ?? throw new ArgumentException("Rendez-vous inconnu");
        var zone = TimeZoneInfo.FindSystemTimeZoneById(timeZoneName);
        if (zone.IsInvalidTime(localStart) || zone.IsAmbiguousTime(localStart)) throw new ArgumentException("Horaire ambigu");
        await using var command = db.CreateCommand("SELECT kb.reporter_rdv($1,$2,$3,$4)");
        command.Parameters.AddWithValue(booking);
        command.Parameters.AddWithValue(account);
        command.Parameters.AddWithValue(TimeZoneInfo.ConvertTimeToUtc(DateTime.SpecifyKind(localStart, DateTimeKind.Unspecified), zone));
        command.Parameters.AddWithValue(key);
        await command.ExecuteScalarAsync();
    }
}
