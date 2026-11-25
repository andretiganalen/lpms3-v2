// Lpms3.IdsLogin — satu pintu login LPMS3 lewat IDS Len (OIDC code + PKCE).
//
// Prinsip (keputusan pemilik 20 Nov 2026):
//  - Hanya ada SATU login untuk semua orang. Tidak ada pilihan "Pengguna/Admin" dan tidak ada akun lokal.
//  - Hak akses ditentukan di dalam aplikasi sebagai Role Akun (Administrasi › Pengguna, peran proyek, grup fungsi),
//    bukan oleh klaim IDS dan bukan oleh pilihan di halaman login. Bridge tidak pernah mengubah bendera admin.
//  - Akun yang dikunci di LPMS3 tetap terkunci: login IDS tidak mengaktifkannya kembali.
using System.Text.Json;
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

const string OpSessionCookie = "_open_project_session";
const string LoopCookie = "lpms3.enter";
var cfg = app.Configuration;
var opBase = cfg["Lpms:BaseUrl"] ?? "http://web:8080";
string OpHost(HttpContext c) => cfg["Lpms:PublicHost"] ?? c.Request.Host.Value ?? "";

// ---------- Halaman (UIx) ----------
// Token dan font Poppins dari uix.css plugin (dilayani OpenProject); versi rilis di URL sebagai pemecah cache.
// Titik dibuang: segmen :digest di route Rails tidak menerima titik (akan 404).
var uixRelease = Uri.EscapeDataString((cfg["Lpms3:Release"] ?? "local").Replace('.', '-'));
string UixPage(string title, string body) =>
    "<!doctype html><html lang=\"id\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
    + "<title>" + title + " · LPMS3</title>"
    + "<link rel=\"preload\" as=\"font\" type=\"font/woff2\" crossorigin href=\"/lpms3/assets/" + uixRelease + "/fonts/poppins-latin-400.woff2\">"
    + "<link rel=\"stylesheet\" href=\"/lpms3/assets/" + uixRelease + "/uix/uix.css\"><style>"
    + "body{margin:0;min-height:100vh;display:grid;place-items:center;background:var(--uix-surface-page);color:var(--uix-text-body);font:var(--uix-fs-body)/1.5 var(--uix-font)}"
    + "main{width:min(400px,calc(100% - 32px));box-sizing:border-box;background:var(--uix-surface);border:1px solid var(--uix-border);border-radius:var(--uix-radius-card);box-shadow:var(--uix-shadow-xs);padding:32px}"
    + "h1{margin:0 0 4px;font-size:var(--uix-fs-page);font-weight:600;color:var(--uix-text-head)}"
    + "p{margin:0 0 24px;color:var(--uix-text-secondary)}"
    + "a.btn{display:flex;align-items:center;justify-content:center;height:38px;box-sizing:border-box;border-radius:var(--uix-radius-control);font-weight:500;text-decoration:none;box-shadow:var(--uix-shadow-xs);background:var(--uix-primary);color:var(--uix-on-primary);border:1px solid var(--uix-primary)}"
    + "a.btn:hover{background:var(--uix-primary-strong);border-color:var(--uix-primary-strong)}"
    + "a.btn.o{background:var(--uix-surface);color:var(--uix-text-body);border-color:var(--uix-border-strong)}a.btn.o:hover{background:var(--uix-surface-muted)}"
    + ".sp{height:12px}small{display:block;margin-top:20px;font-size:12px;color:var(--uix-text-secondary);text-align:center}"
    + "</style></head><body><main>" + body + "</main></body></html>";

static string E(string? v) => System.Net.WebUtility.HtmlEncode(v ?? "");

IResult Page(string title, string body, int status = 200) =>
    Results.Content(UixPage(E(title), body), "text/html; charset=utf-8", statusCode: status);

