using System.Security.Cryptography;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.DataProtection;
using Npgsql;

namespace KekeBeauty.Web.Services;

public sealed partial class PhoneIdentity(NpgsqlDataSource db, IDataProtectionProvider protection)
{
    private readonly IDataProtector protector = protection.CreateProtector("KekeBeauty.OTP.v1");

    // International format keeps country configuration separate from identity.
    public static string Normalize(string phone)
    {
        var normalized = phone.Replace(" ", "").Replace("-", "").Replace("(", "").Replace(")", "");
        if (!InternationalPhone().IsMatch(normalized))
            throw new ArgumentException("Utilisez le format international, par exemple +225 suivi de votre numéro.");
        return normalized;
    }

    [GeneratedRegex(@"^\+[1-9][0-9]{7,14}$")]
    private static partial Regex InternationalPhone();

    public async Task<(Guid Challenge, string Code, string Phone)> Issue(string phone)
    {
        phone = Normalize(phone);
        await using var connection = await db.OpenConnectionAsync();
        await using var transaction = await connection.BeginTransactionAsync();
        // Serialize challenges for this phone, including first registration.
        await using (var gate = new NpgsqlCommand("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", connection, transaction))
        {
            gate.Parameters.AddWithValue(phone);
            await gate.ExecuteNonQueryAsync();
        }
        await using (var rate = new NpgsqlCommand("SELECT count(*) FROM kb.defi_connexion WHERE telephone=$1 AND cree_le>clock_timestamp()-interval '15 minutes'", connection, transaction))
        {
            rate.Parameters.AddWithValue(phone);
            if ((long)(await rate.ExecuteScalarAsync())! >= 3)
                throw new InvalidOperationException("Trop de demandes. Réessayez dans quinze minutes.");
        }
        var id = Guid.NewGuid();
        var code = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
        await using (var invalidate = new NpgsqlCommand("UPDATE kb.defi_connexion SET consomme=true WHERE telephone=$1 AND NOT consomme", connection, transaction))
        {
            invalidate.Parameters.AddWithValue(phone);
            await invalidate.ExecuteNonQueryAsync();
        }
        await using var command = new NpgsqlCommand("""
            INSERT INTO kb.defi_connexion(defi_id,telephone,preuve,expire_le)
            VALUES($2,$1,$3,clock_timestamp()+interval '5 minutes');
            """, connection, transaction);
        command.Parameters.AddWithValue(phone);
        command.Parameters.AddWithValue(id);
        command.Parameters.AddWithValue(protector.Protect(id + ":" + code));
        await command.ExecuteNonQueryAsync();
        await transaction.CommitAsync();
        return (id, code, phone);
    }

    public async Task<long?> Verify(Guid id, string code)
    {
        if (code.Length != 6 || code.Any(c => c < '0' || c > '9')) return null;
        await using var connection = await db.OpenConnectionAsync();
        await using var transaction = await connection.BeginTransactionAsync();
        string phone, encrypted;
        await using (var command = new NpgsqlCommand("SELECT telephone,preuve FROM kb.defi_connexion WHERE defi_id=$1 AND NOT consomme AND essais<5 AND expire_le>clock_timestamp() FOR UPDATE", connection, transaction))
        {
            command.Parameters.AddWithValue(id);
            await using var reader = await command.ExecuteReaderAsync();
            if (!await reader.ReadAsync()) return null;
            phone = reader.GetString(0); encrypted = reader.GetString(1);
        }
        bool valid;
        try { valid = CryptographicOperations.FixedTimeEquals(System.Text.Encoding.UTF8.GetBytes(protector.Unprotect(encrypted)), System.Text.Encoding.UTF8.GetBytes(id + ":" + code)); }
        catch (CryptographicException) { valid = false; }
        await using (var attempt = new NpgsqlCommand("UPDATE kb.defi_connexion SET essais=essais+1,consomme=$2 WHERE defi_id=$1", connection, transaction))
        {
            attempt.Parameters.AddWithValue(id); attempt.Parameters.AddWithValue(valid);
            await attempt.ExecuteNonQueryAsync();
        }
        long? account = null;
        if (valid)
        {
            await using var command = new NpgsqlCommand("""
                INSERT INTO kb.compte(telephone_normalise,telephone_verifie_le,etat) VALUES($1,clock_timestamp(),'actif')
                ON CONFLICT(telephone_normalise) DO UPDATE SET telephone_verifie_le=excluded.telephone_verifie_le
                WHERE compte.etat='actif' RETURNING compte_id
                """, connection, transaction);
            command.Parameters.AddWithValue(phone);
            account = await command.ExecuteScalarAsync() as long?;
        }
        await transaction.CommitAsync();
        return account;
    }
}
