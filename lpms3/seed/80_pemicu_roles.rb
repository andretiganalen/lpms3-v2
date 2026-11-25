require_relative "00_data"
# Pemicu LenO (1.37): peran global registrasi dan persetujuan proyek baru, serta atribut proyek "LPMS-2 Proyek ID". Idempoten.
# Pemegang peran ditetapkan di Administrasi -> Pengguna -> Peran global. Admin LPMS TIDAK otomatis berwenang.
{ "Admin Fungsi Pelaksanaan Proyek" => :lpms3_register_project_trigger,
  "Pejabat Eselon 1 Fungsi Pelaksanaan Proyek" => :lpms3_approve_project_trigger }.each do |name, perm|
  unless OpenProject::AccessControl.permissions.map(&:name).include?(perm)
    puts "  izin #{perm} belum terdaftar (plugin belum dimuat?)"
    next
  end
  role = GlobalRole.find_or_initialize_by(name:)
  role.permissions = [perm]
  role.save!
  puts "  peran global #{name}: #{role.permissions.map(&:to_s).join(',')}"
end
sec = ProjectCustomFieldSection.find_by(name: "Identitas") || ProjectCustomFieldSection.first
cf = ProjectCustomField.find_or_initialize_by(name: "LPMS-2 Proyek ID")
if cf.new_record?
  cf.field_format = "string"
  cf.is_required = false
  cf.project_custom_field_section = sec
  cf.save!
end
puts "pemicu roles ok: LPMS-2 Proyek ID cf=#{cf.id}"
