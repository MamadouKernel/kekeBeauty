using Npgsql;
namespace KekeBeauty.Web.Services;
public record Salon(long Id, string Name, string Description, string Location, string Phone, string TimeZone, decimal? Latitude, decimal? Longitude);
public record ServiceOption(long Id, string Name, int Minutes, decimal Price, string Currency);
public record CategoryOption(long Id, string Name);
public record AvailableSlot(DateTime LocalStart);
public sealed class CatalogService(NpgsqlDataSource db)
{
    public async Task<List<Salon>> Search(string query = "", long? id = null, long? category = null)
    {
        await using var command = db.CreateCommand("""
            SELECT e.etablissement_id,e.nom,coalesce(e.description,''),coalesce(co.nom,''),coalesce(e.telephone_service,''),e.fuseau,e.latitude,e.longitude
            FROM kb.annuaire e LEFT JOIN kb.commune co USING(commune_id)
            WHERE (e.nom ILIKE $1 OR co.nom ILIKE $1) AND ($2::bigint IS NULL OR e.etablissement_id=$2)
            AND ($3::bigint IS NULL OR EXISTS (SELECT 1 FROM kb.etablissement_categorie ec
                JOIN kb.categorie c USING(categorie_id)
                WHERE ec.etablissement_id=e.etablissement_id AND ec.categorie_id=$3 AND c.etat='actif'))
            ORDER BY e.nom,e.etablissement_id LIMIT 100
            """);
        command.Parameters.AddWithValue("%" + query.Trim().Replace("\\", "\\\\").Replace("%", "\\%").Replace("_", "\\_") + "%");
        command.Parameters.AddWithValue(NpgsqlTypes.NpgsqlDbType.Bigint,(object?)id ?? DBNull.Value);
        command.Parameters.AddWithValue(NpgsqlTypes.NpgsqlDbType.Bigint,(object?)category ?? DBNull.Value);
        List<Salon> salons=[];
        await using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync()) salons.Add(new(reader.GetInt64(0),reader.GetString(1),reader.GetString(2),reader.GetString(3),reader.GetString(4),reader.GetString(5),reader.IsDBNull(6)?null:reader.GetDecimal(6),reader.IsDBNull(7)?null:reader.GetDecimal(7)));
        return salons;
    }
    public async Task<List<CategoryOption>> Categories()
    {
        await using var command = db.CreateCommand("SELECT categorie_id,nom FROM kb.categorie WHERE etat='actif' ORDER BY nom");
        await using var reader = await command.ExecuteReaderAsync();
        List<CategoryOption> result = [];
        while (await reader.ReadAsync()) result.Add(new(reader.GetInt64(0), reader.GetString(1)));
        return result;
    }
    public async Task<List<ServiceOption>> Services(long salon)
    {
        await using var command = db.CreateCommand("""
            SELECT vv.version_variante_id,p.nom||' — '||v.libelle,vv.duree_minutes,vv.montant,vv.devise
            FROM kb.prestation p JOIN kb.variante v USING(prestation_id)
            JOIN LATERAL(SELECT * FROM kb.version_variante x WHERE x.variante_id=v.variante_id AND x.date_effet<=now() ORDER BY x.date_effet DESC LIMIT 1) vv ON true
            WHERE p.etablissement_id=$1 AND p.etat='actif' AND v.actif ORDER BY p.nom,v.libelle
            """);
        command.Parameters.AddWithValue(salon);
        List<ServiceOption> options=[];
        await using var reader=await command.ExecuteReaderAsync();
        while (await reader.ReadAsync()) options.Add(new(reader.GetInt64(0),reader.GetString(1),reader.GetInt32(2),reader.GetDecimal(3),reader.GetString(4)));
        return options;
    }
    public async Task<List<AvailableSlot>> AvailableSlots(long salon, long[] versions, int days = 14, int limit = 30)
    {
        if (versions.Length is < 1 or > 10) return [];
        await using var command = db.CreateCommand("""
            WITH selected AS (
              SELECT vv.version_variante_id,vv.duree_minutes
              FROM kb.version_variante vv JOIN kb.variante v USING(variante_id) JOIN kb.prestation p USING(prestation_id)
              WHERE vv.version_variante_id=ANY($2) AND p.etablissement_id=$1 AND p.etat='actif' AND v.actif
            ), duration AS (
              SELECT sum(duree_minutes)::int AS minutes,count(*)::int AS selected_count FROM selected
            ), context AS (
              SELECT e.etablissement_id,e.fuseau,p.mode_capacite,d.minutes
              FROM kb.etablissement e CROSS JOIN duration d
              JOIN LATERAL(SELECT mode_capacite FROM kb.politique_rdv pr WHERE pr.etablissement_id=e.etablissement_id AND pr.date_effet<=now() ORDER BY pr.date_effet DESC LIMIT 1) p ON true
              WHERE e.etablissement_id=$1 AND d.selected_count=cardinality($2) AND p.mode_capacite='globale'
            ), candidates AS (
              SELECT c.*,g AS local_start,g+(c.minutes*interval '1 minute') AS local_end,
                     g AT TIME ZONE c.fuseau AS utc_start,(g+(c.minutes*interval '1 minute')) AT TIME ZONE c.fuseau AS utc_end
              FROM context c CROSS JOIN LATERAL generate_series(
                date_trunc('hour',now() AT TIME ZONE c.fuseau)+interval '1 hour',
                (now() AT TIME ZONE c.fuseau)+($3*interval '1 day'), interval '30 minutes') g
            )
            SELECT local_start
            FROM candidates c
            WHERE (
              (EXISTS(SELECT 1 FROM kb.exception_ouverture x WHERE x.etablissement_id=c.etablissement_id AND x.date_concernee=c.local_start::date)
               AND EXISTS(SELECT 1 FROM kb.exception_ouverture x WHERE x.etablissement_id=c.etablissement_id AND x.date_concernee=c.local_start::date AND NOT x.ferme AND c.local_start::time>=x.heure_debut AND c.local_end::time<=x.heure_fin))
              OR
              (NOT EXISTS(SELECT 1 FROM kb.exception_ouverture x WHERE x.etablissement_id=c.etablissement_id AND x.date_concernee=c.local_start::date)
               AND EXISTS(SELECT 1 FROM kb.plage_ouverture po WHERE po.etablissement_id=c.etablissement_id AND po.jour_semaine=extract(isodow from c.local_start)::int AND c.local_start::time>=po.heure_debut AND c.local_end::time<=po.heure_fin))
            )
            AND EXISTS (
              SELECT 1 FROM kb.ressource r
              WHERE r.etablissement_id=c.etablissement_id AND r.nature='globale' AND r.actif
                AND NOT EXISTS(SELECT 1 FROM kb.indisponibilite_ressource i WHERE i.ressource_id=r.ressource_id AND i.debut<c.utc_end AND i.fin>c.utc_start)
                AND COALESCE((SELECT sum(a.quantite) FROM kb.allocation_rdv a JOIN kb.ligne_rdv l USING(rdv_id,numero) JOIN kb.rendez_vous rd USING(rdv_id)
                  WHERE a.ressource_id=r.ressource_id AND rd.etat IN ('en_attente_salon','accepte') AND l.debut<c.utc_end AND l.fin>c.utc_start),0)<r.capacite
            )
            ORDER BY local_start LIMIT $4
            """);
        command.Parameters.AddWithValue(salon);
        command.Parameters.AddWithValue(versions);
        command.Parameters.AddWithValue(days);
        command.Parameters.AddWithValue(limit);
        List<AvailableSlot> slots = [];
        await using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync()) slots.Add(new(reader.GetDateTime(0)));
        return slots;
    }
    public async Task<long> Book(long client,long salon,long[] versions,DateTime utc,string key)
    {
        await using var command=db.CreateCommand("SELECT kb.creer_rdv($1,$2,$3,$4,$5)");
        command.Parameters.AddWithValue(client); command.Parameters.AddWithValue(salon); command.Parameters.AddWithValue(versions);
        command.Parameters.AddWithValue(utc); command.Parameters.AddWithValue(key);
        return (long)(await command.ExecuteScalarAsync())!;
    }
}
