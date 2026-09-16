using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;

namespace KekeBeauty.Web.Services;

public static class IdentityEndpoints
{
    public static void MapIdentity(this WebApplication app)
    {
        app.MapPost("/auth/request", async (HttpContext context, IAntiforgery antiforgery, PhoneIdentity identity) =>
        {
            await antiforgery.ValidateRequestAsync(context);
            // No simulated delivery in production. A real SMS adapter is required there.
            if (!app.Environment.IsDevelopment())
                return Results.Problem("Le service SMS n’est pas encore configuré.", statusCode: 503);
            var form = await context.Request.ReadFormAsync();
            try
            {
                var challenge = await identity.Issue(form["phone"].ToString());
                var tokens = antiforgery.GetAndStoreTokens(context);
                context.Response.Headers.CacheControl = "no-store";
                var html = $"""
                    <!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width">
                    <title>Vérifier mon téléphone — Keke Beauty</title><link rel="stylesheet" href="/app.css">
                    <main class="auth-card"><h1>Vérifier mon téléphone</h1>
                    <p>Environnement de développement : aucun SMS n’a été envoyé.</p>
                    <p>Code de test : <strong>{challenge.Code}</strong> — valable cinq minutes.</p>
                    <form method="post" action="/auth/verify">
                    <input type="hidden" name="{HtmlEncoder.Default.Encode(tokens.FormFieldName)}" value="{HtmlEncoder.Default.Encode(tokens.RequestToken!)}">
                    <input type="hidden" name="challenge" value="{challenge.Challenge}">
                    <label for="code">Code à six chiffres</label><input id="code" name="code" inputmode="numeric" autocomplete="one-time-code" minlength="6" maxlength="6" required>
                    <button type="submit">Me connecter</button></form><a href="/connexion">Recommencer</a></main></html>
                    """;
                return Results.Content(html, "text/html; charset=utf-8");
            }
            catch (ArgumentException) { return Results.Redirect("/connexion?erreur=format"); }
            catch (InvalidOperationException) { return Results.Redirect("/connexion?erreur=limite"); }
        }).RequireRateLimiting("login");

        app.MapPost("/auth/verify", async (HttpContext context, IAntiforgery antiforgery, PhoneIdentity identity) =>
        {
            await antiforgery.ValidateRequestAsync(context);
            var form = await context.Request.ReadFormAsync();
            if (!Guid.TryParse(form["challenge"], out var challenge)) return Results.Redirect("/connexion?erreur=code");
            var account = await identity.Verify(challenge, form["code"].ToString());
            if (account is null) return Results.Redirect("/connexion?erreur=code");
            var principal = new ClaimsPrincipal(new ClaimsIdentity([new Claim(ClaimTypes.NameIdentifier, account.Value.ToString())], CookieAuthenticationDefaults.AuthenticationScheme));
            await context.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal);
            return Results.Redirect("/mes-rendez-vous");
        }).RequireRateLimiting("login");

        app.MapPost("/auth/logout", async (HttpContext context, IAntiforgery antiforgery) =>
        {
            await antiforgery.ValidateRequestAsync(context);
            await context.SignOutAsync();
            return Results.Redirect("/");
        });
    }
}
