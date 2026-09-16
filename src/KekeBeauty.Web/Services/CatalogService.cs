using Npgsql;
namespace KekeBeauty.Web.Services;
public record Salon(long Id, string Name, string Description, string Location, string Phone, string TimeZone);
public record ServiceOption(long Id, string Name, int Minutes, decimal Price, string Currency);
public sealed class CatalogService(NpgsqlDataSource db)
{
    public async Task<List<Salon>> Search(string query = "", long? id = null)
    {
        await using var command = db.CreateCommand("""
            SELECT e.etablissement_id,e.nom,coalesce(e.description,''),coalesce(co.nom,''),coalesce(e.telephone_service,''),e.fuseau
            FROM kb.annuaire e LEFT JOIN kb.commune co USING(commune_id)
            WHERE (e.nom ILIKE $1 OR co.nom ILIKE $1) AND ($2::bigint IS NULL OR e.etablissement_id=$2)
            ORDER BY e.nom,e.etablissement_id LIMIT 100
            """);
        command.Parameters.AddWithValue("%" + query.Trim().Replace("\\", "\\\\").Replace("%", "\\%").Replace("_", "\\_") + "%");
        command.Parameters.AddWithValue(NpgsqlTypes.NpgsqlDbType.Bigint,(object?)id ?? DBNull.Value);
        List<Salon> salons=[];
        await using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync()) salons.Add(new(reader.GetInt64(0),reader.GetString(1),reader.GetString(2),reader.GetString(3),reader.GetString(4),reader.GetString(5)));
        return salons;
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
    public async Task<long> Book(long client,long salon,long[] versions,DateTime utc,string key)
    {
        await using var command=db.CreateCommand("SELECT kb.creer_rdv($1,$2,$3,$4,$5)");
        command.Parameters.AddWithValue(client); command.Parameters.AddWithValue(salon); command.Parameters.AddWithValue(versions);
        command.Parameters.AddWithValue(utc); command.Parameters.AddWithValue(key);
        return (long)(await command.ExecuteScalarAsync())!;
    }
}
