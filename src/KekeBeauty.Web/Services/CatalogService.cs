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
    public async Task<List<AvailableSlot>> AvailableSlots(long salon, long[] versions, int days = 14, int limit = 30, long? excludedBooking = null)
    {
        if (versions.Length is < 1 or > 10) return [];
        await using var command = db.CreateCommand("""
            WITH selected_raw AS (
              SELECT input.ord,vv.version_variante_id,vv.variante_id,vv.duree_minutes
              FROM unnest($2::bigint[]) WITH ORDINALITY input(version_variante_id,ord)
              JOIN kb.version_variante vv USING(version_variante_id)
              JOIN kb.variante v USING(variante_id) JOIN kb.prestation p USING(prestation_id)
              WHERE p.etablissement_id=$1 AND p.etat='actif' AND v.actif
                AND vv.date_effet<=now() AND NOT EXISTS(SELECT 1 FROM kb.version_variante newer WHERE newer.variante_id=vv.variante_id AND newer.date_effet>vv.date_effet AND newer.date_effet<=now())
            ), selected AS (
              SELECT *,coalesce(sum(duree_minutes) OVER(ORDER BY ord ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),0)::int AS offset_minutes
              FROM selected_raw
            ), duration AS (
              SELECT sum(duree_minutes)::int AS minutes,count(*)::int AS selected_count FROM selected
            ), context AS (
              SELECT e.etablissement_id,e.fuseau,p.mode_capacite,d.minutes
              FROM kb.etablissement e CROSS JOIN duration d
              JOIN LATERAL(SELECT mode_capacite FROM kb.politique_rdv pr WHERE pr.etablissement_id=e.etablissement_id AND pr.date_effet<=now() ORDER BY pr.date_effet DESC LIMIT 1) p ON true
              WHERE e.etablissement_id=$1 AND d.selected_count=cardinality($2)
            ), candidates AS (
              SELECT c.*,g AS local_start,g+(c.minutes*interval '1 minute') AS local_end,
                     g AT TIME ZONE c.fuseau AS utc_start,(g+(c.minutes*interval '1 minute')) AT TIME ZONE c.fuseau AS utc_end
              FROM context c CROSS JOIN LATERAL generate_series(
                date_trunc('hour',now() AT TIME ZONE c.fuseau)+interval '1 hour',
                (now() AT TIME ZONE c.fuseau)+($3*interval '1 day'), interval '30 minutes') g
            ), service_windows AS (
              SELECT c.local_start,s.variante_id,c.mode_capacite,c.fuseau,
                (c.local_start+s.offset_minutes*interval '1 minute') AS service_local_start,
                (c.local_start+(s.offset_minutes+s.duree_minutes)*interval '1 minute') AS service_local_end,
                (c.utc_start+s.offset_minutes*interval '1 minute') AS service_utc_start,
                (c.utc_start+(s.offset_minutes+s.duree_minutes)*interval '1 minute') AS service_utc_end
              FROM candidates c CROSS JOIN selected s
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
            AND NOT EXISTS (
              SELECT 1 FROM service_windows sw JOIN kb.besoin_variante b USING(variante_id)
              WHERE sw.local_start=c.local_start AND NOT EXISTS (
                SELECT 1 FROM kb.ressource r JOIN kb.membre_groupe mg USING(ressource_id)
                WHERE mg.groupe_id=b.groupe_id AND r.etablissement_id=c.etablissement_id AND r.actif AND r.capacite>=b.quantite
                  AND (sw.mode_capacite='combinee' OR (sw.mode_capacite='globale' AND r.nature='globale') OR (sw.mode_capacite='employes' AND r.nature='employe') OR (sw.mode_capacite='ressources' AND r.nature='physique'))
                  AND EXISTS(SELECT 1 FROM kb.plage_ressource pr WHERE pr.ressource_id=r.ressource_id AND pr.jour_semaine=extract(isodow FROM sw.service_local_start)::int AND pr.debut<=sw.service_local_start::time AND pr.fin>=sw.service_local_end::time)
                  AND NOT EXISTS(SELECT 1 FROM kb.indisponibilite_ressource i WHERE i.ressource_id=r.ressource_id AND i.debut<sw.service_utc_end AND i.fin>sw.service_utc_start)
                  AND COALESCE((SELECT max(charge) FROM (
                    SELECT sum(a.quantite) AS charge FROM kb.allocation_rdv a JOIN kb.ligne_rdv l USING(rdv_id,numero)
                    JOIN kb.rendez_vous rd USING(rdv_id) JOIN kb.politique_rdv rp USING(politique_id)
                    WHERE a.ressource_id=r.ressource_id AND rd.rdv_id<>COALESCE($5,0) AND l.debut<sw.service_utc_end AND l.fin>sw.service_utc_start
                      AND (rd.etat='accepte' OR (rd.etat='en_attente_salon' AND rp.blocage_attente AND rd.expire_le>now()))
                    GROUP BY greatest(l.debut,sw.service_utc_start)
                  ) loads),0)+b.quantite<=r.capacite
              )
            )
            AND NOT EXISTS (SELECT 1 FROM service_windows sw JOIN kb.besoin_variante b USING(variante_id)
              JOIN kb.membre_groupe mg USING(groupe_id) WHERE sw.local_start=c.local_start GROUP BY sw.variante_id,mg.ressource_id HAVING count(*)>1)
            ORDER BY local_start LIMIT $4
            """);
        command.Parameters.AddWithValue(salon);
        command.Parameters.AddWithValue(versions);
        command.Parameters.AddWithValue(days);
        command.Parameters.AddWithValue(limit);
        command.Parameters.AddWithValue(NpgsqlTypes.NpgsqlDbType.Bigint,(object?)excludedBooking ?? DBNull.Value);
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
