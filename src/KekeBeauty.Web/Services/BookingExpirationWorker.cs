using Microsoft.Extensions.Options;
using Npgsql;

namespace KekeBeauty.Web.Services;

public sealed class BookingExpirationOptions
{
    public const string Section = "Jobs:BookingExpiration";
    public bool Enabled { get; set; } = true;
    public int IntervalSeconds { get; set; } = 60;
    public int BatchSize { get; set; } = 100;
}

public sealed class BookingExpirationWorker(
    NpgsqlDataSource db,
    IOptions<BookingExpirationOptions> options,
    ILogger<BookingExpirationWorker> logger) : BackgroundService
{
    private readonly BookingExpirationOptions settings = options.Value;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!settings.Enabled) return;
        await Expire(stoppingToken);
        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(settings.IntervalSeconds));
        while (await timer.WaitForNextTickAsync(stoppingToken)) await Expire(stoppingToken);
    }

    private async Task Expire(CancellationToken cancellationToken)
    {
        try
        {
            await using var command = db.CreateCommand("SELECT kb.expirer_demandes_rdv($1)");
            command.Parameters.AddWithValue(settings.BatchSize);
            var count = (int)(await command.ExecuteScalarAsync(cancellationToken))!;
            if (count > 0) logger.LogInformation("{Count} demande(s) de rendez-vous expirée(s).", count);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested) { }
        catch (Exception exception)
        {
            logger.LogError(exception, "Échec du traitement d'expiration des rendez-vous.");
        }
    }
}
