# frozen_string_literal: true

# 1.39 Member proyek berjenjang (idempoten):
#  - Peran proyek "Admin Direksi" dan "Admin Pejabat Eselon 1" (izin = "Tim Proyek"; admin bekerja atas nama pejabat,
#    tidak memutus persetujuan karena rantai persetujuan memeriksa peran pejabat).
#  - Jabatan Kepala/Admin per unit Direksi/ES1/ES2 dan Staf per unit ES1/ES2 di struktur aktif (lpms3.position).
# Pemegang jabatan diisi lewat Administrasi -> Jabatan Pengguna (manual atau impor CSV), bukan di seed.
tim = ProjectRole.find_by!(name: "Tim Proyek")
["Admin Direksi", "Admin Pejabat Eselon 1", "Pejabat Eselon 1", "Pejabat Eselon 2", "Direksi"].each do |nama|
  r = ProjectRole.find_or_initialize_by(name: nama)
  next unless r.new_record?

  r.permissions = tim.permissions
  r.save!
  puts "[peran] dibuat: #{nama}"
end

st = Lpms3::OrgStructure.active.first
if st
  n = 0
  st.units.where(grade: %w[DIREKSI ES1 ES2]).find_each do |unit|
    kinds = %w[KEPALA ADMIN]
    kinds << "STAF" unless unit.grade == "DIREKSI"
    kinds.each do |k|
      before = Lpms3::Position.count
      Lpms3::Position.ensure_for!(unit, k)
      n += Lpms3::Position.count - before
    end
  end
  puts "[jabatan] posisi baru: #{n}, total: #{Lpms3::Position.count}"
else
  puts "[lewati] belum ada struktur organisasi aktif"
end
