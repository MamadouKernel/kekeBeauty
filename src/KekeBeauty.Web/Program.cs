using KekeBeauty.Web.Components;
using Microsoft.AspNetCore.DataProtection;
using KekeBeauty.Web.Services;
using Microsoft.AspNetCore.Authentication.Cookies;
using System.Security.Claims;
using System.Threading.RateLimiting;
using Npgsql;

var builder = WebApplication.CreateBuilder(args);

var operations = builder.Configuration.GetSection(OperationsOptions.Section).Get<OperationsOptions>() ?? new();
if (builder.Environment.IsDevelopment())
{
    // Keep local development keys inside the workspace. Production key storage
    // will be configured with the hosting environment before deployment.
    var keyDirectory = new DirectoryInfo(Path.Combine(builder.Environment.ContentRootPath, "App_Data", "keys"));
    builder.Services.AddDataProtection().PersistKeysToFileSystem(keyDirectory);
}
else if (!string.IsNullOrWhiteSpace(operations.DataProtectionKeysDirectory))
{
    builder.Services.AddDataProtection().PersistKeysToFileSystem(new DirectoryInfo(operations.DataProtectionKeysDirectory));
}

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();
builder.Services.AddSingleton(sp => Database.Create(builder.Configuration, builder.Environment));
builder.Services.AddScoped<PhoneIdentity>();
builder.Services.AddScoped<BookingService>();
builder.Services.AddScoped<CatalogService>();
builder.Services.AddKekeIntegrations(builder.Configuration);
builder.Services.AddOptions<BookingExpirationOptions>().Bind(builder.Configuration.GetSection(BookingExpirationOptions.Section)).Validate(x =>
    !x.Enabled || (x.IntervalSeconds is >= 10 and <= 3600 && x.BatchSize is >= 1 and <= 1000),
    "Expiration RDV : intervalle de 10 à 3600 secondes et lot de 1 à 1000.").ValidateOnStart();
builder.Services.AddHostedService<BookingExpirationWorker>();
if (!builder.Environment.IsDevelopment())
{
    builder.Services.AddOptions<OperationsOptions>().Bind(builder.Configuration.GetSection(OperationsOptions.Section)).Validate(x =>
        Uri.TryCreate(x.PublicBaseUrl, UriKind.Absolute, out var publicUrl) && publicUrl.Scheme == Uri.UriSchemeHttps &&
        !string.IsNullOrWhiteSpace(x.DataProtectionKeysDirectory) && x.BackupsConfigured && x.MonitoringConfigured,
        "Production : URL publique HTTPS, stockage persistant des clés, sauvegardes et supervision sont obligatoires.").ValidateOnStart();
}
builder.Services.AddCascadingAuthenticationState();
builder.Services.AddAuthorization();
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme).AddCookie(options =>
{
    options.LoginPath = "/connexion";
    options.Cookie.HttpOnly = true;
    options.Cookie.SameSite = SameSiteMode.Lax;
    options.Cookie.SecurePolicy = builder.Environment.IsDevelopment() ? CookieSecurePolicy.SameAsRequest : CookieSecurePolicy.Always;
    options.ExpireTimeSpan = TimeSpan.FromHours(8);
    options.SlidingExpiration = false;
    options.Events.OnValidatePrincipal = async context =>
    {
        if (!long.TryParse(context.Principal?.FindFirstValue(ClaimTypes.NameIdentifier), out var id)) { context.RejectPrincipal(); return; }
        var source = context.HttpContext.RequestServices.GetRequiredService<NpgsqlDataSource>();
        await using var command = source.CreateCommand("SELECT EXISTS(SELECT 1 FROM kb.compte WHERE compte_id=$1 AND etat='actif')");
        command.Parameters.AddWithValue(id);
        if (!(bool)(await command.ExecuteScalarAsync())!) context.RejectPrincipal();
    };
});
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = 429;
    options.AddPolicy("login", context => RateLimitPartition.GetFixedWindowLimiter(
        context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        _ => new FixedWindowRateLimiterOptions { PermitLimit = 15, Window = TimeSpan.FromMinutes(15), QueueLimit = 0 }));
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}
app.UseStatusCodePagesWithReExecute("/not-found", createScopeForStatusCodePages: true);
app.UseHttpsRedirection();

