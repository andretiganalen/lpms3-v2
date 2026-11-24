# frozen_string_literal: true

# Smoke 1.44: persetujuan berjenjang per Fungsi, permintaan anggota (Pimpro menyetujui), draft privat, visibilitas pohon
# Member per penonton. Transaksi non-joinable yang di-rollback. Jalankan:
#   docker cp lpms3/smoke/jalur_fungsi.rb lpms3v2-web-1:/tmp/ && docker exec lpms3v2-web-1 bash -lc "cd /app && bin/rails runner /tmp/jalur_fungsi.rb"
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

AT = Lpms3::ApprovalTask
H = Lpms3::Hierarki
ActiveRecord::Base.transaction(joinable: false) do
  st = H.structure
  unit = ->(c) { Lpms3::OrgUnit.find_by!(structure_id: st.id, code: c) }
  pw = SecureRandom.hex(12) + "Aa1!"
  mk = ->(k) { User.create!(login: "uji144.#{k}", firstname: "Uji144", lastname: k, mail: "uji144.#{k}@example.com", status: User.statuses[:active], password: pw, password_confirmation: pw) }
  pim, qa_staf, qa_e2, qa_e1, fp_staf, adm2, calon, luar = %w[pim qastaf qae2 qae1 fpstaf adm2 calon luar].map { |k| mk.(k) }
  # jabatan: QA staf/E2 di Bagian Quality Assurance, E1 di Divisi QHSE; FP staf & Pimpro di Bagian Project Operation
  qa2 = unit.("DIR-4.4.2"); qa1 = unit.("DIR-4.4"); fp2 = H.unit_primer_of_fungsi("F-MPR")
  Lpms3::UserPosition.active_on.where(position_id: [Lpms3::Position.ensure_for!(qa2, "KEPALA").id, Lpms3::Position.ensure_for!(qa1, "KEPALA").id])
                     .update_all(valid_to: Date.yesterday)
  [[qa_staf, qa2, "STAF"], [qa_e2, qa2, "KEPALA"], [qa_e1, qa1, "KEPALA"], [fp_staf, fp2, "STAF"], [pim, fp2, "STAF"], [adm2, fp2, "ADMIN"]].each do |u, un, k|
    Lpms3::UserPosition.active_on.where(user_id: u.id).update_all(valid_to: Date.yesterday)
    Lpms3::UserPosition.create!(user_id: u.id, position_id: Lpms3::Position.ensure_for!(un, k).id, assignment_type: "DEFINITIF", valid_from: Date.current - 1, updated_at: Time.current)
  end
  proj = Project.create!(name: "Proyek Uji 1.44", identifier: "uji144-#{SecureRandom.hex(3)}", public: false, workspace_type: "project")
  %w[Task Inspeksi\ Mutu Lesson\ Learned].each { |t| ProjectType.find_or_create_by!(project: proj, type: Type.find_by!(name: t)) }
  proj.enabled_module_names = proj.enabled_module_names | %w[work_package_tracking]
  role = ->(n) { ProjectRole.find_by!(name: n) }
  Lpms3::MemberRequest.bypass do
    { pim => "Pimpro", qa_staf => "Fungsi Penjaminan Mutu", fp_staf => "Tim Proyek", adm2 => "Admin Pejabat Eselon 2" }.each do |u, r|
      Member.create!(project: proj, principal: u, roles: [role.(r)])
    end
  end
  proj.reload

  # --- Jalur FUNGSI ---
  User.current = qa_staf
  im = WorkPackage.create!(project: proj, type: Type.find_by!(name: "Inspeksi Mutu"), subject: "Audit mutu uji", status: Status.find_by!(name: "Direncanakan"),
                           priority: IssuePriority.default, author: qa_staf, assigned_to: qa_staf)
  t1 = AT.ajukan!(im, qa_staf, note: "mohon reviu")
  chk "staf Quality → jalur FUNGSI tahap Eselon 2 Bagian Quality Assurance", t1.jalur == "FUNGSI" && t1.stage == "eselon2" && t1.unit_es2_id == qa2.id, "#{t1.jalur}/#{t1.stage}"
  chk "Pejabat Eselon 2 Quality otomatis menjadi member agar dapat meninjau", Member.exists?(project: proj, user_id: qa_e2.id)
  chk "hanya Kepala Bagian Quality yang dapat memutus (bukan Pimpro)", t1.actable_by?(qa_e2) && !t1.actable_by?(pim) && !t1.actable_by?(qa_e1)
  t1.act!(qa_e2, "setujui", "OK")
  t2 = AT.pending.find_by!(work_package_id: im.id)
  chk "disetujui Eselon 2 → tahap Eselon 1 Divisi QHSE; Eselon 1 dimasukkan ke proyek", t2.stage == "eselon1" && t2.jalur == "FUNGSI" && Member.exists?(project: proj, user_id: qa_e1.id)
  chk "Pejabat Eselon 1 proyek (bukan fungsi) tidak dapat memutus", !t2.actable_by?(pim)
  t2.act!(qa_e1, "setujui", "Final")
  fin = AT.final_approved.find_by!(work_package_id: im.id)
  chk "final oleh Pejabat Eselon 1 Fungsi Quality; dapat ditembuskan olehnya", fin.eselon1_for?(qa_e1) && AT.tembusan_candidates(qa_e1).map(&:id).include?(fin.id)
  # --- Jalur PROYEK tetap ---
  User.current = fp_staf
  tk = WorkPackage.create!(project: proj, type: Type.find_by!(name: "Task"), subject: "Isian FP uji", status: Status.find_by!(name: "Baru"),
                           priority: IssuePriority.default, author: fp_staf)
  tp = AT.ajukan!(tk, fp_staf)
  chk "staf Fungsi Pelaksanaan Proyek → jalur PROYEK tahap Pimpro", tp.jalur == "PROYEK" && tp.stage == "pimpro" && tp.actable_by?(pim)

  # --- Draft privat ---
  ll = WorkPackage.create!(project: proj, type: Type.find_by!(name: "Lesson Learned"), subject: "Draft LL uji", status: Status.find_by!(name: "Draft"),
                           priority: IssuePriority.default, author: qa_staf)
  chk "draft terlihat oleh pembuat", WorkPackage.visible(qa_staf).exists?(ll.id)
  chk "draft belum diajukan TIDAK terlihat oleh Pimpro/atasan", !WorkPackage.visible(pim).exists?(ll.id) && !WorkPackage.visible(qa_e2).exists?(ll.id)
  AT.ajukan!(ll, qa_staf)
  chk "setelah diajukan, draft terlihat oleh atasan", WorkPackage.visible(qa_e2).exists?(ll.id)
  sys = WorkPackage.create!(project: proj, type: Type.find_by!(name: "Task"), subject: "Item sistem", status: Status.find_by!(name: "New"),
                            priority: IssuePriority.default, author: User.system)
  chk "item buatan Sistem berstatus New tetap terlihat (bukan draft)", WorkPackage.visible(pim).exists?(sys.id)

  # --- Permintaan anggota ---
  r = Members::CreateService.new(user: adm2).call(project: proj, principal: calon, role_ids: [role.("Tim Proyek").id])
  chk "Admin Eselon 2 memasukkan orang → ditahan, menjadi permintaan", !r.success? && !Member.exists?(project: proj, user_id: calon.id) &&
                                                                    Lpms3::MemberRequest.pending.exists?(project_id: proj.id, user_id: calon.id), r.errors.full_messages.first.to_s[0, 60]
  req = Lpms3::MemberRequest.pending.find_by!(project_id: proj.id, user_id: calon.id)
  chk "permintaan muncul di Tugas Pimpro, bukan Admin E2", Lpms3::MemberRequest.pending_for(pim).map(&:id).include?(req.id) && Lpms3::MemberRequest.pending_for(adm2).empty?
  chk "Admin E2 tidak dapat menyetujui sendiri", raises(Lpms3::MemberRequest::Error, "Pimpro") { req.decide!(adm2, true) }
  chk "calon belum dapat melihat proyek sebelum disetujui", !calon.allowed_in_project?(:view_work_packages, proj)
  req.decide!(pim, true)
  chk "Pimpro menyetujui → calon menjadi member Tim Proyek dan dapat melihat", calon.reload.allowed_in_project?(:view_work_packages, proj.reload)
  r2 = Members::CreateService.new(user: pim).call(project: proj, principal: luar, role_ids: [role.("Tim Proyek").id])
  chk "Pimpro memasukkan orang langsung (tanpa persetujuan)", r2.success? && Member.exists?(project: proj, user_id: luar.id)

  # --- Visibilitas pohon member ---
  vis = ->(u) { d = Lpms3::MemberHierarki.build_for(proj, u); names = []; walk = ->(n) { names << n.person[:user].id if n.person; n.children.each(&walk) }; d[:roots].each(&walk); names }
  full = vis.(pim)
  chk "Pimpro melihat seluruh pohon (termasuk Quality)", full.include?(qa_staf.id) && full.include?(qa_e1.id) && full.include?(fp_staf.id)
  sv = vis.(qa_staf)
  chk "staf Quality hanya melihat garis lurus ke atas (E2, E1) dan dirinya", sv.include?(qa_e2.id) && sv.include?(qa_e1.id) && sv.include?(qa_staf.id) && !sv.include?(fp_staf.id) && !sv.include?(pim.id), sv.size.to_s
  e1v = vis.(qa_e1)
  chk "Pejabat Eselon 1 Quality melihat bawahannya, bukan fungsi lain", e1v.include?(qa_staf.id) && e1v.include?(qa_e2.id) && !e1v.include?(fp_staf.id)

  puts "\nRINGKASAN: PASS=#{RES.count(true)} FAIL=#{RES.count(false)}"
  raise ActiveRecord::Rollback
end
