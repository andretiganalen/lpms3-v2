// Lpms3.IdsLogin — hanya Login IDS (OIDC code + PKCE), tidak ada fitur lain.
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.AspNetCore.DataProtection;

var builder = WebApplication.CreateBuilder(args);
var oidc = builder.Configuration.GetSection("Oidc");

// Kunci data-protection dipersist agar cookie/sesi tetap valid setelah restart container.
builder.Services.AddDataProtection()
    .SetApplicationName("lpms3-idslogin")
    .PersistKeysToFileSystem(new DirectoryInfo(builder.Configuration["DataProtection:KeysPath"] ?? "/keys"));

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

builder.Services.AddHttpClient("op", c => c.Timeout = TimeSpan.FromSeconds(20))
    .ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler { UseCookies = false, AllowAutoRedirect = false });
var app = builder.Build();
app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/health", () => Results.Ok("OK"));
app.MapGet("/ids/login", (string? @as) =>
    Results.Challenge(new AuthenticationProperties { RedirectUri = @as == "admin" ? "/ids/admin" : "/ids/enter" }));
app.MapGet("/ids/logout", () => Results.SignOut(new AuthenticationProperties { RedirectUri = "/" },
    new[] { CookieAuthenticationDefaults.AuthenticationScheme, OpenIdConnectDefaults.AuthenticationScheme }));
var adminRoles = (builder.Configuration["AdminRoles"] ?? "administrator").Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

var adminEmails = (builder.Configuration["AdminEmails"] ?? "").Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
bool IsAdmin(System.Security.Claims.ClaimsPrincipal u) =>
    u.FindAll("role").Any(r => adminRoles.Contains(r.Value, StringComparer.OrdinalIgnoreCase))
    || (u.FindFirst("email")?.Value is { } m && adminEmails.Contains(m, StringComparer.OrdinalIgnoreCase));

