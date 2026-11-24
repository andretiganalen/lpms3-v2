# frozen_string_literal: true

# Smoke 1.39: jabatan pengguna -> member proyek berjenjang (tim default + atasan Eselon 2 Pimpro).
# Seluruhnya di transaksi non-joinable yang di-rollback: callback after_commit tetap berjalan (savepoint), data tidak
# tertinggal. Jalankan:
#   docker cp lpms3/smoke/tim_proyek.rb lpms3v2-web-1:/tmp/ && \
#   docker exec lpms3v2-web-1 bash -lc "cd /app && bin/rails runner /tmp/tim_proyek.rb"
RES = []
def chk(label, ok, note = nil)
  RES << ok
  puts format("%-4s %s%s", ok ? "PASS" : "FAIL", label, note ? " — #{note}" : "")
end
def roles_in(project, user) = Member.find_by(project:, principal: user)&.roles&.map(&:name).to_a

H = Lpms3::Hierarki
T = Lpms3::TimProyek

ActiveRecord::Base.transaction(joinable: false) do
  pw = SecureRandom.hex(12) + "Aa1!"
  mk = ->(k) do
    User.create!(login: "uji139.#{k}", firstname: "Uji139", lastname: k, mail: "uji139.#{k}@example.com",
                 status: User.statuses[:active], password: pw, password_confirmation: pw)
  end
  dirh, dira, es1h, es1a, es2h, es2plt, pim, pim2, luar = %w[dirh dira es1h es1a es2h es2plt pim pim2 luar].map { |k| mk.(k) }

  es1 = H.unit_eselon1_of_fungsi
  dir = H.unit_direksi_of_fungsi
  es2 = Lpms3::FungsiUnitMap.includes(:unit).find_by(fungsi_id: Lpms3::FungsiGenerik.find_by!(code: "F-MPR").id, is_primary: true)&.unit
  chk "resolver: ES1 Fungsi Pelaksanaan Proyek = Divisi Project Deployment Center", es1&.grade == "ES1" && es1.code == "DIR-3.1", es1&.name
  chk "resolver: Direksi di atasnya = Direktorat Operasi", dir&.code == "DIR-3", dir&.name
  chk "unit ES2 F-MPR ada dan berinduk ke ES1 itu", es2&.grade == "ES2" && es2.parent_id == es1&.id, es2&.name

  put = ->(user, unit, kind, type = "DEFINITIF", from = Date.current - 30, to = nil) do
    Lpms3::UserPosition.create!(position: Lpms3::Position.ensure_for!(unit, kind), user:, assignment_type: type,
                                valid_from: from, valid_to: to, updated_at: Time.current)
  end
  # Bersihkan pemegang nyata selama uji (rollback memulihkan).
  Lpms3::UserPosition.where(position_id: Lpms3::Position.where(unit_id: [dir.id, es1.id, es2.id]).select(:id)).delete_all
  put.(dirh, dir, "KEPALA"); put.(dira, dir, "ADMIN"); put.(es1h, es1, "KEPALA"); put.(es1a, es1, "ADMIN")
  put.(es2h, es2, "KEPALA"); put.(pim, es2, "STAF")
  put.(luar, es2, "KEPALA", "DEFINITIF", Date.current - 90, Date.current - 31) # sudah berakhir

  chk "holders: Kepala aktif saja (yang berakhir tidak dihitung)", H.holders(es2, "KEPALA") == [es2h]
  chk "unit_eselon2_of(Pimpro staf ES2) = unit ES2", H.unit_eselon2_of(pim) == es2
  chk "atasan_eselon2_of(Pimpro) = Kepala ES2", H.atasan_eselon2_of(pim) == [es2h]
  chk "pengguna tanpa jabatan: tidak punya unit ES2", H.unit_eselon2_of(pim2).nil?

  proj = Project.create!(name: "Proyek Uji 1.39", identifier: "uji139-#{SecureRandom.hex(3)}", public: false, workspace_type: "project")
  r = T.sync!(proj)
  chk "tim default: Direktur = peran Direksi", roles_in(proj, dirh).include?("Direksi")
  chk "tim default: Admin Direktur = Admin Direksi", roles_in(proj, dira).include?("Admin Direksi")
  chk "tim default: Pejabat Eselon 1 F-MPR", roles_in(proj, es1h).include?("Pejabat Eselon 1")
  chk "tim default: Admin Pejabat Eselon 1", roles_in(proj, es1a).include?("Admin Pejabat Eselon 1")
  chk "belum ada Pimpro: Eselon 2 belum ditambahkan", roles_in(proj, es2h).empty?
  # 4 tim default F-MPR/Direksi + pemegang jabatan Fungsi Pengawasan Proyek (Eselon 1, Admin, Eselon 2 unit primer; 1.42).
  pwp1 = Lpms3::Hierarki.unit_eselon1_of_fungsi("F-PWP")
  pwp2 = Lpms3::Hierarki.unit_primer_of_fungsi("F-PWP")
  n_pwp = [[pwp1, "KEPALA"], [pwp1, "ADMIN"], [pwp2, "KEPALA"]].sum { |un, k| un ? Lpms3::Hierarki.holders(un, k).size : 0 }
  chk "jejak lpms3_auto_members tercatat (4 + #{n_pwp} Fungsi Pengawasan)", Lpms3::AutoMember.where(project: proj).count == 4 + n_pwp, r.added.size.to_s
  chk "sinkron kedua idempoten (tidak menambah)", T.sync!(proj).added.empty? && Lpms3::AutoMember.where(project: proj).count == 4 + n_pwp

  # Hook: Pimpro ditetapkan lewat peran member (after_commit MemberRole).
  ActiveRecord::Base.transaction { Member.create!(project: proj, principal: pim, roles: [ProjectRole.find_by!(name: "Pimpro")]) }
  chk "hook peran Pimpro: Pejabat Eselon 2 atasannya otomatis member", roles_in(proj, es2h).include?("Pejabat Eselon 2")
  chk "orang luar tidak ditambahkan", roles_in(proj, luar).empty?

  # Hook: atribut proyek Pimpro (after_commit CustomValue) di proyek kedua, Pimpro dengan atasan Plt.
  Lpms3::UserPosition.where(user: es2h).update_all(valid_to: Date.current - 1)
  put.(es2plt, es2, "KEPALA", "PLT")
  proj2 = Project.create!(name: "Proyek Uji 1.39 B", identifier: "uji139b-#{SecureRandom.hex(3)}", public: false, workspace_type: "project")
  cf = ProjectCustomField.find_by!(name: "Pimpro")
  ProjectCustomFieldProjectMapping.find_or_create_by!(project_id: proj2.id, custom_field_id: cf.id)
  Member.create!(project: proj2, principal: pim, roles: [ProjectRole.find_by!(name: "Tim Proyek")])
  ActiveRecord::Base.transaction { CustomValue.create!(customized: proj2, custom_field: cf, value: pim.id.to_s) }
  chk "hook atribut Pimpro: Plt Kepala ES2 jadi Pejabat Eselon 2", roles_in(proj2, es2plt).include?("Pejabat Eselon 2")
  chk "hook atribut Pimpro: tim default ikut ditambahkan", roles_in(proj2, dirh).include?("Direksi") && roles_in(proj2, es1h).include?("Pejabat Eselon 1")
  chk "Kepala yang masa jabatannya berakhir tidak ditambahkan", roles_in(proj2, es2h).empty?

  # Pimpro tanpa jabatan: peringatan, tanpa galat.
  proj3 = Project.create!(name: "Proyek Uji 1.39 C", identifier: "uji139c-#{SecureRandom.hex(3)}", public: false, workspace_type: "project")
  Member.create!(project: proj3, principal: pim2, roles: [ProjectRole.find_by!(name: "Pimpro")])
  r3 = T.sync!(proj3)
  chk "Pimpro tanpa jabatan: peringatan, tidak galat", r3.warnings.any? { |w| w.include?("belum diketahui") }

  # Member lain tidak pernah dihapus: peran manual dipertahankan.
  m = Member.find_by!(project: proj, principal: es1h)
  m.roles = m.roles.to_a + [ProjectRole.find_by!(name: "Tim Proyek")]
  m.save!
  T.sync!(proj)
  chk "peran manual dipertahankan setelah sinkron", (roles_in(proj, es1h) & ["Tim Proyek", "Pejabat Eselon 1"]).size == 2

  # Template proyek tidak disentuh.
  tpl = Project.templated.first
  chk "proyek template dilewati", tpl.nil? || T.sync!(tpl).added.empty?

  puts "\nRINGKASAN: PASS=#{RES.count(true)} FAIL=#{RES.count(false)}"
  raise ActiveRecord::Rollback
end