// Halaman galat: selalu ada jalan keluar (coba lagi / keluar), tidak pernah JSON mentah.
IResult Fail(string title, string message, int status, bool retry = true) =>
    Page(title, "<h1>" + E(title) + "</h1><p>" + E(message) + "</p>"
        + (retry ? "<a class=\"btn\" href=\"/ids/enter\">Coba lagi</a><div class=\"sp\"></div>" : "")
        + "<a class=\"btn o\" href=\"/ids/logout\">Keluar</a>", status);

// ---------- Tujuan sesudah login (deep link) ----------
// OpenProject mengalihkan sesi kedaluwarsa ke /login?back_url=<URL absolut>; proxy meneruskannya ke /ids/login.
// Hanya jalur lokal di host aplikasi yang diterima (cegah open redirect); jalur login/logout ditolak agar tidak berputar.
string? SafeBack(string? raw, HttpContext c)
{
    if (string.IsNullOrWhiteSpace(raw) || raw.Length > 2000) return null;
    string path;
    if (raw.StartsWith('/'))
    {
        if (raw.StartsWith("//") || raw.StartsWith("/\\")) return null;
        path = raw;
    }
    else if (Uri.TryCreate(raw, UriKind.Absolute, out var u) && (u.Scheme == Uri.UriSchemeHttp || u.Scheme == Uri.UriSchemeHttps)
             && string.Equals(u.IsDefaultPort ? u.Host : u.Host + ":" + u.Port, OpHost(c), StringComparison.OrdinalIgnoreCase))
        path = u.PathAndQuery;
    else return null;
    if (path.Contains('\\') || path.Any(char.IsControl)) return null;
    var p = path.Split('?', 2)[0].ToLowerInvariant();
    string[] blocked = { "/ids", "/login", "/logout", "/signin-oidc", "/signout-callback-oidc", "/auth", "/account" };
    if (p == "/" || blocked.Any(b => p == b || p.StartsWith(b + "/"))) return null;
    return path;
}

string EnterUrl(string? back) => back is null ? "/ids/enter" : "/ids/enter?back=" + Uri.EscapeDataString(back);

// ---------- Rute ----------
app.MapGet("/health", () => Results.Ok("OK"));

// Satu-satunya pintu masuk. Parameter lama "as" (Pengguna/Admin) diabaikan: hak akses ditentukan di aplikasi.
app.MapGet("/ids/login", (HttpContext c) =>
{
    var enter = EnterUrl(SafeBack(c.Request.Query["back_url"].FirstOrDefault() ?? c.Request.Query["back"].FirstOrDefault(), c));
    if (c.User.Identity?.IsAuthenticated == true) return Results.Redirect(enter);
    return Results.Challenge(new AuthenticationProperties { RedirectUri = enter });
});

// Tautan lama gerbang Admin: tidak ada lagi gerbang terpisah.
app.MapGet("/ids/admin", () => Results.Redirect("/"));

// Logout tunggal: akhiri sesi OpenProject di server (bukan hanya hapus cookie), lalu keluar dari IDS.
// Tanpa ini, '/' akan menyambung ulang sesi OpenProject dari sesi IDS yang masih aktif.
app.MapGet("/ids/logout", async (HttpContext c, IHttpClientFactory f) =>
{
    var raw = c.Request.Headers.Cookie.ToString();
    var opCookie = raw.Split(';').Select(x => x.Trim()).FirstOrDefault(x => x.StartsWith(OpSessionCookie + "="));
    if (opCookie != null)
    {
        try
        {
            using var req = new HttpRequestMessage(HttpMethod.Get, opBase + "/logout");
            req.Headers.Host = OpHost(c);
            req.Headers.Add("Cookie", opCookie);
            using var res = await f.CreateClient("op").SendAsync(req);
            app.Logger.LogInformation("LOGOUT op-session status={S}", (int)res.StatusCode);
        }
        catch (Exception ex) { app.Logger.LogWarning(ex, "LOGOUT gagal mengakhiri sesi OpenProject di server; cookie tetap dihapus."); }
    }
    c.Response.Cookies.Delete(OpSessionCookie, new CookieOptions { Path = "/" });
    c.Response.Cookies.Delete(LoopCookie, new CookieOptions { Path = "/ids" });
    return Results.SignOut(new AuthenticationProperties { RedirectUri = "/" },
        new[] { CookieAuthenticationDefaults.AuthenticationScheme, OpenIdConnectDefaults.AuthenticationScheme });
});

