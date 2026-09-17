using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
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
    public string InitiatePath { get; set; } = "/payments";
    public string ApiKeyHeader { get; set; } = "Authorization";
}

public sealed class KycStorageOptions
{
    public const string Section = "Integrations:KycStorage";
    public bool Enabled { get; set; }
    public string Provider { get; set; } = "";
    public string Bucket { get; set; } = "";
    public string Endpoint { get; set; } = "";
    public string ApiKey { get; set; } = "";
    public string ApiKeyHeader { get; set; } = "Authorization";
    public long MaxFileBytes { get; set; } = 8_388_608;
    public string[] AllowedContentTypes { get; set; } = ["image/jpeg", "image/png", "application/pdf"];
    public int RetentionDays { get; set; } = 365;
}

public sealed class BusinessRulesOptions
{
    public const string Section = "BusinessRules";
    public string LaunchCountryCode { get; set; } = "CI";
    public string Currency { get; set; } = "XOF";
    public int SubscriptionMinimumMonths { get; set; } = 12;
    public int BookingChangeDeadlineMinutes { get; set; } = 60;
    public int MaximumBookingChanges { get; set; } = 2;
    public int PaymentGraceDays { get; set; }
}

public sealed class OperationsOptions
{
    public const string Section = "Operations";
    public string PublicBaseUrl { get; set; } = "";
    public string DataProtectionKeysDirectory { get; set; } = "";
    public bool BackupsConfigured { get; set; }
    public bool MonitoringConfigured { get; set; }
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

public record PaymentRequest(string OperationKey, decimal Amount, string Currency, string Description);
public record PaymentSession(string ProviderReference, Uri PaymentUrl);

public interface IPaymentGateway
{
    bool IsConfigured { get; }
    Task<PaymentSession> Initiate(PaymentRequest payment, CancellationToken cancellationToken);
    bool VerifyWebhook(ReadOnlySpan<byte> body, string signature);
}

public sealed class ConfiguredPaymentGateway(HttpClient client, IOptions<PaymentOptions> options) : IPaymentGateway
{
    private readonly PaymentOptions settings = options.Value;
    public bool IsConfigured => settings.Enabled;

    public async Task<PaymentSession> Initiate(PaymentRequest payment, CancellationToken cancellationToken)
    {
        if (!IsConfigured) throw new InvalidOperationException("La passerelle de paiement n'est pas configurée.");
        var target = new Uri(new Uri(settings.ApiBaseUrl.TrimEnd('/') + "/"), settings.InitiatePath.TrimStart('/'));
        using var request = new HttpRequestMessage(HttpMethod.Post, target)
        {
            Content = JsonContent.Create(new
            {
                operationKey = payment.OperationKey,
                amount = payment.Amount,
                currency = payment.Currency,
                description = payment.Description,
                callbackUrl = settings.CallbackBaseUrl.TrimEnd('/') + "/paiements/retour"
            })
        };
        AddApiKey(request, settings.ApiKeyHeader, settings.SecretKey);
        using var response = await client.SendAsync(request, cancellationToken);
        response.EnsureSuccessStatusCode();
        using var json = JsonDocument.Parse(await response.Content.ReadAsStreamAsync(cancellationToken));
        var reference = json.RootElement.GetProperty("reference").GetString();
        var url = json.RootElement.GetProperty("paymentUrl").GetString();
        if (string.IsNullOrWhiteSpace(reference) || !Uri.TryCreate(url, UriKind.Absolute, out var paymentUrl) || paymentUrl.Scheme != Uri.UriSchemeHttps)
            throw new InvalidOperationException("Réponse de paiement fournisseur invalide.");
        return new(reference, paymentUrl);
    }

    public bool VerifyWebhook(ReadOnlySpan<byte> body, string signature)
    {
        if (!IsConfigured || string.IsNullOrWhiteSpace(signature)) return false;
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(settings.WebhookSecret));
        var expected = Convert.ToHexString(hmac.ComputeHash(body.ToArray()));
        return CryptographicOperations.FixedTimeEquals(Encoding.ASCII.GetBytes(expected), Encoding.ASCII.GetBytes(signature.ToUpperInvariant()));
    }

    internal static void AddApiKey(HttpRequestMessage request, string header, string key)
    {
        if (header.Equals("Authorization", StringComparison.OrdinalIgnoreCase)) request.Headers.Authorization = new("Bearer", key);
        else request.Headers.TryAddWithoutValidation(header, key);
    }
}

