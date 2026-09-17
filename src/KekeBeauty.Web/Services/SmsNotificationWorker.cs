using Microsoft.Extensions.Options;
using Npgsql;

namespace KekeBeauty.Web.Services;

public sealed class SmsNotificationOptions
{
    public const string Section = "Jobs:SmsNotifications";
    public bool Enabled { get; set; } = true;
    public int IntervalSeconds { get; set; } = 30;
    public int BatchSize { get; set; } = 50;
    public int MaximumAttempts { get; set; } = 5;
}

public sealed class SmsNotificationWorker(NpgsqlDataSource db, ISmsSender sender, IOptions<SmsNotificationOptions> options, ILogger<SmsNotificationWorker> logger) : BackgroundService
{
    private readonly SmsNotificationOptions settings = options.Value;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!settings.Enabled) return;
        while (!stoppingToken.IsCancellationRequested)
        {
            if (sender.IsConfigured) await Process(stoppingToken);
            await Task.Delay(TimeSpan.FromSeconds(settings.IntervalSeconds), stoppingToken);
        }
    }

    private async Task Process(CancellationToken token)
    {
        var items = new List<(long Id, string Phone, string Message)>();
        await using (var command = db.CreateCommand("""
            WITH claimed AS (
              SELECT n.notification_id FROM kb.notification n
              WHERE n.canal='sms' AND n.essais<$1 AND (
                (n.etat IN ('a_envoyer','echec') AND (n.prochain_essai IS NULL OR n.prochain_essai<=now()))
                OR (n.etat='en_cours' AND n.traite_le<now()-interval '10 minutes'))
              ORDER BY n.notification_id FOR UPDATE SKIP LOCKED LIMIT $2
            )
            UPDATE kb.notification n SET etat='en_cours',essais=essais+1,derniere_erreur=NULL,traite_le=now()
            FROM claimed c, kb.evenement_rdv ev, kb.rendez_vous r, kb.politique_rdv p, kb.etablissement e, kb.compte d
            WHERE n.notification_id=c.notification_id AND ev.evenement_id=n.evenement_id AND r.rdv_id=ev.rdv_id
              AND p.politique_id=r.politique_id AND e.etablissement_id=p.etablissement_id AND d.compte_id=n.destinataire_id
            RETURNING n.notification_id,d.telephone_normalise,
              'Keke Beauty - '||e.nom||' : '||ev.nature||' le '||to_char((SELECT min(l.debut) FROM kb.ligne_rdv l WHERE l.rdv_id=r.rdv_id) AT TIME ZONE e.fuseau,'DD/MM/YYYY HH24:MI')
            """))
        {
            command.Parameters.AddWithValue(settings.MaximumAttempts); command.Parameters.AddWithValue(settings.BatchSize);
            await using var reader = await command.ExecuteReaderAsync(token);
            while (await reader.ReadAsync(token)) items.Add((reader.GetInt64(0), reader.GetString(1), reader.GetString(2)));
        }
        foreach (var item in items)
        {
            try
            {
                await sender.SendMessage(item.Phone, item.Message, token);
                await Update(item.Id, true, null, token);
            }
            catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
            {
                logger.LogWarning("Échec SMS pour notification {NotificationId}", item.Id);
                await Update(item.Id, false, ex.GetType().Name, token);
            }
        }
    }

    private async Task Update(long id, bool success, string? error, CancellationToken token)
    {
        await using var command = db.CreateCommand("UPDATE kb.notification SET etat=$2,traite_le=now(),prochain_essai=CASE WHEN $2='echec' THEN now()+least(essais*essais,60)*interval '1 minute' ELSE NULL END,derniere_erreur=$3 WHERE notification_id=$1 AND etat='en_cours'");
        command.Parameters.AddWithValue(id); command.Parameters.AddWithValue(success ? "envoye" : "echec");
        command.Parameters.AddWithValue(NpgsqlTypes.NpgsqlDbType.Text, (object?)error ?? DBNull.Value);
        await command.ExecuteNonQueryAsync(token);
    }
}