// Jembatan: sesudah login IDS, cari/buat akun OpenProject lalu masuk atas nama pengguna.
// Bendera admin dan status kunci TIDAK diubah di sini: keduanya milik aplikasi (Role Akun).
app.MapGet("/ids/enter", async (HttpContext c, IHttpClientFactory f) =>
{
    var back = SafeBack(c.Request.Query["back"].FirstOrDefault(), c);
    if (c.User.Identity?.IsAuthenticated != true) return Results.Redirect(back is null ? "/ids/login" : "/ids/login?back=" + Uri.EscapeDataString(back));

    // Penjaga loop: 5 kali masuk ke sini dalam 10 detik berarti sesi aplikasi terus ditolak dan pengguna dipantulkan balik.
    var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
    var (n, since) = (0, now);
    if (c.Request.Cookies.TryGetValue(LoopCookie, out var lc) && lc.Split(':') is [var a, var b]
        && int.TryParse(a, out var na) && long.TryParse(b, out var nb) && now - nb < 10) (n, since) = (na, nb);
    if (n >= 5)
    {
        c.Response.Cookies.Delete(LoopCookie, new CookieOptions { Path = "/ids" });
        app.Logger.LogWarning("ENTER loop terdeteksi email={Email}", c.User.FindFirst("email")?.Value);
        return Fail("Sesi tidak dapat dibuat", "Aplikasi berulang kali menolak sesi Anda. Silakan keluar lalu masuk kembali; bila tetap terjadi, hubungi administrator.", 500, retry: false);
    }
    c.Response.Cookies.Append(LoopCookie, (n + 1) + ":" + since, new CookieOptions { Path = "/ids", HttpOnly = true, SameSite = SameSiteMode.Lax, MaxAge = TimeSpan.FromSeconds(10) });

    var key = cfg["Lpms:BridgeApiKey"];
    if (string.IsNullOrEmpty(key)) { app.Logger.LogError("Lpms:BridgeApiKey belum diatur."); return Fail("Layanan belum siap", "Konfigurasi login aplikasi belum lengkap. Hubungi administrator.", 503); }

    var email = (c.User.FindFirst("email")?.Value
                 ?? c.User.FindAll("preferred_username").Select(x => x.Value).FirstOrDefault(v => v.Contains('@')))?.Trim().ToLowerInvariant();
    if (string.IsNullOrEmpty(email) || email.Length > 254 || !System.Text.RegularExpressions.Regex.IsMatch(email, @"^[^@\s""]+@[^@\s""]+\.[^@\s""]+$"))
        return Fail("Akun IDS tanpa email", "Akun IDS Anda tidak menyertakan alamat email yang valid, sehingga tidak dapat dicocokkan dengan akun LPMS3.", 403, retry: false);

    var http = f.CreateClient("op");
    var host = OpHost(c);
    HttpRequestMessage Api(HttpMethod m, string path, object? body = null)
    {
        var r = new HttpRequestMessage(m, opBase + path);
        r.Headers.Host = host;
        r.Headers.Authorization = new("Basic", Convert.ToBase64String(System.Text.Encoding.ASCII.GetBytes("apikey:" + key)));
        if (body != null) r.Content = new StringContent(JsonSerializer.Serialize(body), System.Text.Encoding.UTF8, "application/json");
        return r;
    }
    try
    {
        var filter = JsonSerializer.Serialize(new[] { new Dictionary<string, object> { ["login"] = new Dictionary<string, object> { ["operator"] = "=", ["values"] = new[] { email } } } });
        using var found = await http.SendAsync(Api(HttpMethod.Get, "/api/v3/users?filters=" + Uri.EscapeDataString(filter)));
        if (!found.IsSuccessStatusCode)
        {
            app.Logger.LogError("ENTER cari akun gagal status={S}", (int)found.StatusCode);
            return Fail("Gagal masuk", "Akun LPMS3 tidak dapat diperiksa saat ini. Coba lagi beberapa saat lagi.", 502);
        }
        using var doc = JsonDocument.Parse(await found.Content.ReadAsStringAsync());
        var els = doc.RootElement.GetProperty("_embedded").GetProperty("elements");
        var pwd = Convert.ToHexString(System.Security.Cryptography.RandomNumberGenerator.GetBytes(24)) + "aA1!";

        if (els.GetArrayLength() == 0)
        {
            // IDS dapat mengirim klaim sebagai array JSON (mis. ["username","Nama Lengkap"]); ambil nilai terpanjang.
            string Pick(string t)
            {
                var vs = c.User.FindAll(t).Select(x => x.Value?.Trim() ?? "").Where(x => x.Length > 0)
                    .SelectMany(v => { if (v.StartsWith('[')) { try { return JsonSerializer.Deserialize<string[]>(v) ?? Array.Empty<string>(); } catch (JsonException) { } } return new[] { v }; })
                    .Select(x => x.Trim()).Where(x => x.Length > 0).ToList();
                return vs.Count == 0 ? "" : vs.OrderByDescending(x => x.Length).First();
            }
            var fullName = Pick("given_name"); if (fullName == "") fullName = Pick("name"); if (fullName == "") fullName = email;
            var familyRaw = Pick("family_name");
            string given, family;
            if (familyRaw != "" && familyRaw != "-") { given = fullName; family = familyRaw; }
            else { var parts = fullName.Split(' ', 2, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries); given = parts[0]; family = parts.Length > 1 ? parts[1] : "-"; }
            // Akun baru selalu pengguna biasa. Admin diberikan oleh administrator di dalam aplikasi.
            using var cr = await http.SendAsync(Api(HttpMethod.Post, "/api/v3/users", new { login = email, email, firstName = given, lastName = family, admin = false, status = "active", password = pwd }));
            if (!cr.IsSuccessStatusCode)
            {
                app.Logger.LogError("ENTER buat akun gagal email={Email} status={S}", email, (int)cr.StatusCode);
                return Fail("Gagal masuk", "Akun LPMS3 Anda tidak dapat dibuat. Hubungi administrator.", 502);
            }
            app.Logger.LogInformation("ENTER akun baru email={Email} admin=false", email);
        }
        else
        {
            var el = els[0];
            var id = el.GetProperty("id").GetInt32();
            var status = el.TryGetProperty("status", out var st) ? st.GetString() : null;
            var admin = el.TryGetProperty("admin", out var ad) && ad.ValueKind == JsonValueKind.True;
            if (status == "locked")
            {
                app.Logger.LogWarning("ENTER ditolak: akun terkunci email={Email}", email);
                return Fail("Akun dinonaktifkan", "Akun LPMS3 Anda sedang dinonaktifkan. Hubungi administrator aplikasi untuk mengaktifkannya kembali.", 403, retry: false);
            }
            // Hanya kata sandi sesi bridge yang diperbarui; status diaktifkan hanya untuk akun undangan/terdaftar yang belum aktif.
            object patch = status == "active" ? new { password = pwd } : new { status = "active", password = pwd };
            using var up = await http.SendAsync(Api(HttpMethod.Patch, "/api/v3/users/" + id, patch));
            if (!up.IsSuccessStatusCode)
            {
                app.Logger.LogError("ENTER sinkron akun gagal email={Email} status={S}", email, (int)up.StatusCode);
                return Fail("Gagal masuk", "Akun LPMS3 Anda tidak dapat disiapkan. Coba lagi, atau hubungi administrator.", 502);
            }
            app.Logger.LogInformation("ENTER email={Email} admin={Admin} status={Status}", email, admin, status);
        }

        // Login form OpenProject atas nama pengguna.
        HttpRequestMessage Web(HttpMethod m, string path, string? cookie = null)
        { var r = new HttpRequestMessage(m, opBase + path); r.Headers.Host = host; if (cookie != null) r.Headers.Add("Cookie", cookie); return r; }
        using var form = await http.SendAsync(Web(HttpMethod.Get, "/login"));
        var html = await form.Content.ReadAsStringAsync();
        var m1 = System.Text.RegularExpressions.Regex.Match(html, "name=\"authenticity_token\"[^>]*value=\"([^\"]+)\"");
        if (!m1.Success) m1 = System.Text.RegularExpressions.Regex.Match(html, "name=\"csrf-token\"[^>]*content=\"([^\"]+)\"");
        if (!m1.Success) { app.Logger.LogError("ENTER token CSRF login OpenProject tidak ditemukan (status {S}).", (int)form.StatusCode); return Fail("Gagal masuk", "Aplikasi belum siap menerima login. Coba lagi beberapa saat lagi.", 502); }
        var sess = string.Join("; ", form.Headers.TryGetValues("Set-Cookie", out var sc) ? sc.Select(x => x.Split(';')[0]) : Array.Empty<string>());
        var post = Web(HttpMethod.Post, "/login", sess);
        post.Content = new FormUrlEncodedContent(new Dictionary<string, string> { ["authenticity_token"] = m1.Groups[1].Value, ["username"] = email, ["password"] = pwd });
        using var res = await http.SendAsync(post);
        var loc = res.Headers.Location?.ToString() ?? "";
        if ((int)res.StatusCode != 302 || loc.Contains("/login"))
        {
            app.Logger.LogError("ENTER login OpenProject gagal email={Email} status={S} location={L}", email, (int)res.StatusCode, loc);
            return Fail("Gagal masuk", "Sesi aplikasi tidak dapat dibuat untuk akun Anda. Coba lagi, atau hubungi administrator.", 502);
        }
        if (!res.Headers.TryGetValues("Set-Cookie", out var cks) || !cks.Any(x => x.StartsWith(OpSessionCookie + "=")))
        {
            app.Logger.LogError("ENTER login OpenProject tanpa cookie sesi email={Email} location={L}", email, loc);
            return Fail("Gagal masuk", "Sesi aplikasi tidak dapat dibuat untuk akun Anda. Coba lagi, atau hubungi administrator.", 502);
        }
        foreach (var ck in cks) c.Response.Headers.Append("Set-Cookie", ck);
        return Results.Redirect(back ?? "/projects");
    }
    catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or JsonException or KeyNotFoundException or InvalidOperationException)
    {
        app.Logger.LogError(ex, "ENTER galat jembatan email={Email}", email);
        return Fail("Gagal masuk", "Aplikasi tidak dapat dihubungi saat ini. Coba lagi beberapa saat lagi.", 502);
    }
});

// Halaman depan: satu tombol untuk semua orang. Bila sesi IDS masih ada, langsung sambung ke aplikasi.
app.MapGet("/", (HttpContext c) =>
    c.User.Identity?.IsAuthenticated == true
        ? Results.Redirect("/ids/enter")
        : Page("Masuk", "<h1>LPMS3</h1><p>Masuk menggunakan akun IDS Len.</p>"
            + "<a class=\"btn\" href=\"/ids/login\">Masuk dengan IDS</a>"
            + "<small>Satu pintu masuk untuk semua pengguna. Hak akses ditentukan oleh peran akun Anda di LPMS3.</small>"));

app.Run();
