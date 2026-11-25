# frozen_string_literal: true

# Smoke 1.37: registrasi -> persetujuan -> proyek dibuat dari template, dari pemicu LenO.
# Seluruhnya dalam satu transaksi yang di-rollback (tidak meninggalkan data). Jalankan:
#   docker cp lpms3/smoke/pemicu_registrasi.rb lpms3v2-web-1:/tmp/ && \
#   docker exec lpms3v2-web-1 bash -lc "cd /app && bin/rails runner /tmp/pemicu_registrasi.rb"
PT = Lpms3::ProjectTrigger
RES = []
def chk(label, ok, note = nil)
  RES << ok
  puts format("%-4s %s%s", ok ? "PASS" : "FAIL", label, note ? " — #{note}" : "")
end
def raises(klass = PT::Error)
  yield
  false
rescue klass
  true
end

ActiveRecord::Base.transaction do
  pw = SecureRandom.hex(12) + "Aa1!"
  mk = ->(k, admin: false) do
    User.create!(login: "uji137.#{k}", firstname: "Uji137", lastname: k, mail: "uji137.#{k}@example.com", admin:,
                 status: User.statuses[:active], password: pw, password_confirmation: pw)
  end
  reg, appr, both, pim, vp, outsider = %w[reg appr both pim vp luar].map { |k| mk.(k) }
  adm = mk.("admin", admin: true)
  r_reg = GlobalRole.find_by!(name: "Admin Fungsi Pelaksanaan Proyek")
  r_app = GlobalRole.find_by!(name: "Pejabat Eselon 1 Fungsi Pelaksanaan Proyek")
  Member.create!(project: nil, principal: reg, roles: [r_reg])
  Member.create!(project: nil, principal: appr, roles: [r_app])
  Member.create!(project: nil, principal: both, roles: [r_reg, r_app])

  chk "peran: registrar/approver dari peran global", PT.registrar?(reg) && PT.approver?(appr) && !PT.registrar?(appr)
  chk "admin OpenProject tanpa peran global tidak berwenang", !PT.registrar?(adm) && !PT.approver?(adm)

  tr, = PT.receive!(kode_proyek: "UJI137-LPMS2-001", id_kiriman: "s1", lpms2_proyek_id: 991)
  chk "pemicu baru muncul di tugas registrar", PT.pending_for(reg).include?(tr) && PT.pending_for(outsider).empty?

  ok = { template: "lpms3-predik", nama_proyek: "Proyek Uji 1.37", kode_proyek_lpms3: "U37-00000001",
         pimpro_id: pim.id, vp_id: vp.id }
  chk "bukan registrar tidak bisa mengusulkan", raises { tr.usulkan!(outsider, **ok) }
  chk "admin tanpa peran tidak bisa mengusulkan", raises { tr.usulkan!(adm, **ok) }
  chk "kode LPMS3 salah format ditolak", raises { tr.usulkan!(reg, **ok, kode_proyek_lpms3: "SALAH") }
  chk "template bukan daftar ditolak", raises { tr.usulkan!(reg, **ok, template: "1ud-123ud001") }
  chk "Pimpro wajib", raises { tr.usulkan!(reg, **ok, pimpro_id: nil) }

  tr.usulkan!(both, **ok, catatan: "uji")
  chk "usulan → diusulkan", tr.reload.status == "diusulkan" && tr.diusulkan_oleh == both
  chk "pengusul (pemegang dua peran) tidak melihat tugas putusnya", !PT.pending_for(both).include?(tr)
  chk "pengusul tidak bisa memutus sendiri", raises { tr.putuskan!(both, "setujui") }
  chk "admin tanpa peran tidak bisa memutus", raises { tr.putuskan!(adm, "setujui") }
  chk "kembalikan tanpa catatan ditolak", raises { tr.putuskan!(appr, "kembalikan", "") }
  tr.putuskan!(appr, "kembalikan", "lengkapi nama")
  chk "dikembalikan → registrar dapat tugas lagi", tr.reload.status == "dikembalikan" && PT.pending_for(reg).include?(tr)

  tr.usulkan!(reg, **ok)
  tr2, = PT.receive!(kode_proyek: "UJI137-LPMS2-002", id_kiriman: "s2")
  chk "kode LPMS3 yang sudah diusulkan pemicu lain ditolak", raises { tr2.usulkan!(reg, **ok) }

  tr.putuskan!(appr, "setujui", "ok")
  chk "disetujui", tr.reload.status == "disetujui" && tr.diputus_oleh == appr
  chk "pembuatan proyek masuk antrean job",
      GoodJob::Job.where(job_class: "Lpms3::BuatProyekDariPemicuJob").where("serialized_params::text LIKE ?", "%#{tr.id}%").exists?

  t0 = Time.current
  proj = tr.buat_proyek!
  tr.reload
  chk "proyek dibuat dari template", tr.status == "proyek_dibuat" && proj.persisted? && !proj.templated, "#{(Time.current - t0).round(1)} dtk, #{proj.identifier}"
  wp = proj.work_packages.joins(:type).reorder(nil).group("types.name").count
  chk "WP template tersalin (Dokumen Rencana 9, Milestone 4)", wp["Dokumen Rencana"] == 9 && wp["Milestone"] == 4, wp.inspect
  # Baca langsung dari custom_values (runner = Anonymous, yang tidak melihat atribut proyek).
  cv = ->(n) { CustomValue.find_by(customized: proj, custom_field: ProjectCustomField.find_by!(name: n))&.value }
  chk "semua atribut proyek aktif di proyek baru",
      ProjectCustomFieldProjectMapping.where(project_id: proj.id).count == ProjectCustomField.count
  chk "Kode Proyek terisi", cv.("Kode Proyek") == "U37-00000001"
  chk "LPMS-2 Proyek ID terisi", cv.("LPMS-2 Proyek ID") == "991"
  chk "atribut Pimpro & VP terisi", cv.("Pimpro") == pim.id.to_s && cv.("Fungsi Pelaksanaan Proyek (struktural)") == vp.id.to_s
  chk "Pendekatan Delivery = Prediktif",
      ProjectCustomField.find_by!(name: "Pendekatan Delivery").custom_options.find_by(id: cv.("Pendekatan Delivery"))&.value == "Prediktif"
  roles = ->(u) { Member.find_by(project: proj, principal: u)&.roles&.map(&:name) || [] }
  chk "Pimpro anggota dengan peran Pimpro", roles.(pim).include?("Pimpro")
  chk "VP anggota dengan peran Fungsi Pelaksanaan Proyek (Struktural)", roles.(vp).include?("Fungsi Pelaksanaan Proyek (Struktural)")
  chk "Kick-Off belum dibuat (menunggu Dokumen Inisiasi final)", !Lpms3::Kickoff.exists?(project: proj)

  again = tr.buat_proyek!
  chk "job ganda tidak membuat proyek kedua", again.id == proj.id && Project.where(name: "Proyek Uji 1.37").count == 1
  chk "kiriman LenO sesudahnya → final (200)", PT.receive!(kode_proyek: "UJI137-LPMS2-001", id_kiriman: "s9").last == :final
  chk "kode LPMS3 dipakai proyek → usulan baru ditolak", raises { tr2.usulkan!(reg, **ok) }

  tr2.batalkan!(reg, "duplikat")
  chk "batal → dibatalkan", tr2.reload.status == "dibatalkan"
  kinds = tr.events.map(&:kind)
  chk "riwayat lengkap", (%w[diterima diusulkan dikembalikan disetujui proyek_dibuat] - kinds).empty?, kinds.join(",")

  html = User.execute_as(reg) do
    Lpms3::PemicuController.render(:show, layout: false,
                                          assigns: { trigger: tr2.reload, users: PT.user_options.first(3),
                                                     templates: Project.templated.to_a, kode_re: PT.kode_regexp })
  end
  chk "halaman pemicu dirender", html.include?("UJI137-LPMS2-002")

  puts "---"
  puts "RINGKASAN: PASS=#{RES.count(true)} FAIL=#{RES.count(false)}"
  raise ActiveRecord::Rollback
end
puts "sisa data uji: pemicu=#{PT.where('kode_proyek LIKE ?', 'UJI137-%').count} proyek=#{Project.where(name: 'Proyek Uji 1.37').count} " \
     "user=#{User.where('login LIKE ?', 'uji137.%').count}"
