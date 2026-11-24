# frozen_string_literal: true

# Smoke 1.40: editor WBS bobot cascading (Lpms3::Wbs). Seluruhnya di transaksi non-joinable yang di-rollback.
# Lampiran bukti yang dibuat dihapus dari disk di akhir. Jalankan:
#   docker cp lpms3/smoke/wbs_editor.rb lpms3v2-web-1:/tmp/ && \
#   docker exec lpms3v2-web-1 bash -lc "cd /app && bin/rails runner /tmp/wbs_editor.rb"
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
files = []
ActiveRecord::Base.transaction(joinable: false) do
  bc = (1..7).map { |n| W.bell_curve(n) }
  chk "bell curve: Σ = 100 % untuk n = 1..7", bc.all? { |w| (w.sum - 1).abs < 1e-9 }
  chk "bell curve: simetris, tengah terbesar, tepi terkecil (n = 5)",
      bc[4].first == bc[4].last && bc[4].max == bc[4][2] && bc[4].min == bc[4][0], bc[4].map { |v| (v * 100).round(2) }.inspect

  pw = SecureRandom.hex(12) + "Aa1!"
  mk = ->(k) do
    User.create!(login: "uji140.#{k}", firstname: "Uji140", lastname: k, mail: "uji140.#{k}@example.com",
                 status: User.statuses[:active], password: pw, password_confirmation: pw)
  end
  pim, tim, luar, es1h, staf = %w[pim tim luar es1h staf].map { |k| mk.(k) }
  proj = Project.create!(name: "Proyek Uji 1.40", identifier: "uji140-#{SecureRandom.hex(3)}", public: false, workspace_type: "project")
  ProjectType.find_or_create_by!(project: proj, type: Type.find_by!(name: "Task"))
  proj.enabled_module_names = proj.enabled_module_names | %w[work_package_tracking]
  Member.create!(project: proj, principal: pim, roles: [ProjectRole.find_by!(name: "Pimpro")])
  Member.create!(project: proj, principal: tim, roles: [ProjectRole.find_by!(name: "Tim Proyek")])
  User.current = pim
  W.ensure_assignable_roles!

  chk "hak edit: Pimpro ya, Tim Proyek tidak, orang luar tidak",
      W.can_edit?(pim, proj) && !W.can_edit?(tim, proj) && !W.can_edit?(luar, proj)

  root = W.ensure_root!(proj)
  chk "Level 0 dibuat: kode 0, bobot 100 %", root.wbs_code == "0" && root.weight.to_f == 1 && root.level == "Level 0"
  a = W.add_child!(proj, pim, parent_id: root.id)
  b = W.add_child!(proj, pim, parent_id: root.id)
  chk "dua Level 1: kode 1 dan 2, bobot 50/50", [a.reload.wbs_code, b.reload.wbs_code] == %w[1 2] &&
                                                [a.weigh_factor.to_f, b.weigh_factor.to_f] == [0.5, 0.5]
  a1 = W.add_child!(proj, pim, parent_id: a.id)
  a2 = W.add_child!(proj, pim, parent_id: a.id)
  a3 = W.add_child!(proj, pim, parent_id: a.id)
  wf = [a1, a2, a3].map { |n| n.reload.weigh_factor.to_f }
  chk "tambah anak: kelompok saudara diatur ulang kurva normal", wf == W.bell_curve(3), wf.inspect
  chk "kode 1.1/1.2/1.3", [a1, a2, a3].map(&:wbs_code) == %w[1.1 1.2 1.3]
  chk "weight cascading: weight 1.2 = 50 % × wf 1.2", (a2.weight.to_f - 0.5 * wf[1]).abs < 1e-9, a2.weight.to_f.to_s

  chk "bobot Σ ≠ 100 % ditolak", raises("harus 100") { W.set_weights!(proj, pim, a.id, { a1.id.to_s => "30", a2.id.to_s => "30", a3.id.to_s => "30" }) }
  W.set_weights!(proj, pim, a.id, { a1.id.to_s => "30", a2.id.to_s => "30", a3.id.to_s => "40" })
  chk "bobot 30/30/40 diterima dan weight ikut (template)", (a3.reload.weight.to_f - 0.2).abs < 1e-9, a3.weight.to_f.to_s

  W.update_field!(proj, pim, a1.id, "tasks", "Survey Plan")
  W.update_field!(proj, pim, a1.id, "date_plan_start", "2026-12-01")
  W.update_field!(proj, pim, a1.id, "date_plan_finish", "2026-12-29")
  W.update_field!(proj, pim, a2.id, "date_plan_start", "2026-12-10")
  W.update_field!(proj, pim, a2.id, "date_plan_finish", "2027-01-15")
  a.reload
  chk "tanggal induk = min/max anak", a.date_plan_start == Date.new(2026, 12, 1) && a.date_plan_finish == Date.new(2027, 1, 15)
  wp1 = a1.reload.work_package
  chk "work package aktivitas dibuat: subjek, tanggal, induk WP", wp1 && wp1.subject == "1.1 Survey Plan" &&
                                                                  wp1.start_date == Date.new(2026, 12, 1) && wp1.parent&.id == a.work_package_id,
      wp1&.subject
  chk "tanggal di baris induk ditolak", raises("aktivitas") { W.update_field!(proj, pim, a.id, "date_plan_start", "2026-12-01") }
  chk "Finish < Start ditolak", raises("tidak boleh sebelum") { W.update_field!(proj, pim, a1.id, "date_plan_finish", "2026-11-01") }

  chk "PIC bukan anggota proyek ditolak", raises("anggota proyek") { W.update_field!(proj, pim, a1.id, "pic", "u:#{luar.id}") }
  W.update_field!(proj, pim, a1.id, "pic", "u:#{tim.id}")
  chk "PIC anggota: assignee WP ikut", a1.reload.work_package.assigned_to_id == tim.id

  chk "% Complete tanpa bukti ditolak", raises("bukti") { W.update_field!(proj, pim, a1.id, "pct_complete", "50") }
  path = Rails.root.join("tmp", "uji140-bukti-#{SecureRandom.hex(4)}.txt").to_s
  File.write(path, "bukti uji 1.40")
  att = Attachment.new(container: wp1, author: pim, description: "")
  att.file = ActionDispatch::Http::UploadedFile.new(tempfile: File.open(path), filename: "bukti.txt", type: "text/plain")
  att.save!
  files << att.diskfile.to_s << path
  W.update_field!(proj, pim, a1.id, "pct_complete", "50")
  a1.reload
  chk "% Complete 50 dengan bukti: progres = weight × 50 %, Actual Start terisi",
      (a1.pct_progress.to_f - a1.weight.to_f * 0.5).abs < 1e-9 && a1.date_actual_start == Date.current
  chk "% Complete 33 ditolak (hanya 0/25/50/75/100)", raises("harus 0") { W.update_field!(proj, pim, a1.id, "pct_complete", "33") }
  root.reload
  chk "progres proyek (Level 0) = Σ kontribusi aktivitas", (root.pct_progress.to_f - a1.pct_progress.to_f).abs < 1e-9, root.pct_progress.to_f.to_s
  chk "% Complete WP ikut (done_ratio 50)", a1.work_package.reload.done_ratio == 50

  chk "aktivitas berprogres tidak dapat dipecah", raises("berprogres") { W.add_child!(proj, pim, parent_id: a1.id) }
  chk "aktivitas berprogres tidak dapat dihapus", raises("berprogres") { W.delete!(proj, pim, a1.id) }
  chk "induk dengan anak tidak dapat dihapus", raises("sub-tugas") { W.delete!(proj, pim, a.id) }

  W.move!(proj, pim, a3.id, "up")
  chk "pindah ke atas: penomoran ulang + subjek WP ikut", a3.reload.wbs_code == "1.2" && a2.reload.wbs_code == "1.3" &&
                                                         a2.work_package.reload.subject.start_with?("1.3 ")
  wp_b = b.reload.work_package_id
  W.delete!(proj, pim, b.id)
  chk "hapus Level 1 kosong: WP ikut terhapus, saudara kembali 100 %",
      !WorkPackage.exists?(wp_b) && a.reload.weigh_factor.to_f == 1.0

  # PIC dari unit Eselon 1: Kepala ES1 menugaskan staf dari unitnya.
  es1 = Lpms3::Hierarki.unit_eselon1_of_fungsi
  bagian = es1.children.first
  [[es1h, es1, "KEPALA"], [staf, bagian, "STAF"]].each do |u, unit, kind|
    Lpms3::UserPosition.create!(position: Lpms3::Position.ensure_for!(unit, kind), user: u, assignment_type: "DEFINITIF",
                                valid_from: Date.current - 1, updated_at: Time.current)
  end
  chk "PIC Fungsi harus unit Eselon 1", raises("Eselon 1") { W.update_field!(proj, pim, a2.id, "pic", "f:#{bagian.id}") }
  W.update_field!(proj, pim, a2.id, "pic", "f:#{es1.id}")
  chk "tugas penugasan muncul untuk Kepala ES1, tidak untuk orang lain",
      W.pic_pending_for(es1h).select { |n| n.project_id == proj.id }.map(&:id) == [a2.id] && W.pic_pending_for(tim).empty?
  chk "tim ES1 mencakup staf unit di bawahnya", W.unit_team(es1).include?(staf)
  chk "orang luar unit tidak dapat ditugaskan", raises("anggota tim") { W.assign_from_unit!(es1h, a2.id, luar.id) }
  chk "selain Kepala/Admin ES1 tidak dapat menugaskan", raises("bukan Kepala") { W.assign_from_unit!(tim, a2.id, staf.id) }
  W.assign_from_unit!(es1h, a2.id, staf.id)
  a2.reload
  chk "penugasan ES1: staf jadi member Tim Proyek, PIC + assignee WP",
      a2.pic_user_id == staf.id && Member.find_by(project: proj, principal: staf)&.roles&.map(&:name)&.include?("Tim Proyek") &&
      a2.work_package.reload.assigned_to_id == staf.id
  chk "setelah ditugaskan, tugas hilang dari kotak ES1", W.pic_pending_for(es1h).none? { |n| n.project_id == proj.id }

  rows = W.rows(proj)
  chk "peringatan: aktivitas tanpa tanggal terdeteksi", W.warnings(rows).any? { |w| w.include?("tanggal rencana") }

  puts "\nRINGKASAN: PASS=#{RES.count(true)} FAIL=#{RES.count(false)}"
  raise ActiveRecord::Rollback
end
files.each { |f| FileUtils.rm_f(f) }
