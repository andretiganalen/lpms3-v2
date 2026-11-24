# frozen_string_literal: true

# Smoke 1.42: monitoring Kontrak awal (Lpms3::Kontrak). Seluruhnya di transaksi non-joinable yang di-rollback. Jalankan:
#   docker cp lpms3/smoke/kontrak.rb lpms3v2-web-1:/tmp/ && docker exec lpms3v2-web-1 bash -lc "cd /app && bin/rails runner /tmp/kontrak.rb"
RES = []
def chk(label, ok, note = nil)
  RES << ok
  puts format("%-4s %s%s", ok ? "PASS" : "FAIL", label, note ? " — #{note}" : "")
end
def raises(msg = nil)
  yield
  false
rescue Lpms3::Kontrak::Error => e
  msg.nil? || e.message.include?(msg)
end

K = Lpms3::Kontrak
W = Lpms3::Wbs
today = Date.current
ActiveRecord::Base.transaction(joinable: false) do
  pw = SecureRandom.hex(12) + "Aa1!"
  mk = ->(k) do
    User.create!(login: "uji142.#{k}", firstname: "Uji142", lastname: k, mail: "uji142.#{k}@example.com",
                 status: User.statuses[:active], password: pw, password_confirmation: pw)
  end
  pim, keu, es2, tim, luar = %w[pim keu es2 tim luar].map { |k| mk.(k) }
  proj = Project.create!(name: "Proyek Uji 1.42", identifier: "uji142-#{SecureRandom.hex(3)}", public: false, workspace_type: "project")
  ProjectType.find_or_create_by!(project: proj, type: Type.find_by!(name: "Task"))
  proj.enabled_module_names = proj.enabled_module_names | %w[work_package_tracking]
  { pim => "Pimpro", keu => "Fungsi Pengendali Anggaran/Keuangan/Akuntansi", es2 => "Pejabat Eselon 2", tim => "Tim Proyek" }.each do |u, r|
    Member.create!(project: proj, principal: u, roles: [ProjectRole.find_by!(name: r)])
  end
  User.current = pim
  { nomor: "KTR/UJI/142", tanggal: (today - 90).iso8601, nilai: "50000000000", selesai: (today + 40).iso8601 }.each { |k, v| K.set_cf!(proj, k, v) }

  chk "hak: Pimpro & Keuangan edit, Tim Proyek tidak, orang luar tidak lihat",
      K.can_edit?(pim, proj) && K.can_edit?(keu, proj) && !K.can_edit?(tim, proj) && !K.can_view?(luar, proj)
  s = K.summary(proj, today:)
  chk "kelas SOP-004: 50 M = Sedang", s[:kelas_awal] == "Sedang", s[:kelas_awal].inspect
  chk "temuan: Go/No-Go SFR-028 belum, Jaminan Pelaksanaan belum, kontrak ≤ 60 hari",
      %i[go_nogo jaminan_pelaksanaan kontrak_akan_berakhir].all? { |c| s[:findings].map(&:code).include?(c) }, s[:findings].map(&:code).inspect
  chk "Go dengan nomor kosong ditolak", raises("nomor tinjauan") { K.save_info!(proj, pim, { go_nogo: "GO" }) }
  chk "Tim Proyek tidak dapat menyimpan data kontrak", raises("berwenang") { K.save_info!(proj, tim, { go_nogo: "BELUM" }) }
  K.save_info!(proj, pim, { go_nogo: "GO", go_nogo_tanggal: (today - 100).iso8601, go_nogo_nomor: "01/SFR-028/UJI", posisi_len: "Kontraktor Utama" })
  chk "Go dicatat: temuan Go/No-Go hilang; nilai awal terekam", !K.summary(proj)[:findings].map(&:code).include?(:go_nogo) &&
                                                             K.info(proj).nilai_awal.to_i == 50_000_000_000

  # Jaminan
  chk "jaminan tanpa tanggal berakhir ditolak", raises("berlaku sampai") { K.save_jaminan!(proj, pim, { jenis: "PELAKSANAAN", nomor: "BG-1" }) }
  jp = K.save_jaminan!(proj, keu, { jenis: "PELAKSANAAN", nomor: "BG-001", penerbit: "Bank Uji", nilai: "2500000000", persen: "5",
                                    berlaku_dari: (today - 90).iso8601, berlaku_sampai: (today + 20).iso8601 })
  ju = K.save_jaminan!(proj, keu, { jenis: "UANG_MUKA", nomor: "BG-002", nilai: "5000000000", berlaku_sampai: (today - 1).iso8601 })
  codes = K.summary(proj)[:findings].map(&:code)
  chk "jaminan pelaksanaan 20 hari lagi → akan berakhir; uang muka lewat → kedaluwarsa",
      codes.include?(:jaminan_akan_berakhir) && codes.include?(:jaminan_kadaluarsa) && !codes.include?(:jaminan_pelaksanaan), codes.inspect
  tasks_keu = K.tasks_for(keu).map { _1[:finding].code }
  chk "Tugas Keuangan: peringatan jaminan; Tim Proyek tidak menerima", tasks_keu.include?(:jaminan_kadaluarsa) && K.tasks_for(tim).empty?, tasks_keu.inspect
  K.set_jaminan_status!(proj, keu, ju.id, "DIKEMBALIKAN")
  chk "jaminan dikembalikan: temuan kedaluwarsa hilang", !K.summary(proj)[:findings].map(&:code).include?(:jaminan_kadaluarsa)

  # Termin & WBS
  root = W.ensure_root!(proj)
  a = W.add_child!(proj, pim, parent_id: root.id)
  b = W.add_child!(proj, pim, parent_id: root.id)
  [a, b].each do |n|
    W.update_field!(proj, pim, n.id, "date_plan_start", (today - 60).iso8601)
    W.update_field!(proj, pim, n.id, "date_plan_finish", (today + 30).iso8601)
  end
  K.save_termin!(proj, pim, { uraian: "Uang muka 20 %", persen: "20", syarat: "UANG_MUKA" })
  t2 = K.save_termin!(proj, pim, { uraian: "Progres 50 %", persen: "30", syarat: "PROGRES", syarat_progres: "50" })
  t3 = K.save_termin!(proj, pim, { uraian: "Aktivitas 2 selesai", persen: "30", syarat: "AKTIVITAS", syarat_wbs_node_id: b.id })
  chk "termin melebihi 100 % ditolak", raises("maks. 100") { K.save_termin!(proj, pim, { uraian: "Lebih", persen: "25", syarat: "MANUAL" }) }
  K.save_termin!(proj, pim, { uraian: "BAST", persen: "20", syarat: "BAST" })
  s = K.summary(proj)
  chk "Σ termin 100 %, nilai termin 2 = 30 % × 50 M", s[:termin_total_pct] == 100.0 && s[:termin].find { _1[:t].id == t2.id }[:nilai].to_i == 15_000_000_000
  chk "uang muka tidak layak (jaminan dikembalikan), progres 0 % tidak layak", s[:termin].none? { _1[:layak] }
  chk "tagih sebelum syarat terpenuhi ditolak", raises("belum terpenuhi") { K.tagih!(proj, keu, t2.id, nomor: "INV-1") }
  chk "Tim Proyek tidak dapat mencatat penagihan", raises("Keuangan") { K.tagih!(proj, tim, t2.id, nomor: "INV-1") }
  # progres 50 % (aktivitas A selesai = 50 % bobot) dengan bukti
  wpa = a.reload.work_package
  path = Rails.root.join("tmp", "uji142-#{SecureRandom.hex(3)}.txt").to_s
  File.write(path, "bukti")
  att = Attachment.new(container: wpa, author: pim, description: "")
  att.file = ActionDispatch::Http::UploadedFile.new(tempfile: File.open(path), filename: "b.txt", type: "text/plain")
  att.save!
  %w[25 50 75 100].each { |v| W.update_field!(proj, pim, a.id, "pct_complete", v) }
  s = K.summary(proj)
  r2 = s[:termin].find { _1[:t].id == t2.id }
  chk "progres 50 %: termin 2 layak tagih + temuan + tugas Pimpro", r2[:layak] && s[:findings].any? { _1.code == :termin_layak_tagih } &&
                                                                    K.tasks_for(pim).any? { _1[:finding].code == :termin_layak_tagih }, r2[:alasan]
  chk "termin aktivitas 2 belum layak", !s[:termin].find { _1[:t].id == t3.id }[:layak]
  K.tagih!(proj, keu, t2.id, nomor: "INV-142-02", tanggal: (today - 40).iso8601)
  chk "termin ditagih > 30 hari belum dibayar → temuan tinggi", K.summary(proj)[:findings].any? { _1.code == :termin_tertunda_bayar && _1.severity == :high }
  chk "termin ditagih tidak dapat diubah", raises("sudah ditagih") { K.save_termin!(proj, pim, { uraian: "x", persen: "30", syarat: "MANUAL" }, id: t2.id) }
  K.bayar!(proj, keu, t2.id)
  s = K.summary(proj)
  chk "dibayar: nilai bayar default = nilai termin, terbayar 15 M", s[:terbayar].to_i == 15_000_000_000 && !s[:findings].any? { _1.code == :termin_tertunda_bayar }

  # Adendum
  chk "adendum tanpa perubahan ditolak", raises("harus mengubah") { K.save_adendum!(proj, pim, { nomor_dokumen: "ADD-1", tanggal: today.iso8601, uraian: "x" }) }
  ad = K.save_adendum!(proj, pim, { nomor_dokumen: "ADD-01/UJI", tanggal: today.iso8601, uraian: "Tambah bay & waktu 90 hari",
                                    nilai_baru: "120000000000", tanggal_selesai_baru: (today + 130).iso8601, sfr025_nomor: "01/SFR-025" })
  chk "draft adendum: tugas pengesah untuk Pejabat Eselon 2", K.tasks_for(es2).any? { _1[:finding].code == :adendum_draft }
  chk "Pimpro tidak dapat mengesahkan", raises("Eselon 2/1") { K.sahkan_adendum!(proj, pim, ad.id) }
  K.sahkan_adendum!(proj, es2, ad.id)
  s = K.summary(proj)
  chk "disahkan: atribut proyek Nilai/Selesai/Nomor Adendum diperbarui", s[:nilai_efektif].to_i == 120_000_000_000 && s[:selesai] == today + 130 &&
                                                                       K.cf(proj, :adendum) == "ADD-01/UJI"
  chk "nilai & selesai awal tetap terekam", s[:nilai_awal].to_i == 50_000_000_000 && s[:selesai_awal] == today + 40
  chk "kelas berubah Sedang → Besar ditandai (SOP-009)", s[:kelas_efektif] == "Besar" && s[:findings].any? { _1.code == :kelas_berubah }
  chk "kontrak tidak lagi ≤ 60 hari", s[:findings].none? { _1.code == :kontrak_akan_berakhir }
  chk "adendum disahkan tidak dapat dihapus", raises("disahkan") { K.destroy_draft!(proj, pim, "adendum", ad.id) }

  row = Lpms3::Portfolio.row(proj, today, today - 30)
  chk "kartu Portofolio memuat ringkasan kontrak", row[:kontrak] && row[:kontrak][:kelas] == "Besar" && row[:kontrak][:terbayar_pct] == 12.5 &&
                                                   row[:kontrak][:adendum] == 1, row[:kontrak].inspect
  chk "monitoring lintas proyek memuat proyek uji untuk Pimpro, tidak untuk orang luar",
      K.rows(pim).any? { _1[:project].id == proj.id } && K.rows(luar).none? { _1[:project].id == proj.id }

  FileUtils.rm_f(path)
  FileUtils.rm_f(att.diskfile.to_s)
  puts "\nRINGKASAN: PASS=#{RES.count(true)} FAIL=#{RES.count(false)}"
  raise ActiveRecord::Rollback
end
