# D10 smoke test: alur Inisiasi -> Closing pada proyek uji sementara. Data uji dihapus di akhir (ensure).
# Dijalankan lewat lpms3/smoke/run.sh. Keluaran: baris PASS/FAIL/N-A per skenario U.
admin = User.admin.active.order(:id).first
User.current = admin
RES = []
def chk(id, desc, ok, note = nil)
  RES << [id, desc, ok]
  puts format("%-5s %-4s %s%s", ok.nil? ? "N/A" : (ok ? "PASS" : "FAIL"), id, desc, note ? " — #{note}" : "")
end
def safe(id, desc)
  r = yield
  chk(id, desc, r.is_a?(Array) ? r[0] : r, r.is_a?(Array) ? r[1] : nil)
rescue => e
  chk(id, desc, false, "#{e.class}: #{e.message[0, 160]}")
end

TAG = "smoke-d10"
users = {}
proj = nil
begin
  # --- prasyarat: user uji (pw acak) ---
  pw = SecureRandom.hex(12) + "Aa1!"
  { pimpro: "Pimpro", pengawas: "Fungsi Pengawasan Proyek", approver: "Approver CCM", pembaca: "Pembaca (Informed)" }.each do |k, role|
    u = User.new(login: "#{TAG}.#{k}", firstname: "Smoke", lastname: k.to_s, mail: "#{TAG}.#{k}@example.com", admin: false,
                 status: User.statuses[:active], language: "id", password: pw, password_confirmation: pw, force_password_change: false)
    u.save!
    users[k] = [u, role]
  end

  # U01 buat proyek dari template
  tpl = Project.find_by!(identifier: "lpms3-tpl-prediktif")
  res = Projects::CopyService.new(user: admin, source: tpl)
          .call(target_project_params: { name: "SMOKE D10", identifier: "#{TAG}-proyek" },
                only: %i[members work_packages wiki_page_content])
  raise "copy gagal: #{res.errors.full_messages.join('; ')}" unless res.success?
  proj = res.result
  proj.update_columns(templated: false)
  users.each do |_k, (u, role)|
    m = Member.find_or_initialize_by(project: proj, principal: u)
    m.roles = [ProjectRole.find_by!(name: role)]; m.save!
  end
  safe("U01", "Proyek dari template: 35 WP aktivitas + 9 Dokumen Rencana + 4 milestone gate") do
    c = proj.work_packages.joins(:type).reorder(nil).group("types.name").count
    [c["Task"] == 35 && c["Dokumen Rencana"] == 9 && c["Milestone"] == 4, c.inspect]
  end
  safe("U01", "Custom field proyek wajib terisi & dapat disimpan (Kode Proyek)") do
    cf = ProjectCustomField.find_by!(name: "Kode Proyek")
    proj.custom_field_values = { cf.id => "SMOKE-D10-001" }
    [proj.save(validate: false) && proj.reload.custom_value_for(cf)&.value == "SMOKE-D10-001"]
  end
  safe("U02", "WP 'Penetapan Tim' ada; due date otomatis = tgl kode + 14 hari") do
    wp = proj.work_packages.where("subject ILIKE ?", "%penetapan pimpro dan tim%").first
    [wp ? nil : false, wp ? "WP ada, aturan +14 hari belum diimplementasi (butuh plugin)" : "WP tidak ditemukan"]
  end
  safe("U03", "Gate G1–G4 sebagai milestone; penutupan gate dengan kriteria") do
    n = proj.work_packages.joins(:type).where(types: { name: "Milestone" }).where("subject ILIKE '%G_%' OR subject ILIKE '%gate%'").count
    [n >= 4 ? nil : false, "milestone gate #{n}; validasi kriteria penutupan belum diimplementasi (butuh plugin)"]
  end

  START = { "Change Request" => "Draft", "Risiko" => "Teridentifikasi", "Bahaya K3L" => "Teridentifikasi",
            "Item Pengadaan" => "Rencana", "NCR" => "Terbuka", "Deliverable" => "Baru", "Action Item" => "Baru",
            "Lesson Learned" => "Draft" }.freeze
  def wp_new(proj, user, type, subject, extra = {})
    t = Type.find_by!(name: type)
    start = START[type] && Status.find_by!(name: START[type])
    r = WorkPackages::CreateService.new(user: user).call(project: proj, type_id: t.id, subject: subject,
                                                         **(start ? { status_id: start.id } : {}), **extra)
    raise "buat #{type}: #{r.errors.full_messages.join('; ')}" unless r.success?
    r.result
  end
  def move(wp, user, status_name)
    st = Status.find_by!(name: status_name)
    r = WorkPackages::UpdateService.new(user: user, model: wp.reload).call(status_id: st.id)
    r.success?
  end
  pimpro, pengawas, approver, pembaca = %i[pimpro pengawas approver pembaca].map { |k| users[k][0] }

  # U06 Change Request end-to-end
  cr = nil
  safe("U06", "CR dibuat (Draft) oleh Pimpro") { cr = wp_new(proj, pimpro, "Change Request", "CR uji"); [cr.status.name == "Draft", cr.status.name] }
  safe("U06", "Transisi terlarang ditolak: Pimpro Draft→Disetujui") { [!move(cr, pimpro, "Disetujui")] }
  safe("U06", "Pimpro: Draft→Diajukan") { [move(cr, pimpro, "Diajukan")] }
  safe("U06", "Pimpro tidak boleh Diajukan→Sidang CCM (hak Pengawasan)") { [!move(cr, pimpro, "Sidang CCM")] }
  safe("U06", "Pengawas: Diajukan→Analisis Dampak→Sidang CCM") { [move(cr, pengawas, "Analisis Dampak") && move(cr, pengawas, "Sidang CCM")] }
  safe("U06", "Approver CCM: Sidang CCM→Ditunda→Sidang CCM→Disetujui") do
    [move(cr, approver, "Ditunda") && move(cr, approver, "Sidang CCM") && move(cr, approver, "Disetujui")]
  end
  safe("U06", "Pimpro: Disetujui→Implementasi→Verifikasi; Pengawas: Verifikasi→Ditutup") do
    [move(cr, pimpro, "Implementasi") && move(cr, pimpro, "Verifikasi") && move(cr, pengawas, "Ditutup")]
  end
  cr2 = wp_new(proj, pimpro, "Change Request", "CR ditolak")
  safe("U06", "Jalur Ditolak") do
    [move(cr2, pimpro, "Diajukan") && move(cr2, pengawas, "Analisis Dampak") && move(cr2, pengawas, "Sidang CCM") && move(cr2, approver, "Ditolak")]
  end

  # U08–U12, U14, U15: siklus tiap tipe dapat dibuat & dipindah status
  { "U08" => ["Risiko", "Risiko uji", %w[Dianalisis Dipantau Terjadi]],
    "U09" => ["Bahaya K3L", "Bahaya uji", %w[Dinilai Pengendalian\ Diterapkan Ditutup]],
    "U10" => ["Item Pengadaan", "Item uji", %w[Proses\ Pengadaan PO/Kontrak Pengiriman GR/SES Selesai]],
    "U11" => ["NCR", "NCR uji", %w[Analisis\ Akar\ Masalah Koreksi Verifikasi Ditutup]],
    "U12" => ["Deliverable", "Deliverable uji", %w[Dikerjakan Verifikasi\ Internal Validasi\ Pelanggan Diterima\ Pelanggan]],
    "U14" => ["Action Item", "Action item uji", %w[Dikerjakan Selesai]],
    "U15" => ["Lesson Learned", "LL uji", %w[Ditinjau Dipublikasikan]] }.each do |id, (type, subj, flow)|
    safe(id, "#{type}: buat & lewati status #{flow.join('→')}") do
      w = wp_new(proj, pimpro, type, subj)
      bad = flow.reject { |s| move(w, pimpro, s) }
      [bad.empty?, bad.empty? ? nil : "gagal di: #{bad.join(',')}"]
    end
  end
  safe("U11", "Deliverable tak bisa 'Diterima' bila NCR kritikal terbuka") { [nil, "aturan prosedural + query kontrol; belum ada validasi sistem"] }
  safe("U12", "Lampiran BA wajib sebelum 'Diterima Pelanggan'") { [nil, "dicek di checklist; belum ada validasi sistem"] }

  # U18 hak akses
  safe("U18", "Pembaca tidak bisa mengubah WP") do
    w = proj.work_packages.joins(:type).where(types: { name: "Task" }).first
    r = WorkPackages::UpdateService.new(user: pembaca, model: w).call(subject: "diubah pembaca")
    [!r.success?]
  end
  safe("U18", "Pembaca tidak punya izin view_budgets / edit_work_packages") do
    [!pembaca.allowed_in_project?(:edit_work_packages, proj) && !pembaca.allowed_in_project?(:view_budgets, proj)]
  end

  # U16/U17 Penutupan: set Jenis Penutupan, arsipkan
  safe("U16", "Penutupan: Jenis Penutupan=Selesai 100%, proyek diarsipkan (read-only)") do
    cf = ProjectCustomField.find_by!(name: "Jenis Penutupan")
    opt = cf.custom_options.order(:id).first
    proj.custom_field_values = { cf.id => opt.id.to_s }
    proj.save(validate: false)
    Projects::ArchiveService.new(user: admin, model: proj).call
    proj.reload
    w = proj.work_packages.first
    r = WorkPackages::UpdateService.new(user: pimpro, model: w).call(subject: "setelah arsip")
    [!proj.active? && !r.success?, "opsi=#{opt.value}; active=#{proj.active?}"]
  end
  safe("U16", "Sub-project purnajual otomatis saat penutupan") { [nil, "belum diimplementasi (butuh plugin)"] }

  # Integrasi D9: mirror StarRocks
  sleep 15
  safe("D9", "Proyek uji & statusnya tersinkron ke outbox (synced)") do
    n = ActiveRecord::Base.connection.select_value("select count(*) from lpms3.sync_outbox where synced_at is null and table_name='project' and row_pk='#{proj.id}'").to_i
    [n == 0, "pending=#{n}"]
  end
ensure
  # --- pembersihan data uji ---
  begin
    if proj
      proj = Project.find_by(id: proj.id)
      proj&.update_columns(active: true)
      Projects::DeleteService.new(user: admin, model: proj).call if proj
    end
  rescue => e
    puts "cleanup proyek gagal: #{e.class}: #{e.message[0, 200]}"
  end
  users.each_value { |(u, _)| (User.find_by(id: u.id)&.then { |x| x.destroy rescue Principals::DeleteJob.perform_now(x) }) }
  puts "---"
  puts "RINGKASAN: PASS=#{RES.count { |r| r[2] == true }} FAIL=#{RES.count { |r| r[2] == false }} N/A=#{RES.count { |r| r[2].nil? }}"
end
