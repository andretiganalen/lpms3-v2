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
app.MapGet("/ids/login", (string? @as) =>
    Results.Challenge(new AuthenticationProperties { RedirectUri = @as == "admin" ? "/ids/admin" : "/" }));
app.MapGet("/ids/logout", () => Results.SignOut(new AuthenticationProperties { RedirectUri = "/" },
    new[] { CookieAuthenticationDefaults.AuthenticationScheme, OpenIdConnectDefaults.AuthenticationScheme }));
var adminRoles = (builder.Configuration["AdminRoles"] ?? "admin,administrator").Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
app.MapGet("/ids/admin", (HttpContext c) =>
{
    if (c.User.Identity?.IsAuthenticated != true) return Results.Redirect("/ids/login?as=admin");
    var ok = c.User.FindAll("role").Any(r => adminRoles.Contains(r.Value, StringComparer.OrdinalIgnoreCase));
    return ok ? Results.Redirect("/?admin=1")
              : Results.Content("<!doctype html><meta charset=utf-8><body style=\"font-family:system-ui;padding:2rem\"><h1>Akses ditolak</h1><p>Akun ini bukan Admin.</p><a href=\"/\">Kembali</a><br><a href=\"/ids/logout\">Keluar</a>", "text/html; charset=utf-8", statusCode: 403);
});
app.MapGet("/", (HttpContext c) =>
{
    static string E(string? v) => System.Net.WebUtility.HtmlEncode(v ?? "");
    const string css = ":root{--bg:#f5f6f8;--fg:#1c1f26;--card:#fff;--mut:#667085;--pri:#ae2524;--bd:#e4e7ec}@media(prefers-color-scheme:dark){:root{--bg:#14161a;--fg:#eceef2;--card:#1e2127;--mut:#98a2b3;--bd:#2f343c}}body{margin:0;min-height:100vh;display:grid;place-items:center;background:var(--bg);color:var(--fg);font:16px/1.5 system-ui,sans-serif}main{width:min(440px,calc(100% - 32px));background:var(--card);border:1px solid var(--bd);border-radius:12px;padding:32px}h1{font-size:1.4rem;margin:0 0 4px}p{color:var(--mut);margin:0 0 24px}a.btn{display:block;text-align:center;background:var(--pri);color:#fff;text-decoration:none;padding:12px;border-radius:8px;font-weight:600}a.btn.o{background:none;color:var(--pri);border:1px solid var(--pri)}.sp{height:12px}small{display:block;margin-top:20px;color:var(--mut);text-align:center}dl{margin:0 0 24px;display:grid;grid-template-columns:auto 1fr;gap:8px 16px}dt{color:var(--mut)}dd{margin:0;word-break:break-all}";
    string page(string body) => "<!doctype html><html lang=\"id\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>LPMS3 Login IDS</title><style>" + css + "</style></head><body><main>" + body + "</main></body></html>";
    if (c.User.Identity?.IsAuthenticated != true)
        return Results.Content(page("<h1>LPMS3</h1><p>Masuk menggunakan akun IDS Len.</p>"
            + "<a class=\"btn\" href=\"/ids/login?as=user\">Login User</a>"
            + "<div class=\"sp\"></div>"
            + "<a class=\"btn o\" href=\"/ids/login?as=admin\">Login Admin</a>"
            + "<small>Keduanya memakai IDS; hak akses ditentukan oleh peran akun.</small>"), "text/html; charset=utf-8");
    string Claim(params string[] t) => t.Select(x => c.User.FindFirst(x)?.Value).FirstOrDefault(v => v != null) ?? "-";
    var roles = string.Join(", ", c.User.FindAll("role").Select(x => x.Value).DefaultIfEmpty("-"));
    var body = "<h1>Berhasil masuk</h1><p>Login IDS berhasil" + (c.Request.Query.ContainsKey("admin") ? " (Admin)." : ".") + "</p><dl><dt>Nama</dt><dd>" + E(c.User.Identity.Name) + "</dd><dt>Username</dt><dd>" + E(Claim("preferred_username", "username")) + "</dd><dt>Email</dt><dd>" + E(Claim("email")) + "</dd><dt>Peran</dt><dd>" + E(roles) + "</dd></dl><a class=\"btn o\" href=\"/ids/logout\">Keluar</a>";
    return Results.Content(page(body), "text/html; charset=utf-8");
});
app.Run();
