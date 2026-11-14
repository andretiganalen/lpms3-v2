# DEMO — hapus sebelum go-live: user pimpro.demo + proyek "Pengadaan NVG Monocular 100" dari template Prediktif.
admin = User.admin.active.order(:id).first
User.current = admin
pw = ENV["DEMO_PW"].presence || ::DEMO_PW
u = User.find_or_initialize_by(login: "pimpro.demo")
if u.new_record?
  u.assign_attributes(firstname: "Pimpro", lastname: "Demo", mail: "pimpro.demo@example.com", admin: false,
                      status: User.statuses[:active], language: "id", password: pw, password_confirmation: pw,
                      force_password_change: false)
  u.save!
end
g = Group.find_by!(lastname: "Struktural Fungsi Pelaksanaan Proyek")
Groups::AddUsersService.new(g, current_user: admin).call(ids: [u.id]) unless g.users.include?(u)

tpl = Project.find_by!(identifier: "lpms3-tpl-prediktif")
proj = Project.find_by(identifier: "demo-nvg-monocular-100")
unless proj
  res = Projects::CopyService.new(user: admin, source: tpl)
          .call(target_project_params: { name: "Pengadaan NVG Monocular 100", identifier: "demo-nvg-monocular-100" },
                only: %i[members work_packages queries wiki_page_content])
  abort("copy gagal: #{res.errors.full_messages.join('; ')}") unless res.success?
  proj = res.result
end
proj.update_columns(templated: false)
role = ProjectRole.find_by!(name: "Pimpro")
m = Member.find_or_initialize_by(project: proj, principal: u)
m.roles = [role]; m.save!

vals = { "Kode Proyek" => "DEMO-NVG-001", "Nama Pelanggan" => "Pelanggan Demo", "Nomor Kontrak" => "KTR/DEMO/2026/001",
         "Tanggal Kontrak" => "2026-11-01", "Nilai Kontrak (IDR)" => "1500000000", "Jenis/Klasifikasi Proyek" => "Sistem Pertahanan",
         "Pendekatan Delivery" => "Prediktif", "Tanggal Selesai Kontrak" => "2027-06-30", "Purnajual dipersyaratkan" => "f",
         "Tujuan bisnis / manfaat yang diharapkan" => "Pengadaan 100 unit NVG monocular (data demo).",
         "Pertimbangan keberlanjutan (ESG/K3L)" => "Data demo." }
vals.each do |n, v|
  cf = ProjectCustomField.find_by(name: n) or next
  proj.custom_field_values = { cf.id => cf.field_format == "list" ? cf.custom_options.find_by(value: v)&.id.to_s : (cf.field_format == "bool" ? false : v) }
  proj.save(validate: false)
end
puts "demo ok: proyek ##{proj.id} #{proj.name}; WP #{proj.work_packages.count}; anggota #{proj.members.count}; query #{Query.where(project_id: proj.id).count}; user #{u.login}"