// Jembatan: setelah login IDS, buat/sinkronkan akun OpenProject lalu masuk atas nama pengguna.
app.MapGet("/ids/enter", async (HttpContext c, IHttpClientFactory f, IConfiguration cfg) =>
{
    if (c.User.Identity?.IsAuthenticated != true) return Results.Redirect("/ids/login");
    var baseUrl = cfg["OpenProject:BaseUrl"] ?? "http://web:8080";
    var host = cfg["OpenProject:PublicHost"] ?? c.Request.Host.Value;
    var key = cfg["OpenProject:BridgeApiKey"];
    if (string.IsNullOrEmpty(key)) return Results.Problem("OpenProject:BridgeApiKey belum diatur.");
    var email = c.User.FindFirst("email")?.Value;
    if (string.IsNullOrEmpty(email)) return Results.Problem("Akun IDS tanpa email.");
    var isAdmin = IsAdmin(c.User);
    app.Logger.LogInformation("ENTER email={Email} roles=[{Roles}] isAdmin={IsAdmin}", email, string.Join(",", c.User.FindAll("role").Select(r => r.Value)), isAdmin);
    var http = f.CreateClient("op");
    HttpRequestMessage Api(HttpMethod m, string path, object? body = null)
    {
        var r = new HttpRequestMessage(m, baseUrl + path);
        r.Headers.Host = host;
        r.Headers.Authorization = new("Basic", Convert.ToBase64String(System.Text.Encoding.ASCII.GetBytes("apikey:" + key)));
        if (body != null) r.Content = new StringContent(System.Text.Json.JsonSerializer.Serialize(body), System.Text.Encoding.UTF8, "application/json");
        return r;
    }
    var pwd = Convert.ToHexString(System.Security.Cryptography.RandomNumberGenerator.GetBytes(24)) + "aA1!";
    var filter = Uri.EscapeDataString("[{\"login\":{\"operator\":\"=\",\"values\":[\"" + email.Replace("\"", "") + "\"]}}]");
    using var found = await http.SendAsync(Api(HttpMethod.Get, "/api/v3/users?filters=" + filter));
    var doc = System.Text.Json.JsonDocument.Parse(await found.Content.ReadAsStringAsync());
    var els = doc.RootElement.GetProperty("_embedded").GetProperty("elements");
    // IDS dapat mengirim klaim sebagai array JSON (mis. ["username","Nama Lengkap"]); ambil nilai terpanjang.
    string Pick(string t)
    {
        var vs = c.User.FindAll(t).Select(x => x.Value?.Trim() ?? "").Where(x => x.Length > 0)
            .SelectMany(v => { if (v.StartsWith("[")) { try { return System.Text.Json.JsonSerializer.Deserialize<string[]>(v) ?? new string[0]; } catch { } } return new[] { v }; })
            .Select(x => x.Trim()).Where(x => x.Length > 0).ToList();
        return vs.Count == 0 ? "" : vs.OrderByDescending(x => x.Length).First();
    }
    var fullName = Pick("given_name"); if (fullName == "") fullName = Pick("name"); if (fullName == "") fullName = email;
    var familyRaw = Pick("family_name");
    string given, family;
    if (familyRaw != "" && familyRaw != "-") { given = fullName; family = familyRaw; }
    else { var parts = fullName.Split(' ', 2, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries); given = parts[0]; family = parts.Length > 1 ? parts[1] : "-"; }
    if (els.GetArrayLength() == 0)
    {
        using var cr = await http.SendAsync(Api(HttpMethod.Post, "/api/v3/users", new { login = email, email, firstName = given, lastName = family, admin = isAdmin, status = "active", password = pwd }));
        if (!cr.IsSuccessStatusCode) return Results.Problem("Gagal membuat akun OpenProject (" + (int)cr.StatusCode + ").");
    }
    else
    {
        var id = els[0].GetProperty("id").GetInt32();
        using var up = await http.SendAsync(Api(HttpMethod.Patch, "/api/v3/users/" + id, new { admin = isAdmin, status = "active", password = pwd }));
        if (!up.IsSuccessStatusCode) return Results.Problem("Gagal menyinkronkan akun OpenProject (" + (int)up.StatusCode + ").");
    }
    // Login form OpenProject atas nama pengguna
    HttpRequestMessage Web(HttpMethod m, string path, string? cookie = null)
    { var r = new HttpRequestMessage(m, baseUrl + path); r.Headers.Host = host; if (cookie != null) r.Headers.Add("Cookie", cookie); return r; }
    using var form = await http.SendAsync(Web(HttpMethod.Get, "/login"));
    var html = await form.Content.ReadAsStringAsync();
    var m1 = System.Text.RegularExpressions.Regex.Match(html, "name=\"authenticity_token\"[^>]*value=\"([^\"]+)\"");
    if (!m1.Success) m1 = System.Text.RegularExpressions.Regex.Match(html, "name=\"csrf-token\"[^>]*content=\"([^\"]+)\"");
    var sess = string.Join("; ", form.Headers.TryGetValues("Set-Cookie", out var sc) ? sc.Select(x => x.Split(';')[0]) : Array.Empty<string>());
    var post = Web(HttpMethod.Post, "/login", sess);
    post.Content = new FormUrlEncodedContent(new Dictionary<string, string> { ["authenticity_token"] = m1.Groups[1].Value, ["username"] = email, ["password"] = pwd });
    using var res = await http.SendAsync(post);
    if ((int)res.StatusCode != 302) return Results.Problem("Login OpenProject gagal (" + (int)res.StatusCode + ").");
    app.Logger.LogInformation("OP-LOGIN status={S} location={L} cookies={N}", (int)res.StatusCode, res.Headers.Location, res.Headers.TryGetValues("Set-Cookie", out var dbg) ? dbg.Count() : 0);
    if (!res.Headers.TryGetValues("Set-Cookie", out var cks)) return Results.Problem("Login OpenProject tidak mengembalikan sesi (redirect ke " + res.Headers.Location + ").");
    foreach (var ck in cks) c.Response.Headers.Append("Set-Cookie", ck);
    return Results.Redirect("/projects");
});
app.MapGet("/ids/admin", (HttpContext c) =>
{
    if (c.User.Identity?.IsAuthenticated != true) return Results.Redirect("/ids/login?as=admin");
    var ok = IsAdmin(c.User);
    app.Logger.LogInformation("ADMIN-GATE email={Email} roles=[{Roles}] ok={Ok}", c.User.FindFirst("email")?.Value, string.Join(",", c.User.FindAll("role").Select(r => r.Value)), ok);
    return ok ? Results.Redirect("/ids/enter")
              : Results.Content("<!doctype html><meta charset=utf-8><body style=\"font-family:system-ui;padding:2rem\"><h1>Akses ditolak</h1><p>Akun ini bukan Admin.</p><a href=\"/\">Kembali</a><br><a href=\"/ids/logout\">Keluar</a>", "text/html; charset=utf-8", statusCode: 403);
});
app.MapGet("/", (HttpContext c) =>
{
    static string E(string? v) => System.Net.WebUtility.HtmlEncode(v ?? "");
    const string css = ":root{--bg:#f5f6f8;--fg:#1c1f26;--card:#fff;--mut:#667085;--pri:#ae2524;--bd:#e4e7ec}@media(prefers-color-scheme:dark){:root{--bg:#14161a;--fg:#eceef2;--card:#1e2127;--mut:#98a2b3;--bd:#2f343c}}body{margin:0;min-height:100vh;display:grid;place-items:center;background:var(--bg);color:var(--fg);font:16px/1.5 system-ui,sans-serif}main{width:min(440px,calc(100% - 32px));background:var(--card);border:1px solid var(--bd);border-radius:12px;padding:32px}h1{font-size:1.4rem;margin:0 0 4px}p{color:var(--mut);margin:0 0 24px}a.btn{display:block;text-align:center;background:var(--pri);color:#fff;text-decoration:none;padding:12px;border-radius:8px;font-weight:600}a.btn.o{background:none;color:var(--pri);border:1px solid var(--pri)}.sp{height:12px}small{display:block;margin-top:20px;color:var(--mut);text-align:center}dl{margin:0 0 24px;display:grid;grid-template-columns:auto 1fr;gap:8px 16px}dt{color:var(--mut)}dd{margin:0;word-break:break-all}";
    string page(string body) => "<!doctype html><html lang=\"id\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>LPMS3 Login IDS</title><style>" + css + "</style></head><body><main>" + body + "</main></body></html>";
    // Sudah login IDS: '/' (mis. klik logo) menyambung ulang sesi aplikasi lalu masuk ke daftar proyek.
    if (c.User.Identity?.IsAuthenticated == true) return Results.Redirect("/ids/enter");
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
