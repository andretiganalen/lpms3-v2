# Dijalankan lewat: rails runner - < (gabungan PROYEK = JSON dari ex.py + berkas ini). Alur: pemicu LenO -> usulkan! -> putuskan! -> job buat proyek.
PT = Lpms3::ProjectTrigger
reg = User.find_by!(mail: "indah.prastiwi@len.co.id"); appr = User.find_by!(mail: "alfian.mahendra@len.co.id")
fallback_pimpro = User.find_by!(mail: "andre.tigana@len.co.id")
PROYEK.each do |o|
  tr = PT.find_by!(kode_proyek: o["asal"].upcase)
  pim = (o["pimpro"] && User.find_by(mail: o["pimpro"])) || fallback_pimpro
  vp = (o["vp"] && User.find_by(mail: o["vp"])) || appr
  note = "Ditarik dari :5000 (kode asal #{o['asal']}#{o['dikoreksi'] ? ", dikoreksi ke format XXX-XXXXXXXX" : ''}); status asal #{o['status']}."
  begin
    tr.usulkan!(reg, template: "lpms3-predik", nama_proyek: o["nama"], kode_proyek_lpms3: o["kode"], pimpro_id: pim.id, vp_id: vp.id, catatan: note)
    tr.putuskan!(appr, "setujui", "Penarikan data dari :5000")
    puts "disetujui #{o['kode']} (#{pim.mail} / #{vp.mail})"
  rescue => e
    puts "GAGAL #{o['asal']}: #{e.message}"
  end
end
