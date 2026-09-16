using Npgsql;

namespace KekeBeauty.Web.Services;

public record Booking(long Id, string Salon, string State, DateTime? Start, bool IsClient, bool CanDecide);

public sealed class BookingService(NpgsqlDataSource db)
{
    public async Task<List<Booking>> List(long account)
    {
        await using var command = db.CreateCommand("""
            SELECT r.rdv_id,e.nom,r.etat,(SELECT min(debut) FROM kb.ligne_rdv l WHERE l.rdv_id=r.rdv_id),r.client_id=$1,
                EXISTS(SELECT 1 FROM kb.gerant g JOIN kb.permission_gestion pg USING(gerant_id)
                    WHERE g.compte_id=$1 AND pg.etablissement_id=e.etablissement_id AND pg.permission_code='rdv_decider')
            FROM kb.rendez_vous r JOIN kb.politique_rdv p USING(politique_id) JOIN kb.etablissement e USING(etablissement_id)
            WHERE EXISTS(SELECT 1 FROM kb.compte WHERE compte_id=$1 AND etat='actif')
              AND (r.client_id=$1 OR EXISTS(SELECT 1 FROM kb.gerant g JOIN kb.permission_gestion pg USING(gerant_id)
                WHERE g.compte_id=$1 AND pg.etablissement_id=e.etablissement_id AND pg.permission_code='rdv_decider'))
            ORDER BY r.cree_le DESC LIMIT 100
            """);
        command.Parameters.AddWithValue(account);
        var rows = new List<Booking>();
        await using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync()) rows.Add(new(reader.GetInt64(0),reader.GetString(1),reader.GetString(2),reader.IsDBNull(3)?null:reader.GetDateTime(3),reader.GetBoolean(4),reader.GetBoolean(5)));
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
}
