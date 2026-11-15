require "action_dispatch/testing/integration"
Rails.application.eager_load!
puts "== audit_mod08 (verifikasi pascadeploy) =="
R = []
def chk(name, ok, detail = nil) R << [name, ok, detail]; puts "#{ok ? 'PASS' : 'FAIL'} | #{name} | #{detail}" end
F = OpenProject::Lpms3::Features
C = InhouseFeatureCatalog

# 1. Saklar
orig = Setting.internal_enabled_features
chk "setting default/kosong", orig == [], orig.inspect
Setting.internal_enabled_features = %w[board_view team_planner_view bogus]
chk "setting tersimpan & tersaring katalog", F.enabled_keys.sort == %i[board_view team_planner_view], F.enabled_keys.inspect
chk "ON tapi belum diimplementasikan => enabled? false", F.enabled?(:team_planner_view) == false
# simulasi fitur selesai (hanya di proses ini, tidak disimpan)
F.singleton_class.prepend(Module.new { def implemented?(k) = k.to_sym == :team_planner_view || super })
chk "ON + implemented => true", F.enabled?(:team_planner_view) == true
Setting.internal_enabled_features = %w[board_view]
chk "OFF => false", F.enabled?(:team_planner_view) == false
Setting.internal_enabled_features = %w[team_planner_view]
chk "ON kembali => true", F.enabled?(:team_planner_view) == true
Setting.internal_enabled_features = orig
chk "setting dipulihkan", Setting.internal_enabled_features == orig

# 2. Katalog 30+5
chk "katalog 35 (30 utama + 5 kompat.)", C.all.size == 35 && C.all.count { _1.cluster != "F" } == 30 && C.all.count { _1.cluster == "F" } == 5
chk "kunci katalog == Features::KEYS", C.keys.sort == F.keys.map(&:to_s).sort
chk "semua kolom terisi", C.all.none? { |f| [f.title, f.menu_location, f.description, f.objective, f.expected_output].any? { _1.to_s.strip.empty? } }
chk "EnterpriseToken tidak diubah (allows_to? false utk 35 fitur)", F.keys.none? { EnterpriseToken.allows_to?(_1) }

# 3. HTTP penuh sebagai admin (sesi disimulasikan hanya di proses ini)
admin = User.admin.active.where.not(login: ["", nil]).first || User.admin.active.first
ApplicationController.class_eval { define_method(:find_current_user) { admin } } if admin
s = ActionDispatch::Integration::Session.new(Rails.application); s.host! "192.168.125.14:5100"
paths = ["/", "/admin", "/admin/info", "/admin/enterprise", "/admin/lpms3/organisasi", "/admin/lpms3/internal_features", "/projects", "/my/page", "/admin/settings/general", "/panduan-internal"]
bodies = {}
paths.each do |pa|
  begin
    s.get pa
    bodies[pa] = s.response.body.to_s
    chk "GET #{pa} bukan 5xx", s.response.status < 500, s.response.status.to_s
  rescue => e
    chk "GET #{pa} bukan 5xx", false, "#{e.class}: #{e.message[0, 120]}"
  end
end
# POST saklar via UI
begin
  s.patch "/admin/lpms3/internal_features", params: { enabled_features: ["team_planner_view"], authenticity_token: "x" }
  chk "PATCH saklar (CSRF aktif di test? status)", s.response.status < 500, s.response.status.to_s
rescue => e
  chk "PATCH saklar bukan 5xx", false, e.message[0, 120]
end
Setting.internal_enabled_features = orig

all_html = bodies.values.join("\n")
# github.com di /admin/info = tautan versi (pasif, diterima)
ext_by = bodies.map { |pa, b| [pa, b.scan(%r{https?://[^\s"'<>)]+}).map { URI(_1).host rescue nil }.compact.uniq.reject { |h| h == "192.168.125.14" || h == "www.w3.org" || (pa == "/admin/info" && h == "github.com") }] }.reject { _1[1].empty? }
ext = ext_by.flat_map(&:last).uniq
puts "EXT_BY_PAGE #{ext_by.inspect}"
chk "halaman tanpa host eksternal", ext.empty?, ext.inspect
chk "tanpa gravatar", !all_html.include?("gravatar")
chk "halaman fitur memuat 35 kunci", C.keys.all? { bodies["/admin/lpms3/internal_features"].to_s.include?(_1) }

# 4. Gravatar, banner, badge, CSP, token
chk "Gravatar nonaktif", OpenProject::Avatars::AvatarManager.gravatar_enabled? == false
chk "security badge nonaktif", Class.new { include SecurityBadgeHelper }.new.display_security_badge_graphic? == false
chk "blok homescreen vendor dibuang", (OpenProject::Static::Homescreen[:blocks].map { _1[:name] } & %w[community upsell new_features]).empty?
css = File.read("/app/custom-plugins/openproject-lpms3/assets/uix/uix.css")
chk "CSS sembunyikan banner Enterprise", css.include?("op-enterprise-banner") && css.include?("display: none !important")
csp = File.read("/app/config/initializers/content_security_policy.rb")
chk "CSP tanpa domain vendor", %w[chargebee start.openproject releases.openproject].none? { csp.include?(_1) } || csp.scan(/chargebee_src = \[\]/).any?
sl = File.read("/app/config/static_links.yml")
chk "static_links tanpa openproject.org/.com", !sl.match?(/href:\s*https?:\/\/[a-z.]*openproject\.(org|com)/)
chk "app_title = LPMS3", Setting.app_title == "LPMS3", Setting.app_title
chk "IDS-only: self_registration 0, login_required", Setting.self_registration.to_i == 0 && Setting.login_required?

# 5. Lisensi di image
%w[LICENSE COPYRIGHT COPYRIGHT_short].each { |f| chk "/app/#{f} ada", File.size?("/app/#{f}").to_i > 0, File.size("/app/#{f}").to_s }
puts "RINGKASAN: #{R.count { _1[1] }} PASS, #{R.count { !_1[1] }} FAIL dari #{R.size}"
