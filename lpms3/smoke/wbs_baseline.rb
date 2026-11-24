# frozen_string_literal: true

# Smoke 1.41: baseline WBS otomatis (Lpms3::WbsBaseline). Seluruhnya di transaksi non-joinable yang di-rollback;
# hook after_commit CR tidak berjalan di dalamnya, sehingga on_cr_status_change dipanggil langsung. Jalankan:
#   docker cp lpms3/smoke/wbs_baseline.rb lpms3v2-web-1:/tmp/ && \
#   docker exec lpms3v2-web-1 bash -lc "cd /app && bin/rails runner /tmp/wbs_baseline.rb"
RES = []
def chk(label, ok, note = nil)
  RES << ok
  puts format("%-4s %s%s", ok ? "PASS" : "FAIL", label, note ? " — #{note}" : "")
end
def raises(msg = nil)
  yield
  false
rescue Lpms3::Wbs::Error => e
  msg.nil? || e.message.include?(msg)
end

W = Lpms3::Wbs
B = Lpms3::WbsBaseline
files = []
ActiveRecord::Base.transaction(joinable: false) do
  pw = SecureRandom.hex(12) + "Aa1!"
  mk = ->(k) do
    User.create!(login: "uji141.#{k}", firstname: "Uji141", lastname: k, mail: "uji141.#{k}@example.com",
                 status: User.statuses[:active], password: pw, password_confirmation: pw)
  end
  pim, tim = %w[pim tim].map { |k| mk.(k) }
  proj = Project.create!(name: "Proyek Uji 1.41", identifier: "uji141-#{SecureRandom.hex(3)}", public: false, workspace_type: "project")
  %w[Task Change\ Request].each { |t| ProjectType.find_or_create_by!(project: proj, type: Type.find_by!(name: t)) }
  proj.enabled_module_names = proj.enabled_module_names | %w[work_package_tracking]
  Member.create!(project: proj, principal: pim, roles: [ProjectRole.find_by!(name: "Pimpro")])
  Member.create!(project: proj, principal: tim, roles: [ProjectRole.find_by!(name: "Tim Proyek")])
  User.current = pim
  proj.reload

  chk "hook CR terpasang pada WorkPackage", WorkPackage.instance_variable_get(:@lpms3_baseline_cr) == true

  root = W.ensure_root!(proj)
  d0 = Lpms3::Baseline.draft_for(proj)
  chk "WBS baru: draft Baseline 0 (Kick-Off) otomatis", d0&.version == 0 && d0.label.include?("Kick-Off")
  a = W.add_child!(proj, pim, parent_id: root.id)
  b = W.add_child!(proj, pim, parent_id: root.id)
  W.update_field!(proj, pim, a.id, "tasks", "Engineering")
  W.update_field!(proj, pim, b.id, "tasks", "Konstruksi")
  chk "item draft mengikuti WBS (3 node)", Lpms3::BaselineItem.where(baseline_id: d0.id).count == 3

  chk "Baseline 0 ditolak bila aktivitas tanpa tanggal", raises("tanggal rencana") { B.tetapkan_baseline0!(proj, pim) }
  chk "Tim Proyek tidak dapat menetapkan baseline", raises("Pimpro") { B.tetapkan_baseline0!(proj, tim) }
  { a => %w[2026-12-01 2026-12-31], b => %w[2027-01-01 2027-03-31] }.each do |n, (s, f)|
    W.update_field!(proj, pim, n.id, "date_plan_start", s)
    W.update_field!(proj, pim, n.id, "date_plan_finish", f)
  end
  v0 = B.tetapkan_baseline0!(proj, pim)
  chk "Baseline 0 aktif, tanpa CR", v0.status == "ACTIVE" && v0.is_active && v0.change_request_form_id.nil?
  chk "tidak ada draft setelah penetapan", Lpms3::Baseline.draft_for(proj).nil?
  sc = Lpms3::ScurvePlan.where(baseline_id: v0.id)
  chk "Kurva-S bulanan: Σ planned_weight = 100 %", (sc.sum(:planned_weight).to_f - 1).abs < 1e-6, "#{sc.count} baris"
  kcf = ProjectCustomField.find_by(name: "Tanggal Kick-Off (Baseline 0)")
  chk "Tanggal Kick-Off (Baseline 0) terisi", kcf.nil? || CustomValue.find_by(customized: proj, custom_field: kcf)&.value == Date.current.iso8601

  # Progres tidak membuat draft
  wpa = a.reload.work_package
  path = Rails.root.join("tmp", "uji141-bukti-#{SecureRandom.hex(4)}.txt").to_s
  File.write(path, "bukti uji 1.41")
  att = Attachment.new(container: wpa, author: pim, description: "")
  att.file = ActionDispatch::Http::UploadedFile.new(tempfile: File.open(path), filename: "bukti.txt", type: "text/plain")
  att.save!
  files << att.diskfile.to_s << path
  W.update_field!(proj, pim, a.id, "pct_complete", "50")
  chk "% Complete tidak membuat draft baseline", Lpms3::Baseline.draft_for(proj).nil?

  # Perubahan rencana → draft v1 + CR Draft
  W.update_field!(proj, pim, b.id, "date_plan_finish", "2027-04-30")
  d1 = Lpms3::Baseline.draft_for(proj)
  cr = d1&.change_request
  chk "ubah tanggal rencana: draft Baseline 1", d1&.version == 1
  chk "CR (BFR-001) dibuat otomatis: status Draft, assignee Pimpro",
      cr && cr.type.name == "Change Request" && cr.status.name == "Draft" && cr.assigned_to_id == pim.id, "#{cr&.subject} / #{cr&.status&.name}"
  chk "ringkasan perubahan menyebut Date Plan Finish", d1.change_summary.to_s.include?("Date Plan Finish 2027-03-31 → 2027-04-30"), d1.change_summary
  chk "kotak Tugas Pimpro: draft menunggu pengajuan CR", B.cr_pending_for(pim).map(&:id) == [d1.id] && B.cr_pending_for(tim).empty?
  W.update_field!(proj, pim, b.id, "tasks", "Konstruksi Sipil")
  chk "perubahan lanjutan memperbarui draft yang sama + deskripsi CR", Lpms3::Baseline.draft_for(proj).id == d1.id &&
                                                                      cr.reload.description.include?("Konstruksi Sipil")

  # Kembali sama dengan baseline aktif → draft & CR dibuang
  W.update_field!(proj, pim, b.id, "tasks", "Konstruksi")
  W.update_field!(proj, pim, b.id, "date_plan_finish", "2027-03-31")
  chk "WBS kembali = baseline aktif: draft dan CR Draft dibuang", Lpms3::Baseline.draft_for(proj).nil? && !WorkPackage.exists?(cr.id)

  # CR diajukan → perubahan rencana ditahan; progres tetap boleh
  W.update_field!(proj, pim, b.id, "date_plan_finish", "2027-05-31")
  d1 = Lpms3::Baseline.draft_for(proj)
  cr = d1.change_request
  cr.update_columns(status_id: Status.find_by!(name: "Diajukan").id)
  chk "CR diajukan: perubahan rencana ditolak", raises("ditahan") { W.update_field!(proj, pim, b.id, "tasks", "X") }
  chk "CR diajukan: Kembalikan ke baseline ditolak", raises("Change Request") { B.restore_active!(proj, pim) }
  W.update_field!(proj, pim, a.id, "pct_complete", "75")
  chk "CR diajukan: % Complete tetap dapat diisi", a.reload.pct.round(2) == 0.75

  # CR Disetujui → Baseline 1 aktif
  cr.update_columns(status_id: Status.find_by!(name: "Disetujui").id)
  B.on_cr_status_change(cr.reload)
  d1.reload
  chk "CR Disetujui: Baseline 1 ACTIVE, Baseline 0 SUPERSEDED",
      d1.status == "ACTIVE" && d1.is_active && v0.reload.status == "SUPERSEDED" && !v0.is_active
  chk "Kurva-S Baseline 1 dibangun", Lpms3::ScurvePlan.where(baseline_id: d1.id).exists?

  # Pekerjaan selesai dibekukan
  W.update_field!(proj, pim, a.id, "pct_complete", "100")
  snap = Lpms3::WbsDoneSnapshot.find_by(wbs_node_id: a.id)
  chk "100 %: rekam aktivitas dibekukan (snapshot)", snap && snap.wbs_code == "1" && snap.date_actual_finish == Date.current
  chk "aktivitas beku: Tasks tidak dapat diubah", raises("dibekukan") { W.update_field!(proj, pim, a.id, "tasks", "Ubah") }
  chk "aktivitas beku: % Complete tidak dapat diturunkan", raises("dibekukan") { W.update_field!(proj, pim, a.id, "pct_complete", "50") }
  wf_a = a.reload.weigh_factor.to_f
  chk "aktivitas beku: bobot tidak dapat diubah",
      raises("dibekukan") { W.set_weights!(proj, pim, root.id, { a.id.to_s => "40", b.id.to_s => "60" }) }
  c = W.add_child!(proj, pim, parent_id: root.id)
  chk "tambah saudara: bobot aktivitas beku dipertahankan, sisanya kurva normal",
      (a.reload.weigh_factor.to_f - wf_a).abs < 1e-9 && ((b.reload.weigh_factor.to_f + c.reload.weigh_factor.to_f) - (1 - wf_a)).abs < 1e-6,
      [a.weigh_factor.to_f, b.weigh_factor.to_f, c.weigh_factor.to_f].inspect
  d2 = Lpms3::Baseline.draft_for(proj)
  it_a = Lpms3::BaselineItem.find_by(baseline_id: d2.id, wbs_node_id: a.id)
  chk "draft Baseline 2: item beku memakai nilai rekam", d2.version == 2 && it_a.is_frozen && (it_a.weight.to_f - snap.weight.to_f).abs < 1e-9

  # CR Ditolak → REJECTED; kembalikan ke baseline aktif
  cr2 = d2.change_request
  cr2.update_columns(status_id: Status.find_by!(name: "Ditolak").id)
  B.on_cr_status_change(cr2.reload)
  chk "CR Ditolak: draft REJECTED, baseline aktif tetap Baseline 1", d2.reload.status == "REJECTED" && Lpms3::Baseline.active_for(proj).id == d1.id
  kept = B.restore_active!(proj, pim)
  chk "Kembalikan ke Baseline 1: baris baru tanpa progres dihapus, tanpa draft",
      kept.empty? && !Lpms3::WbsNode.exists?(c.id) && Lpms3::Baseline.draft_for(proj).nil?, kept.inspect
  chk "WBS setelah pemulihan = Baseline 1", B.signature(B.current_items(proj)) == B.signature(B.stored_items(d1))

  # Ringkasan
  s = B.summary(proj, today: Date.new(2027, 1, 31))
  chk "Rencana % dari baseline aktif (31 Jan 2027)", s[:planned].to_f.positive? && s[:planned] < 100, s[:planned].to_s
  chk "Aktual % = % Progress Level 0", (s[:actual].to_f - root.reload.pct_progress.to_f * 100).abs < 0.01, s[:actual].to_s
  row = Lpms3::Portfolio.row(proj, Date.current, Date.current - 30)
  chk "Portfolio: label baseline aktif", row[:baseline] == "Baseline 1", row.slice(:rencana, :aktual, :baseline).inspect

  puts "\nRINGKASAN: PASS=#{RES.count(true)} FAIL=#{RES.count(false)}"
  raise ActiveRecord::Rollback
end
files.each { |f| FileUtils.rm_f(f) }