public interface IKycDocumentStorage
{
    bool IsConfigured { get; }
    Task<string> Store(Guid documentId, Stream content, long length, string contentType, CancellationToken cancellationToken);
}

public sealed class ConfiguredKycDocumentStorage(HttpClient client, IOptions<KycStorageOptions> options) : IKycDocumentStorage
{
    private readonly KycStorageOptions settings = options.Value;
    public bool IsConfigured => settings.Enabled;

    public async Task<string> Store(Guid documentId, Stream content, long length, string contentType, CancellationToken cancellationToken)
    {
        if (!IsConfigured) throw new InvalidOperationException("Le stockage KYC n'est pas configuré.");
        if (length is <= 0 || length > settings.MaxFileBytes) throw new ArgumentOutOfRangeException(nameof(length));
        if (!settings.AllowedContentTypes.Contains(contentType, StringComparer.OrdinalIgnoreCase)) throw new ArgumentException("Type de document refusé.", nameof(contentType));
        var extension = contentType switch { "image/jpeg" => ".jpg", "image/png" => ".png", "application/pdf" => ".pdf", _ => throw new ArgumentException("Type de document refusé.") };
        var privateReference = $"kyc/{DateTime.UtcNow:yyyy/MM}/{documentId:N}{extension}";
        var target = new Uri($"{settings.Endpoint.TrimEnd('/')}/{Uri.EscapeDataString(settings.Bucket)}/{privateReference}");
        using var request = new HttpRequestMessage(HttpMethod.Put, target) { Content = new StreamContent(content) };
        request.Content.Headers.ContentType = new(contentType);
        request.Content.Headers.ContentLength = length;
        ConfiguredPaymentGateway.AddApiKey(request, settings.ApiKeyHeader, settings.ApiKey);
        using var response = await client.SendAsync(request, cancellationToken);
        response.EnsureSuccessStatusCode();
        return privateReference;
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
            !x.Enabled || (!string.IsNullOrWhiteSpace(x.Provider) && Uri.TryCreate(x.ApiBaseUrl, UriKind.Absolute, out var api) && api.Scheme == Uri.UriSchemeHttps && Uri.TryCreate(x.CallbackBaseUrl, UriKind.Absolute, out var callback) && callback.Scheme == Uri.UriSchemeHttps && !string.IsNullOrWhiteSpace(x.SecretKey) && !string.IsNullOrWhiteSpace(x.WebhookSecret) && !string.IsNullOrWhiteSpace(x.InitiatePath)),
            "Paiement activé : Provider, ApiBaseUrl HTTPS, CallbackBaseUrl HTTPS, SecretKey et WebhookSecret sont obligatoires.").ValidateOnStart();
        services.AddOptions<KycStorageOptions>().Bind(configuration.GetSection(KycStorageOptions.Section)).Validate(x =>
            !x.Enabled || (!string.IsNullOrWhiteSpace(x.Provider) && !string.IsNullOrWhiteSpace(x.Bucket) && Uri.TryCreate(x.Endpoint, UriKind.Absolute, out var endpoint) && endpoint.Scheme == Uri.UriSchemeHttps && !string.IsNullOrWhiteSpace(x.ApiKey) && x.MaxFileBytes is >= 1024 and <= 20_971_520 && x.RetentionDays > 0 && x.AllowedContentTypes.Length > 0),
            "Stockage KYC activé : Provider, Bucket, Endpoint HTTPS, ApiKey, taille, types et conservation sont obligatoires.").ValidateOnStart();
        services.AddOptions<BusinessRulesOptions>().Bind(configuration.GetSection(BusinessRulesOptions.Section)).Validate(x =>
            x.LaunchCountryCode.Length == 2 && x.Currency.Length == 3 && x.SubscriptionMinimumMonths >= 12 && x.BookingChangeDeadlineMinutes >= 0 && x.MaximumBookingChanges >= 0 && x.PaymentGraceDays == 0,
            "Règles métier invalides : engagement >= 12 mois et aucune grâce de paiement.").ValidateOnStart();
        services.Configure<OperationsOptions>(configuration.GetSection(OperationsOptions.Section));
        services.AddHttpClient<ISmsSender, ConfiguredSmsSender>();
        services.AddHttpClient<IPaymentGateway, ConfiguredPaymentGateway>();
        services.AddHttpClient<IKycDocumentStorage, ConfiguredKycDocumentStorage>();
        services.AddSingleton<MapsLinkService>();
        return services;
    }
}
