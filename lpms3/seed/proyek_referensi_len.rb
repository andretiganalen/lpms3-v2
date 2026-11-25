# Nama dan keterangan dummy project berdasarkan riwayat proyek PT Len Industri (Persero) dari www.len.co.id
# (Teknologi & Bisnis > Sistem Transportasi, ICT dan Sistem Navigasi, Energi Terbarukan; Sejarah).
# Data pekerjaan tetap dummy; identifier dummy-project-N dipertahankan untuk seed akun uji. Idempoten.
REF = [
  ["revitalisasi", "Revitalisasi Sistem Persinyalan KRL Jatinegara – Bogor", "2021–2023",
   "Persinyalan kereta mainline (Sistem Transportasi, len.co.id)."],
  ["revitalisas-2", "Revitalisasi Sistem Persinyalan KRL Manggarai – Jakarta Kota", "2021–2023",
   "Persinyalan kereta mainline (Sistem Transportasi, len.co.id)."],
  ["double-track", "Double Track Lintas Utara Jawa Cirebon – Surabaya", "2009–2017",
   "Jalur ganda 435 km, persinyalan dan telekomunikasi serat optik (Sejarah, len.co.id)."],
  ["jalur-selata", "Jalur Selatan Kroya – Kutoarjo", "2016–2018",
   "Persinyalan dan telekomunikasi kereta (Sistem Transportasi, len.co.id)."],
  ["palapa-ring", "Palapa Ring Paket Tengah", "Infrastruktur telekomunikasi",
   "Pembangunan dan pemeliharaan jaringan serat optik di 17 kabupaten/kota Indonesia Bagian Tengah (ICT dan Sistem Navigasi, len.co.id)."],
  ["plts-ipp-kup", "PLTS IPP Kupang 5 MWp", "2014–2015",
   "IPP PLTS pertama 5 MWp di Kupang, NTT; diresmikan 27 November 2015 (Sejarah, len.co.id)."],
]
pjs = REF.map do |ident, name, periode, ket|
  pj = Project.find_by!(identifier: ident)
  pj.name = name
  pj.description = "#{ket} Periode: #{periode}. Data pekerjaan uji (dummy) berdasarkan referensi publik PT Len Industri (Persero)."
  pj.save!
  pj
end
demo = Project.find_by(identifier: "leno-mobile")
if demo
  demo.name = "Revitalisasi Sistem Persinyalan KRL Jatinegara – Bogor"
  demo.description = "Demo LenO Mobile: pekerjaan lapangan WO persinyalan (panel kontrol, tray kabel, terminasi). Data dummy."
  demo.save!
end
puts "referensi: #{pjs.map(&:name).join(' | ')}"
