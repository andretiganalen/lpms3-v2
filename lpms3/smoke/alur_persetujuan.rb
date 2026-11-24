# frozen_string_literal: true

# Skenario alur persetujuan berjenjang + Kick-Off (BOP-001 §5.2.2). Dijalankan dalam transaksi lalu di-rollback:
#   docker exec lpms3v2-web-1 bundle exec rails runner /tmp/alur_persetujuan.rb
# Menghasilkan baris PASS/FAIL. Tidak meninggalkan data di database.
def u(login) = User.find_by!(login:)
results = []
check = lambda do |label, cond, detail = nil|
  results << [label, !!cond]
  puts "#{cond ? 'PASS' : 'FAIL'} | #{label}#{detail ? " | #{detail}" : ''}"
end

proyek = Project.find_by!(name: "Proyek Kristian")

ActiveRecord::Base.transaction do
  staff = u("eselon2.staff02.mpr@len.co.id")
  # WP uji sementara (dibuang saat rollback)
  wp = WorkPackage.new(project: proyek, type: Type.first, subject: "Dokumen Uji Alur Persetujuan",
                       author: staff, status: Status.default, priority: IssuePriority.default)
  wp.save!(validate: false)
  e2 = u("eselon2.pejabat02.mpr@len.co.id")
  e1 = u("eselon1.spesialis02.mpr@len.co.id")
  adm = u("eselon2.admin02.pwp@len.co.id")
  analis = u("eselon2.spesialis02.pwp@len.co.id")
  dir = u("direksi.pejabat01.dir@len.co.id")
  AT = Lpms3::ApprovalTask
  # Sejak 1.42 kursi Proyek Kristian dipegang persona: akun uji dimasukkan di dalam transaksi ini (di-rollback),
  # tanpa jabatan aktif agar memakai jalur PROYEK, dan Kick-Off lama dikosongkan.
  Lpms3::Kickoff.where(project: proyek).delete_all
  { staff => "Tim Proyek", e2 => "Pejabat Eselon 2", e1 => "Pejabat Eselon 1", adm => "Fungsi Pengawasan Proyek",
    analis => "Project Analis", dir => "Direksi" }.each do |usr, r|
    Lpms3::UserPosition.active_on.where(user_id: usr.id).update_all(valid_to: Date.yesterday)
    Lpms3::MemberRequest.bypass do
      m = Member.find_or_initialize_by(project: proyek, principal: usr)
      m.roles = [ProjectRole.find_by!(name: r)]
      m.save!
    end
  end
  staff, e2, e1, adm, analis, dir = [staff, e2, e1, adm, analis, dir].map { |x| User.find(x.id) } # buang cache izin
  proyek.reload

  t1 = AT.ajukan!(wp, staff, note: "uji")
  check.("staff mengajukan → tahap pimpro", t1.stage == "pimpro" && t1.state == "menunggu")
  check.("Pejabat Eselon 2 melihat tugas (bypass)", AT.pending_for(e2).include?(t1))
  check.("staff TIDAK bisa memutus", AT.pending_for(staff).exclude?(t1))

  t1.act!(e2, "setujui")
  t2 = AT.where(work_package_id: wp.id, stage: "eselon1", state: "menunggu").first
  check.("bypass Pejabat Eselon 2 → meneruskan ke Eselon 1", t2 && t1.reload.bypassed)
  check.("Pejabat Eselon 2 tidak bisa setujui final di tahap eselon1", !t2.actions_for(e2).include?("setujui"))

  t2.act!(e1, "setujui")
  check.("Eselon 1 menyetujui → disetujui final", t2.reload.state == "disetujui")
  check.("Kick-Off dibuat setelah persetujuan final", Lpms3::Kickoff.exists?(project: proyek, state: "menunggu_analis"))
  check.("Direksi belum melihat sebelum ditembuskan", AT.tembusan_for(dir).exclude?(t2))
  t2.tembusan!(e1)
  check.("tembusan Eselon 1 → Direksi melihat (untuk diketahui)", AT.tembusan_for(dir).include?(t2))

  k = Lpms3::Kickoff.find_by!(project: proyek)
  check.("admin Pengawasan Proyek melihat tugas tunjuk analis", Lpms3::Kickoff.pending_for(adm).include?(k))
  check.("staff TIDAK bisa menunjuk analis", (k.assign!(staff, analis) rescue nil).nil?)
  check.("analis harus berperan Project Analis", (k.assign!(adm, e2) rescue nil).nil?)
  k.assign!(adm, analis)
  check.("tunjuk analis → menunggu undangan", k.reload.state == "menunggu_undangan" && k.analis_id == analis.id)

  roster_ok = k.roster.values.all? { |r| r[:users].any? }
  if roster_ok
    k.undang!(analis, scheduled_at: 1.day.from_now, agenda: "Kick-Off uji")
    check.("undangan terkirim ke seluruh stakeholder + kategori BOP-001", k.reload.state == "terkirim" && k.invitees.any?)
  else
    begin
      k.undang!(analis, scheduled_at: 1.day.from_now)
      check.("gerbang roster BOP-001 (tanpa Pemimpin/Pemapar, undangan ditolak)", false, "undangan lolos padahal roster kosong")
    rescue Lpms3::Kickoff::Error => e
      check.("gerbang roster BOP-001 menolak undangan", true, e.message)
    end
  end

  # Pembaca Baca Saja: masukan → pembuat bisa edit (tanpa reviu) hanya saat masukan terbuka
  reader = u("direksi.pejabat01.dir@len.co.id")
  fb = Lpms3::Feedback.give!(wp, reader, "Typo uji")
  check.("pembaca Baca Saja bisa memberi masukan", fb.persisted? && fb.state == "terbuka")
  check.("masukan muncul di catatan aktivitas WP", wp.reload.journals.any? { |j| j.notes.to_s.include?("Typo uji") })
  begin
    fb.resolve!(User.find(wp.author_id), "diperbaiki")
    check.("pembuat menandai masukan selesai", fb.reload.state == "diperbaiki")
  rescue Lpms3::Feedback::Error => e
    check.("pembuat menandai masukan selesai", false, e.message)
  end

  raise ActiveRecord::Rollback
end

puts "RINGKASAN: #{results.count { |_, ok| ok }}/#{results.size} PASS (data uji di-rollback)"
