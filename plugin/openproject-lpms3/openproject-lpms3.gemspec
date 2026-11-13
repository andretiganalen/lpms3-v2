Gem::Specification.new do |s|
  s.name        = "openproject-lpms3"
  s.version     = "0.1.0"
  s.authors     = "LPMS3 Len Industri"
  s.email       = "lpms3@len.co.id"
  s.homepage    = "https://github.com/andretiganalen/lpms3-v2"
  s.summary     = "LPMS3 - plugin OpenProject untuk manajemen multi-proyek Len"
  s.description = "Tema UIx, struktur organisasi & fungsi, sidebar LPMS3 (lihat docs/plan/10_Spesifikasi_Teknis_v1.3.md)"
  s.license     = "GPL-3.0-only"
  s.files       = Dir["{app,config,db,lib,assets}/**/*"] + %w(README.md)
  s.metadata["rubygems_mfa_required"] = "true"
end
