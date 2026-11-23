# Dummy LenO Mobile (sesuai mock-up): project demo, empat WO dengan laporan harian dan status pengajuan.
# PIC = eselon2.staff01.mpr (Tim Proyek), Pejabat Eselon 2 = eselon2.pejabat01.mpr (Project Sponsor). Idempoten.
admin = User.find_by!(login: "andre.tigana.k@len.co.id")
User.current = admin
hib = Project.find_by!(identifier: "lpms3-tpl-hibrid")
pj = Project.find_or_initialize_by(identifier: "leno-mobile-demo")
pj.name = "LenO Mobile Demo"
pj.workspace_type = "project"
pj.public = false
pj.templated = false
pj.enabled_module_names = hib.enabled_module_names
pj.save!
hib.project_types.each { |pt| pj.project_types.find_or_create_by!(type_id: pt.type_id, variant_id: pt.variant_id) }

pic = User.find_by!(login: "eselon2.staff01.mpr@len.co.id")
approver = User.find_by!(login: "eselon2.pejabat01.mpr@len.co.id")
[[pic, "Tim Proyek"], [approver, "Project Sponsor"]].each do |u, role|
  next if Member.exists?(project: pj, principal: u)
  Member.create!(project: pj, principal: u, roles: [ProjectRole.find_by!(name: role)])
end

task = Type.find_by!(name: "Task")
def wo_wp(project, task, pic, subject, done, start, due, status_name)
  wp = WorkPackage.find_or_initialize_by(project_id: project.id, subject: subject)
  if wp.new_record?
    wp.type = task
    wp.author = User.find_by!(login: "andre.tigana.k@len.co.id")
    wp.priority = IssuePriority.default || IssuePriority.first
    wp.assigned_to = pic
    wp.status = Status.find_by!(name: status_name)
    wp.save!
  end
  wp.update_columns(done_ratio: done, start_date: start, due_date: due, status_id: Status.find_by!(name: status_name).id)
  wp.reload
end

WOS = {
  "0142" => ["Instalasi panel kontrol ruang operator", 65, Date.new(2026, 11, 3), Date.new(2026, 11, 23), "Dikerjakan"],
  "0131" => ["Pemasangan tray kabel lantai 2", 100, Date.new(2026, 11, 10), Date.new(2026, 11, 15), "Dikerjakan"],
  "0138" => ["Penarikan kabel daya & terminasi", 100, Date.new(2026, 11, 9), Date.new(2026, 11, 20), "Dikerjakan"],
  "0127" => ["Survei lokasi & pengukuran", 100, Date.new(2026, 11, 4), Date.new(2026, 11, 8), "Selesai"],
}.to_h do |code, (title, done, start, due, st)|
  [code, wo_wp(pj, task, pic, "[WO-#{code}] #{title}", done, start, due, st)]
end

# Laporan harian: [tanggal, progres, prev, pelaksanaan, keterangan, kendala, status]
def report!(wp, date, progress, prev, keterangan, status, author, execution: "sesuai", kendala: nil)
  r = Lpms3::DailyReport.find_or_initialize_by(work_package_id: wp.id, report_date: date)
  r.assign_attributes(progress:, prev_progress: prev, execution:, keterangan:, kendala:, status:,
                      author_id: author.id, sent_at: (status == "terkirim" ? date.to_time.change(hour: 16) : nil))
  r.save!
end
R = {
  "0142" => [[Date.new(2026,11,4), 20, 0, "Persiapan lokasi dan pemasangan rak panel"], [Date.new(2026,11,5), 35, 20, "Pemasangan rak panel A"],
             [Date.new(2026,11,6), 35, 35, "Menunggu material kabel kontrol"], [Date.new(2026,11,13), 50, 35, "Penarikan kabel kontrol ke panel"],
             [Date.new(2026,11,14), 65, 50, "Wiring terminal blok selesai"]],
  "0131" => [[Date.new(2026,11,12), 60, 30, "Pemasangan tray kabel jalur 1-2"], [Date.new(2026,11,13), 100, 60, "Pemasangan tray kabel jalur 3-4 selesai"]],
  "0138" => [[Date.new(2026,11,13), 60, 40, "Penarikan kabel daya jalur A"], [Date.new(2026,11,14), 80, 60, "Penarikan kabel daya jalur B"],
             [Date.new(2026,11,15), 100, 80, "Terminasi panel B selesai, uji tahanan isolasi lulus."]],
  "0127" => [[Date.new(2026,11,4), 40, 0, "Survei titik lokasi"], [Date.new(2026,11,5), 80, 40, "Pengukuran area kerja"], [Date.new(2026,11,8), 100, 80, "Berita acara survei disusun"]],
}
R.each do |code, rows|
  wp = WOS[code]
  rows.each { |d, p, prev, ket| report!(wp, d, p, prev, ket, "terkirim", pic) }
end
# Draft belum dikirim (tertunggak) untuk WO-0142.
report!(WOS["0142"], Date.new(2026,11,16), 75, 65, "Uji kontinuitas kabel kontrol, 2 foto", "draft", pic)

# Status pengajuan.
def review!(wp, state, attrs = {})
  r = Lpms3::WoReview.for(wp)
  r.update!({ state: }.merge(attrs))
  r
end
review!(WOS["0142"], "berjalan")
review!(WOS["0131"], "ditolak", submitted_at: Time.zone.parse("2026-11-13 17:00"), decided_at: Time.zone.parse("2026-11-14 09:10"),
        decided_by_id: approver.id, reject_reason: "Foto terminasi kurang jelas.")
review!(WOS["0138"], "diajukan", submitted_at: Time.zone.parse("2026-11-15 17:05"))
review!(WOS["0127"], "disetujui", submitted_at: Time.zone.parse("2026-11-08 16:30"), decided_at: Time.zone.parse("2026-11-09 10:00"), decided_by_id: approver.id)

puts "leno demo: #{pj.identifier}; WO #{WOS.keys.join(', ')}; laporan #{Lpms3::DailyReport.where(work_package_id: WOS.values.map(&:id)).count}"
