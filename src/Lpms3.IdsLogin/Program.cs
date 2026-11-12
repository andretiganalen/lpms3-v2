// Lpms3.IdsLogin — hanya Login IDS (OIDC code + PKCE), tidak ada fitur lain.
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;

var builder = WebApplication.CreateBuilder(args);
var oidc = builder.Configuration.GetSection("Oidc");

builder.Services.AddAuthentication(o =>
    {
        o.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
        o.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;
    })
    .AddCookie(o =>
    {
        o.Cookie.Name = "lpms3.auth";
        o.Cookie.HttpOnly = true;
        o.Cookie.SameSite = SameSiteMode.Lax;
        o.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
        o.ExpireTimeSpan = TimeSpan.FromHours(8);
        o.SlidingExpiration = true;
    })
    .AddOpenIdConnect(OpenIdConnectDefaults.AuthenticationScheme, o =>
    {
        o.Authority = oidc["Authority"] ?? throw new InvalidOperationException("Oidc:Authority wajib diisi.");
        o.ClientId = oidc["ClientId"] ?? throw new InvalidOperationException("Oidc:ClientId wajib diisi.");
        o.ClientSecret = oidc["ClientSecret"] ?? throw new InvalidOperationException("Oidc:ClientSecret wajib diisi.");
        o.ResponseType = "code";
        o.ResponseMode = "query"; // HTTP (LAN) + cookie SameSite=Lax
        o.UsePkce = oidc.GetValue("UsePkce", true);
        o.SaveTokens = true;
        o.RequireHttpsMetadata = oidc.GetValue("RequireHttpsMetadata", true);
        o.GetClaimsFromUserInfoEndpoint = true;
        o.CallbackPath = oidc["CallbackPath"] ?? "/signin-oidc";
        o.SignedOutCallbackPath = oidc["SignedOutCallbackPath"] ?? "/signout-callback-oidc";
        o.CorrelationCookie.SameSite = SameSiteMode.Lax;
        o.CorrelationCookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
        o.NonceCookie.SameSite = SameSiteMode.Lax;
        o.NonceCookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
        o.Scope.Clear();
        foreach (var s in oidc.GetSection("Scopes").Get<string[]>() ?? new[] { "openid", "profile", "email" })
            o.Scope.Add(s);
        o.TokenValidationParameters.NameClaimType = "name";
        o.TokenValidationParameters.RoleClaimType = "role";
    });
builder.Services.AddAuthorization();

var app = builder.Build();
app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/health", () => Results.Ok("OK"));
app.MapGet("/login", (string? returnUrl) =>
    Results.Challenge(new AuthenticationProperties { RedirectUri = returnUrl is { Length: > 0 } && returnUrl.StartsWith('/') && !returnUrl.StartsWith("//") ? returnUrl : "/" }));
app.MapGet("/logout", () => Results.SignOut(new AuthenticationProperties { RedirectUri = "/" },
    new[] { CookieAuthenticationDefaults.AuthenticationScheme, OpenIdConnectDefaults.AuthenticationScheme }));
app.MapGet("/", (HttpContext c) => c.User.Identity?.IsAuthenticated == true
    ? Results.Json(new { login = true, name = c.User.Identity.Name, claims = c.User.Claims.Select(x => x.Type).Distinct() })
    : Results.Redirect("/login"));
app.Run();
