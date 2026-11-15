# LPMS3 MOD-07: dijalankan saat build image. Default bawaan app_title/organization_name -> identitas portal internal.
path = "/app/config/constants/settings/definition.rb"
s = File.read(path)
{ %(app_title: {\n        default: "OpenProject"\n) => %(app_title: {\n        default: "LPMS3"\n),
  %(organization_name: {\n        default: "My Organization"\n) => %(organization_name: {\n        default: "PT Len Industri (Persero)"\n) }.each do |from, to|
  abort "MOD-07: pola tidak ditemukan: #{from.inspect}" unless s.include?(from)
  s = s.sub(from, to)
end
File.write(path, s)

# text_powered_by (dipakai tautan "Powered by OpenProject"): teks netral tanpa %{link}. Plugin tidak bisa menimpa locale inti.
{ "/app/config/locales/en.yml" => ['text_powered_by: "Powered by %{link}"', 'text_powered_by: "LPMS3 internal portal"'],
  "/app/config/locales/crowdin/id.yml" => ["text_powered_by: Didukung oleh %{link}", 'text_powered_by: "Portal internal LPMS3"'] }.each do |file, (from, to)|
  t = File.read(file)
  abort "MOD-07: pola tidak ditemukan di #{file}" unless t.include?(from)
  File.write(file, t.sub(from, to))
end

# Tautan <noscript> ke enable-javascript.com (situs pihak ketiga) dihapus.
base = "/app/app/views/layouts/base.html.erb"
b = File.read(base)
line = %(      <a href="http://www.enable-javascript.com/" target="_blank"><%= t(:noscript_learn_more) %></a>\n)
abort "MOD-07: tautan noscript tidak ditemukan" unless b.include?(line)
File.write(base, b.sub(line, ""))
