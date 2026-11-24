# frozen_string_literal: true

# Smoke 1.43: Item Pengadaan ↔ WBS, master rekanan (PFR-001/019/030). Transaksi non-joinable yang di-rollback. Jalankan:
#   docker cp lpms3/smoke/pengadaan_wbs.rb lpms3v2-web-1:/tmp/ && docker exec lpms3v2-web-1 bash -lc "cd /app && bin/rails runner /tmp/pengadaan_wbs.rb"
RES = []
def chk(label, ok, note = nil)
  RES << ok
  puts format("%-4s %s%s", ok ? "PASS" : "FAIL", label, note ? " — #{note}" : "")
end
def raises(klass, msg = nil)
  yield
  false
rescue klass => e
  msg.nil? || e.message.include?(msg)
end

P = OpenProject::Lpms3::Procurement
R = Lpms3::Rekanan
W = Lpms3::Wbs
today = Date.current
files = []
ActiveRecord::Base.transaction(joinable: false) do
  pw = SecureRandom.hex(12) + "Aa1!"
  mk = ->(k) { User.create!(login: "uji143.#{k}", firstname: "Uji143", lastname: k, mail: "uji143.#{k}@example.com", status: User.statuses[:active], password: pw, password_confirmation: pw) }
  pim, pgd, es1, tim = %w[pim pgd es1 tim].map { |k| mk.(k) }
  proj = Project.create!(name: "Proyek Uji 1.43", identifier: "uji143-#{SecureRandom.hex(3)}", public: false, workspace_type: "project")
  %w[Task Item\ Pengadaan Milestone].each { |t| ProjectType.find_or_create_by!(project: proj, type: Type.find_by!(name: t)) }
  proj.enabled_module_names = proj.enabled_module_names | %w[work_package_tracking budgets costs]
  { pim => "Pimpro", pgd => "Fungsi Pengadaan & Pengelola Gudang", es1 => "Pejabat Eselon 1", tim => "Tim Proyek" }.each do |u, r|
    Member.create!(project: proj, principal: u, roles: [ProjectRole.find_by!(name: r)])
  end
  proj.reload
  User.current = pim
  root = W.ensure_root!(proj)
  a = W.add_child!(proj, pim, parent_id: root.id)
  W.update_field!(proj, pim, a.id, "tasks", "Trafo")
  W.update_field!(proj, pim, a.id, "date_plan_start", (today - 30).iso8601)
  W.update_field!(proj, pim, a.id, "date_plan_finish", (today + 60).iso8601)
  bud = Budget.create!(project: proj, author: pim, subject: "Budget uji 1.43", description: "uji", fixed_date: today, base_amount: 10_000_000_000)

  chk "hak rekanan: Pengadaan kelola, Tim Proyek tidak; Pejabat Eselon 1 boleh daftar hitam",
      R.can_manage?(pgd) && !R.can_manage?(tim) && R.can_blacklist?(es1) && !R.can_blacklist?(pgd)
  r1 = R.save!(pgd, { nama: "PT Trafo Uji Sejahtera", kategori: "Trafo" })
  chk "nama rekanan ganda (beda huruf) ditolak", raises(R::Error, "sudah terdaftar") { R.save!(pgd, { nama: "pt trafo uji  sejahtera" }) }
  r2 = R.save!(pgd, { nama: "CV Kabel Bermasalah Uji", kategori: "Kabel" })
  chk "daftar hitam tanpa alasan ditolak", raises(R::Error, "Alasan") { R.daftar_hitam!(es1, r2.id, "") }
  R.daftar_hitam!(es1, r2.id, "Wanprestasi proyek 2025")

  cf = ->(n) { WorkPackageCustomField.find_by!(name: n) }
  st = ->(n) { Status.find_by!(name: n) }
  save = lambda do |wp, status, vals|
    wp.reload
    wp.status = st.(status)
    wp.budget = bud
    wp.custom_field_values = vals.to_h { |n, v| [cf.(n).id, v.to_s] }
    ok = wp.save
    [ok, wp.errors.full_messages.join("; ")]
  end
  item = WorkPackage.create!(project: proj, type: Type.find_by!(name: P::TYPE), subject: "Trafo 60 MVA", status: st.("Rencana"),
                             priority: IssuePriority.default || IssuePriority.first, author: pgd)
  it = P.items(WorkPackage.where(id: item.id)).first
  chk "item tanpa tautan WBS di proyek ber-WBS → temuan wbs_unlinked", it.findings.include?(:wbs_unlinked)
  chk "Tim Proyek tidak dapat menautkan", raises(Lpms3::Wbs::Error, "berwenang") { Lpms3::PengadaanWbs.link!(proj, tim, item.id, a.id) }
  chk "induk (Level 0) tidak dapat dipilih", raises(Lpms3::Wbs::Error, "aktivitas") { Lpms3::PengadaanWbs.link!(proj, pgd, item.id, root.id) }
  Lpms3::PengadaanWbs.link!(proj, pgd, item.id, a.id)
  chk "tertaut ke WBS 1 Trafo", P.items(WorkPackage.where(id: item.id)).first.wbs_node&.id == a.id

  ok, = save.(item, "PR", { "No. PR" => "PR-143", "Nilai pengadaan (IDR)" => "6000000000", "Tanggal dibutuhkan" => (today + 30).iso8601 })
  chk "PR sah", ok
  ok, msg = save.(item, "PO/Kontrak", { "Rekanan" => "CV Kabel Bermasalah Uji", "No. PO" => "PO-143", "No. Kontrak" => "K-143",
                                        "Tanggal kontrak" => today.iso8601, "Tanggal berakhir kontrak" => (today + 120).iso8601 })
  chk "gerbang: rekanan daftar hitam ditolak di PO/Kontrak", !ok && msg.include?("PFR-030"), msg
  ok, msg = save.(item, "PO/Kontrak", { "Rekanan" => "PT Rekanan Asing Uji", "No. PO" => "PO-143", "No. Kontrak" => "K-143",
                                        "Tanggal kontrak" => today.iso8601, "Tanggal berakhir kontrak" => (today + 120).iso8601 })
  chk "rekanan belum terdaftar: lolos gerbang, temuan vendor_unregistered", ok && P.items(WorkPackage.where(id: item.id)).first.findings.include?(:vendor_unregistered), msg
  ok, = save.(item, "PO/Kontrak", { "Rekanan" => "pt trafo uji sejahtera" })
  it = P.items(WorkPackage.where(id: item.id)).first
  chk "rekanan terdaftar dicocokkan tanpa beda huruf", ok && it.rekanan&.id == r1.id && !it.findings.include?(:vendor_unregistered)
  Lpms3::PengadaanWbs.sync_activity!(a)
  chk "PO/Kontrak tanpa bukti di WP aktivitas: % Complete tidak berubah (usulan saja)", a.reload.pct.zero? &&
                                                                                      Lpms3::PengadaanWbs.summary(proj)[a.id][:usulan] == 25

  path = Rails.root.join("tmp", "uji143-#{SecureRandom.hex(3)}.txt").to_s
  File.write(path, "bukti")
  att = Attachment.new(container: a.work_package, author: pim, description: "")
  att.file = ActionDispatch::Http::UploadedFile.new(tempfile: File.open(path), filename: "b.txt", type: "text/plain")
  att.save!
  files << path << att.diskfile.to_s
  chk "dengan bukti: sinkron menaikkan % Complete ke 25 %", Lpms3::PengadaanWbs.sync_activity!(a) == :applied && a.reload.pct == 0.25

  ms = WorkPackage.new(project: proj, type: Type.where(is_milestone: true).first, subject: "Pengiriman trafo", status: Status.where(is_closed: false).order(:id).first,
                       priority: IssuePriority.default || IssuePriority.first, author: pgd, parent_id: item.id)
  ms.save!(validate: false)
  save.(item, "Pengiriman", {})
  save.(item, "GR/SES", { "No. GR/SES" => "GR-143", "Tanggal GR/SES" => today.iso8601 })
  Lpms3::PengadaanWbs.sync_activity!(a)
  chk "GR/SES → aktivitas 75 %", a.reload.pct == 0.75
  chk "evaluasi oleh Tim Proyek ditolak", raises(R::Error, "berwenang") { R.evaluasi!(tim, item, { skor_mutu: 5, skor_waktu: 5, skor_harga: 5, skor_k3l: 5 }) }
  chk "skor di luar 1–5 ditolak", raises(R::Error, "1–5") { R.evaluasi!(pgd, item, { skor_mutu: 6, skor_waktu: 4, skor_harga: 4, skor_k3l: 4 }) }
  ms.update_columns(status_id: Status.where(is_closed: true).order(:id).first.id)
  ok, msg = save.(item, "Selesai", { "No. BA penagihan" => "BA-143", "Tanggal BA penagihan" => today.iso8601 })
  it = P.items(WorkPackage.where(id: item.id)).first
  chk "Selesai (milestone tertutup + BA): lolos gerbang; temuan evaluasi belum", ok && it.findings.include?(:evaluation_missing), msg
  e = R.evaluasi!(pgd, item, { skor_mutu: 5, skor_waktu: 4, skor_harga: 4, skor_k3l: 5, catatan: "Tepat mutu" })
  it = P.items(WorkPackage.where(id: item.id)).first
  chk "evaluasi tersimpan (rata 4.5), temuan hilang; item tanpa temuan", e.rata == 4.5 && it.findings.empty?, it.findings.inspect
  Lpms3::PengadaanWbs.sync_activity!(a)
  chk "Selesai → aktivitas 100 % dan dibekukan", a.reload.pct == 1.0 && Lpms3::Wbs.frozen?(a)
  row = R.list(q: "Trafo Uji").first
  chk "master rekanan: dipakai 1 item, skor 4.5", row && row[:item] == 1 && row[:skor] == 4.5, row&.slice(:item, :skor).inspect
  chk "daftar hitam tidak dapat dipulihkan oleh Pengadaan", raises(R::Error, "Eselon") { R.pulihkan!(pgd, r2.id) }

  puts "\nRINGKASAN: PASS=#{RES.count(true)} FAIL=#{RES.count(false)}"
  raise ActiveRecord::Rollback
end
files.each { |f| FileUtils.rm_f(f) }