app.UseAuthentication();
app.Use(async (context, next) =>
{
    if (context.Request.Path.StartsWithSegments("/auth") ||
        context.Request.Path.StartsWithSegments("/connexion") ||
        context.Request.Path.StartsWithSegments("/mes-rendez-vous") ||
        context.Request.Path.StartsWithSegments("/rendez-vous") ||
        context.User.Identity?.IsAuthenticated == true)
        context.Response.Headers.CacheControl = "no-store";
    if (context.Request.Path == "/service-worker.js")
        context.Response.Headers.CacheControl = "no-cache";
    await next();
});
app.UseAuthorization();
app.UseRateLimiter();
app.Use(async (context, next) =>
{
    try { await next(context); }
    catch (Microsoft.AspNetCore.Antiforgery.AntiforgeryValidationException)
    { context.Response.StatusCode = 400; await context.Response.WriteAsync("Formulaire expiré ou invalide. Rechargez la page."); }
});
app.UseAntiforgery();
app.MapIdentity();
app.MapPost("/rendez-vous/creer", async (HttpContext context, Microsoft.AspNetCore.Antiforgery.IAntiforgery antiforgery, CatalogService catalog) =>
{
    await antiforgery.ValidateRequestAsync(context);
    var form=await context.Request.ReadFormAsync();
    if (!long.TryParse(context.User.FindFirstValue(ClaimTypes.NameIdentifier),out var account)) return Results.Unauthorized();
    if (!long.TryParse(form["salon"],out var salonId)) return Results.BadRequest();
    var salon=(await catalog.Search(id:salonId)).FirstOrDefault();
    if(salon is null) return Results.NotFound();
    if(!DateTime.TryParseExact(form["start"],"yyyy-MM-ddTHH:mm",System.Globalization.CultureInfo.InvariantCulture,System.Globalization.DateTimeStyles.None,out var local)) return Results.BadRequest();
    var zone=TimeZoneInfo.FindSystemTimeZoneById(salon.TimeZone);
    if(zone.IsInvalidTime(local)||zone.IsAmbiguousTime(local)) return Results.BadRequest("Choisissez un horaire sans changement d’heure.");
    var versions=new List<long>();
    foreach(var raw in form["versions"]) { if(!long.TryParse(raw,out var version)) return Results.BadRequest(); versions.Add(version); }
    if(versions.Count is <1 or >10) return Results.BadRequest("Choisissez de une à dix prestations.");
    try { await catalog.Book(account,salonId,versions.ToArray(),TimeZoneInfo.ConvertTimeToUtc(local,zone),form["key"].ToString()); }
    catch(PostgresException ex) when(ex.SqlState is "42501" or "23514" or "23P01" or "23505" or "P0002") { return Results.Redirect($"/salons/{salonId}?erreur=creneau"); }
    return Results.Redirect("/mes-rendez-vous?resultat=ok");
}).RequireAuthorization();
app.MapPost("/rendez-vous/action", async (HttpContext context, Microsoft.AspNetCore.Antiforgery.IAntiforgery antiforgery, BookingService bookings) =>
{
    await antiforgery.ValidateRequestAsync(context);
    var form = await context.Request.ReadFormAsync();
    if (!long.TryParse(context.User.FindFirstValue(ClaimTypes.NameIdentifier), out var account)) return Results.Unauthorized();
    if (!long.TryParse(form["id"], out var id)) return Results.BadRequest();
    try
    {
        if (form["action"] == "reporter")
        {
            if (!DateTime.TryParseExact(form["start"], "yyyy-MM-ddTHH:mm", System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, out var local)) return Results.BadRequest();
            await bookings.Reschedule(id, account, local, form["key"].ToString());
        }
        else await bookings.Act(id, account, form["action"].ToString(), form["key"].ToString(), form["motif"].ToString());
    }
    catch (PostgresException ex) when (ex.SqlState is "42501" or "23514" or "23P01" or "23505" or "P0002") { return Results.Redirect("/mes-rendez-vous?resultat=erreur"); }
    catch (ArgumentException) { return Results.BadRequest(); }
    return Results.Redirect("/mes-rendez-vous?resultat=ok");
}).RequireAuthorization();

app.MapStaticAssets();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
