# MOD-09: hapus menu "Edisi Enterprise", menu & route "Link Eksternal", dan kunci setting capture link.
menus = "/app/config/initializers/menus.rb"
m = File.read(menus)
m = m.sub(/^  menu\.push :enterprise,.*?\n\n/m, "")
m = m.sub(/^  menu\.push :settings_external_links,.*?\n\n/m, "")
raise "MOD-09: menu Enterprise/Link Eksternal masih ada" if m.include?("menu.push :enterprise,") || m.include?(":settings_external_links")
File.write(menus, m)

routes = "/app/config/routes.rb"
r = File.read(routes)
r2 = r.gsub(%r{^\s*resource :external_links, controller: "/admin/settings/external_links_settings", only: %i\[show update\]\n}, "")
raise "MOD-09: route external_links masih ada" if r2.include?("external_links_settings")
File.write(routes, r2)

defn = "/app/config/constants/settings/definition.rb"
d = File.read(defn)
d2 = d.gsub("writable: -> { EnterpriseToken.allows_to?(:capture_external_links) }", "writable: false")
raise "MOD-09: setting capture masih bisa diubah" if d2.include?("EnterpriseToken.allows_to?(:capture_external_links)")
File.write(defn, d2)
puts "MOD-09 selesai"
