using Npgsql;

namespace KekeBeauty.Web.Services;

public sealed record PartnerProfile(long Id, string Name, string Phone, string KycState);
public sealed record PartnerSalon(long Id, string Name, string State);

public sealed class PartnerService(NpgsqlDataSource source)
{
    public async Task<PartnerProfile?> Get(long account)
    {
        await using var command = source.CreateCommand("""
            SELECT g.gerant_id,g.nom_declare,c.telephone_normalise,
                coalesce((SELECT d.etat FROM kb.dossier_kyc d WHERE d.gerant_id=g.gerant_id
                    ORDER BY d.dossier_id DESC LIMIT 1),'non_demarre')
            FROM kb.gerant g JOIN kb.compte c USING(compte_id)
            WHERE g.compte_id=$1 AND c.etat='actif' ORDER BY g.gerant_id LIMIT 1
            """);
        command.Parameters.AddWithValue(account);
        await using var reader = await command.ExecuteReaderAsync();
        return await reader.ReadAsync() ? new(reader.GetInt64(0), reader.GetString(1), reader.GetString(2), reader.GetString(3)) : null;
    }

    public async Task<List<PartnerSalon>> Salons(long account)
    {
        await using var command = source.CreateCommand("""
            SELECT DISTINCT e.etablissement_id,e.nom,e.etat_publication
            FROM kb.etablissement e JOIN kb.gerant_etablissement ge USING(etablissement_id)
            JOIN kb.gerant g USING(gerant_id) JOIN kb.compte c USING(compte_id)
            WHERE g.compte_id=$1 AND c.etat='actif' ORDER BY e.nom,e.etablissement_id
            """);
        command.Parameters.AddWithValue(account);
        var rows = new List<PartnerSalon>();
        await using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync()) rows.Add(new(reader.GetInt64(0), reader.GetString(1), reader.GetString(2)));
        return rows;
    }

    public async Task Save(long account, string name)
    {
        name = name.Trim();
        if (name.Length is < 2 or > 160 || name.Any(char.IsControl)) throw new ArgumentException("Nom invalide.");
        await using var connection = await source.OpenConnectionAsync();
        await using var transaction = await connection.BeginTransactionAsync();
        // Serialize registration for this account so concurrent submissions share one draft.
        await using var command = new NpgsqlCommand("SELECT compte_id FROM kb.compte WHERE compte_id=$1 AND etat='actif' AND telephone_verifie_le IS NOT NULL FOR UPDATE", connection, transaction);
        command.Parameters.AddWithValue(account);
        if (await command.ExecuteScalarAsync() is null) throw new UnauthorizedAccessException();
        command.CommandText = "SELECT gerant_id FROM kb.gerant WHERE compte_id=$1 ORDER BY gerant_id LIMIT 1 FOR UPDATE";
        var existing = await command.ExecuteScalarAsync();
        long manager;
        if (existing is null)
        {
            command.CommandText = "INSERT INTO kb.gerant(compte_id,nom_declare) VALUES($1,$2) RETURNING gerant_id";
            command.Parameters.AddWithValue(name);
            manager = (long)(await command.ExecuteScalarAsync())!;
        }
        else
        {
            manager = (long)existing;
            command.Parameters.Clear();
            command.Parameters.AddWithValue(manager);
            command.CommandText = "SELECT etat FROM kb.dossier_kyc WHERE gerant_id=$1 ORDER BY dossier_id DESC LIMIT 1 FOR UPDATE";
            var state = await command.ExecuteScalarAsync() as string;
            if (state is not null && state is not "brouillon" and not "refuse" and not "rejete")
                throw new InvalidOperationException("Le dossier ne peut plus être modifié.");
            command.CommandText = "UPDATE kb.gerant SET nom_declare=$2 WHERE gerant_id=$1";
            command.Parameters.AddWithValue(name);
            await command.ExecuteNonQueryAsync();
        }
        command.Parameters.Clear();
        command.Parameters.AddWithValue(manager);
        command.CommandText = """
            INSERT INTO kb.dossier_kyc(gerant_id,etat)
            SELECT $1,'brouillon' WHERE NOT EXISTS(SELECT 1 FROM kb.dossier_kyc WHERE gerant_id=$1)
            """;
        await command.ExecuteNonQueryAsync();
        await transaction.CommitAsync();
    }
}
