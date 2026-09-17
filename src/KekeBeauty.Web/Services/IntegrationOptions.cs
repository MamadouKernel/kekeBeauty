using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.Extensions.Options;

namespace KekeBeauty.Web.Services;

public sealed class SmsOptions
{
    public const string Section = "Integrations:Sms";
    public bool Enabled { get; set; }
    public string Provider { get; set; } = "";
    public string Endpoint { get; set; } = "";
    public string ApiKey { get; set; } = "";
    public string ApiKeyHeader { get; set; } = "Authorization";
    public string SenderId { get; set; } = "KekeBeauty";
}

public sealed class MapsOptions
{
    public const string Section = "Integrations:Maps";
    public bool Enabled { get; set; }
    public string DirectionsUrlTemplate { get; set; } = "https://www.google.com/maps/dir/?api=1&destination={latitude},{longitude}";
}

public sealed class PaymentOptions
{
    public const string Section = "Integrations:Payments";
    public bool Enabled { get; set; }
    public string Provider { get; set; } = "";
    public string ApiBaseUrl { get; set; } = "";
    public string PublicKey { get; set; } = "";
    public string SecretKey { get; set; } = "";
    public string WebhookSecret { get; set; } = "";
    public string CallbackBaseUrl { get; set; } = "";
}

public sealed class KycStorageOptions
{
    public const string Section = "Integrations:KycStorage";
    public bool Enabled { get; set; }
    public string Provider { get; set; } = "";
    public string Bucket { get; set; } = "";
    public string Endpoint { get; set; } = "";
}

public interface ISmsSender
{
    bool IsConfigured { get; }
    Task SendOtp(string phone, string code, CancellationToken cancellationToken);
}

public sealed class ConfiguredSmsSender(HttpClient client, IOptions<SmsOptions> options) : ISmsSender
{
    private readonly SmsOptions settings = options.Value;
    public bool IsConfigured => settings.Enabled;

    public async Task SendOtp(string phone, string code, CancellationToken cancellationToken)
    {
        if (!IsConfigured) throw new InvalidOperationException("Le fournisseur SMS n'est pas configuré.");
        using var request = new HttpRequestMessage(HttpMethod.Post, settings.Endpoint)
        {
            Content = JsonContent.Create(new
            {
                to = phone,
                sender = settings.SenderId,
                message = $"Votre code Keke Beauty est {code}. Il expire dans 5 minutes."
            })
        };
        if (settings.ApiKeyHeader.Equals("Authorization", StringComparison.OrdinalIgnoreCase))
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", settings.ApiKey);
        else
            request.Headers.TryAddWithoutValidation(settings.ApiKeyHeader, settings.ApiKey);
        using var response = await client.SendAsync(request, cancellationToken);
        response.EnsureSuccessStatusCode();
    }
}

public sealed class MapsLinkService(IOptions<MapsOptions> options)
{
    private readonly MapsOptions settings = options.Value;
    public string? Directions(decimal? latitude, decimal? longitude)
    {
        if (!settings.Enabled || latitude is null || longitude is null) return null;
        return settings.DirectionsUrlTemplate
            .Replace("{latitude}", latitude.Value.ToString(System.Globalization.CultureInfo.InvariantCulture), StringComparison.Ordinal)
            .Replace("{longitude}", longitude.Value.ToString(System.Globalization.CultureInfo.InvariantCulture), StringComparison.Ordinal);
    }
}

public static class IntegrationRegistration
{
    public static IServiceCollection AddKekeIntegrations(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<SmsOptions>().Bind(configuration.GetSection(SmsOptions.Section)).Validate(x =>
            !x.Enabled || (!string.IsNullOrWhiteSpace(x.Provider) && Uri.TryCreate(x.Endpoint, UriKind.Absolute, out var uri) && uri.Scheme == Uri.UriSchemeHttps && !string.IsNullOrWhiteSpace(x.ApiKey)),
            "SMS activé : Provider, Endpoint HTTPS et ApiKey sont obligatoires.").ValidateOnStart();
        services.AddOptions<MapsOptions>().Bind(configuration.GetSection(MapsOptions.Section)).Validate(x =>
            !x.Enabled || (Uri.TryCreate(x.DirectionsUrlTemplate.Replace("{latitude}", "0").Replace("{longitude}", "0"), UriKind.Absolute, out var uri) && uri.Scheme == Uri.UriSchemeHttps),
            "Cartographie activée : DirectionsUrlTemplate doit être une URL HTTPS valide.").ValidateOnStart();
        services.AddOptions<PaymentOptions>().Bind(configuration.GetSection(PaymentOptions.Section)).Validate(x =>
            !x.Enabled || (!string.IsNullOrWhiteSpace(x.Provider) && Uri.TryCreate(x.ApiBaseUrl, UriKind.Absolute, out var api) && api.Scheme == Uri.UriSchemeHttps && Uri.TryCreate(x.CallbackBaseUrl, UriKind.Absolute, out var callback) && callback.Scheme == Uri.UriSchemeHttps && !string.IsNullOrWhiteSpace(x.SecretKey) && !string.IsNullOrWhiteSpace(x.WebhookSecret)),
            "Paiement activé : Provider, ApiBaseUrl HTTPS, CallbackBaseUrl HTTPS, SecretKey et WebhookSecret sont obligatoires.").ValidateOnStart();
        services.AddOptions<KycStorageOptions>().Bind(configuration.GetSection(KycStorageOptions.Section)).Validate(x =>
            !x.Enabled || (!string.IsNullOrWhiteSpace(x.Provider) && !string.IsNullOrWhiteSpace(x.Bucket) && Uri.TryCreate(x.Endpoint, UriKind.Absolute, out var endpoint) && endpoint.Scheme == Uri.UriSchemeHttps),
            "Stockage KYC activé : Provider, Bucket et Endpoint HTTPS sont obligatoires.").ValidateOnStart();
        services.AddHttpClient<ISmsSender, ConfiguredSmsSender>();
        services.AddSingleton<MapsLinkService>();
        return services;
    }
}
