# frozen_string_literal: true

# Peran proyek untuk alur persetujuan berjenjang dan Kick-Off (idempoten).
# Role yang belum ada dibuat dengan izin yang sama seperti "Tim Proyek". Akun uji hanya didaftarkan ke proyek uji
# "Proyek Kristian" agar tidak mengubah keanggotaan proyek lain.
ROLE_NAMES = ["Pejabat Eselon 1", "Pejabat Eselon 2", "Direksi", "Project Analis"].freeze
tim = ProjectRole.find_by!(name: "Tim Proyek")
ROLE_NAMES.each do |nama|
  r = ProjectRole.find_or_initialize_by(name: nama)
  next unless r.new_record?

  r.permissions = tim.permissions
  r.save!
  puts "[peran] dibuat: #{nama}"
end

PENUGASAN = {
  "pejabat.eselon1.uji@len.co.id" => "Pejabat Eselon 1",
  "pejabat.eselon2.uji@len.co.id" => "Pejabat Eselon 2",
  "pejabat.direksi1.uji@len.co.id" => "Direksi",
  "spesialis.eselon2.uji@len.co.id" => "Project Analis",
  "admin.eselon2.uji@len.co.id" => "Fungsi Pengawasan Proyek"
}.freeze

proyek = Project.find_by(name: "Proyek Kristian")
if proyek
  PENUGASAN.each do |login, role_name|
    user = User.find_by(login:)
    next puts("[lewati] akun tidak ada: #{login}") unless user

    role = ProjectRole.find_by!(name: role_name)
    member = Member.find_or_initialize_by(project: proyek, principal: user)
    member.roles |= [role]
    member.save!
    puts "[penugasan] #{login} -> #{role_name} di #{proyek.name}"
  end
else
  puts "[lewati] proyek uji 'Proyek Kristian' tidak ditemukan"
end
