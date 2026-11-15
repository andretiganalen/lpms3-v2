# LPMS3 MOD-06: dijalankan saat build image. Setiap penggantian wajib kena (abort bila source OpenProject berubah).
def patch(path, from, to)
  s = File.read(path)
  abort "MOD-06: pola tidak ditemukan di #{path}: #{from.inspect}" unless s.include?(from)
  File.write(path, s.gsub(from, to))
end

# 1. Gravatar: default mati dan tidak pernah aktif (tidak ada hash email ke secure.gravatar.com).
patch "/app/modules/avatars/lib/open_project/avatars/engine.rb", "enable_gravatars: !Rails.env.test?", "enable_gravatars: false"
patch "/app/modules/avatars/lib/open_project/avatars/avatar_manager.rb",
      "          val = settings[:enable_gravatars]\n          ActiveModel::Type::Boolean.new.cast(val)\n", "          false\n"

# 2. CSP: tanpa domain vendor/pihak ketiga (chargebee, start.openproject.com, releases.openproject.com, video onboarding).
csp = "/app/config/initializers/content_security_policy.rb"
patch csp, 'chargebee_src = ["https://*.chargebee.com"]', "chargebee_src = []"
patch csp, "assets_src + %w(js.chargebee.com)", "assets_src"
patch csp, "default_src + [OpenProject::Configuration.enterprise_trial_creation_host]", "default_src.dup"
patch csp, %(      media_src << "\#{onboarding.scheme}://\#{onboarding.host}"\n), ""
patch csp, %(      media_src << "\#{enterprise_video.scheme}://\#{enterprise_video.host}"\n), ""
patch csp, "policy.object_src(OpenProject::Configuration[:security_badge_url])", %(policy.object_src("'none'"))
patch csp, "frame_src << OpenProject::Configuration[:security_badge_url] if OpenProject::Configuration[:security_badge_displayed]\n", ""
