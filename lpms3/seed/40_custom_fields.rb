require_relative "00_data"
# Atribut proyek (§5.2): section => [[nama, format, wajib, opsi]]
PROJ = {
  "Identitas" => [
    ["Kode Proyek", "string", true], ["Nama Pelanggan", "string", true],
    ["Nomor Kontrak", "string", true], ["Tanggal Kontrak", "date", true],
    ["Nilai Kontrak (IDR)", "float", true],
    ["Jenis/Klasifikasi Proyek", "list", true, ["Sistem Pertahanan", "Transportasi", "Energi", "ICT", "Lainnya"]],
    ["Pendekatan Delivery", "list", true, %w[Prediktif Hibrid Adaptif]],
  ],
  "Organisasi" => [
    ["Project Sponsor", "user", true], ["Pimpro", "user", true],
    ["Fungsi Pelaksanaan Proyek (struktural)", "user", true],
    ["Fungsi Pengawasan Proyek (PIC)", "user", true],
  ],
  "Baseline" => [
    ["Tanggal Kick-Off (Baseline 0)", "date", false], ["Tanggal Selesai Kontrak", "date", true],
    ["Nomor Adendum Terakhir", "string", false],
  ],
  "Nilai & Keberlanjutan" => [
    ["Tujuan bisnis / manfaat yang diharapkan", "text", true],
    ["Pertimbangan keberlanjutan (ESG/K3L)", "text", true],
  ],
  "Penutupan" => [
    ["Jenis Penutupan", "list", false, ["Selesai 100%", "Terminasi"]],
    ["Purnajual dipersyaratkan", "bool", true], ["Nomor Laporan Akhir Proyek", "string", false],
  ],
}
LVL = %w[Rendah Sedang Tinggi Ekstrem]
ALL = Lpms3Data::TYPES.keys
# Field WP (§5.3, §5.5): [nama, format, tipe, opsi, multi]
WP = [
  ["Kode WBS", "string", %w[Deliverable Task]],
  ["Harga Pekerjaan (IDR)", "float", %w[Deliverable]], ["Bobot (%)", "float", %w[Deliverable]],
  ["Kriteria Penerimaan", "text", %w[Deliverable]], ["No. BA", "string", %w[Deliverable]],
  ["Jenis milestone", "list", %w[Milestone], %w[Kontraktual Internal Pembayaran]],
  ["Jenis rencana", "list", %w[Dokumen\ Rencana],
   ["Lingkup", "Jadwal", "Biaya", "Mutu", "Sumber Daya", "Komunikasi", "Risiko", "Pengadaan", "Stakeholder"]],
  ["Versi", "string", %w[Dokumen\ Rencana]], ["Tanggal Sah", "date", %w[Dokumen\ Rencana]],
  ["Kategori perubahan", "list", %w[Change\ Request],
   ["Ruang lingkup", "Jadwal", "Biaya", "Mutu", "Sumber daya", "Risiko", "Komunikasi", "Pengadaan", "Stakeholder", "Kontrak"], true],
  ["Asal permintaan", "list", %w[Change\ Request], ["Pimpro", "Fungsi Pengawasan", "Penjaminan Mutu", "Pelanggan", "Rekanan"]],
  ["Deskripsi & justifikasi", "text", %w[Change\ Request]],
  ["Dampak ruang lingkup", "text", %w[Change\ Request]], ["Dampak jadwal (hari)", "int", %w[Change\ Request]],
  ["Dampak biaya (IDR)", "float", %w[Change\ Request]], ["Dampak mutu", "text", %w[Change\ Request]],
  ["Dampak risiko", "text", %w[Change\ Request]], ["Dampak SDM", "text", %w[Change\ Request]],
  ["Dampak kontrak", "text", %w[Change\ Request]],
  ["Rekomendasi CCM", "list", %w[Change\ Request], %w[Setuju Tolak Tunda]],
  ["Pejabat berwenang", "user", %w[Change\ Request]], ["Tanggal keputusan", "date", %w[Change\ Request]],
  ["Perlu adendum kontrak", "bool", %w[Change\ Request]],
  ["Kategori risiko", "string", %w[Risiko]], ["Ancaman/Peluang", "list", %w[Risiko], %w[Ancaman Peluang]],
  ["Penyebab risiko", "text", %w[Risiko]], ["Dampak risiko (uraian)", "text", %w[Risiko]],
  ["Probabilitas (1-5)", "int", %w[Risiko]], ["Dampak (1-5)", "int", %w[Risiko]], ["Skor risiko (PxD)", "int", %w[Risiko]],
  ["Tingkat risiko", "list", %w[Risiko], LVL],
  ["Strategi respons", "list", %w[Risiko], %w[Hindari Transfer Mitigasi Terima Eksploitasi Tingkatkan Berbagi]],
  ["Rencana mitigasi", "text", %w[Risiko]], ["Pemilik Risiko", "user", %w[Risiko]],
  ["Tanggal review berikutnya", "date", %w[Risiko]],
  ["Aktivitas K3L", "string", %w[Bahaya\ K3L]], ["Bahaya/Aspek", "text", %w[Bahaya\ K3L]],
  ["Risiko/Dampak K3L", "text", %w[Bahaya\ K3L]], ["Risiko awal", "list", %w[Bahaya\ K3L], LVL],
  ["Hierarki pengendalian", "list", %w[Bahaya\ K3L], %w[Eliminasi Substitusi Rekayasa Administratif APD]],
  ["Risiko sisa", "list", %w[Bahaya\ K3L], LVL], ["Regulasi terkait", "text", %w[Bahaya\ K3L]],
  ["Sumber isu", "list", %w[Isu], %w[Pengadaan Teknis Pelanggan Lainnya]],
  ["Eskalasi ke manajemen", "bool", %w[Isu]],
  ["Asal rapat", "string", %w[Action\ Item]],
  ["Area (domain PMBOK 8)", "list", %w[Lesson\ Learned],
   ["Governance", "Scope", "Schedule", "Finance", "Stakeholders", "Resources", "Risk"]],
  ["Apa yang terjadi", "text", %w[Lesson\ Learned]], ["Akar masalah", "text", %w[Lesson\ Learned]],
  ["Rekomendasi", "text", %w[Lesson\ Learned]], ["Dapat dipakai ulang", "bool", %w[Lesson\ Learned]],
  ["Quality metric", "string", %w[Inspeksi\ Mutu]], ["Hasil ukur", "string", %w[Inspeksi\ Mutu]],
  ["Alat ukur", "string", %w[Inspeksi\ Mutu]],
  ["Severity NCR", "list", %w[NCR], %w[Minor Mayor Kritikal]], ["Tindakan korektif/preventif", "text", %w[NCR]],
  ["No. PR", "string", %w[Item\ Pengadaan]], ["No. PO", "string", %w[Item\ Pengadaan]],
  ["Rekanan", "string", %w[Item\ Pengadaan]], ["Nilai pengadaan (IDR)", "float", %w[Item\ Pengadaan]],
  ["Make-or-Buy", "list", %w[Item\ Pengadaan], %w[Make Buy]], ["Tanggal dibutuhkan", "date", %w[Item\ Pengadaan]],
  ["Organisasi stakeholder", "string", %w[Stakeholder]], ["Peran stakeholder", "string", %w[Stakeholder]],
  ["Pengaruh (1-5)", "int", %w[Stakeholder]], ["Kepentingan (1-5)", "int", %w[Stakeholder]],
  ["Keterlibatan saat ini", "list", %w[Stakeholder], %w[Unaware Resistant Neutral Supportive Leading]],
  ["Keterlibatan diinginkan", "list", %w[Stakeholder], %w[Unaware Resistant Neutral Supportive Leading]],
  ["Strategi keterlibatan", "text", %w[Stakeholder]],
  ["Mata anggaran", "string", %w[Top\ Up\ Anggaran]], ["Nilai Top Up (IDR)", "float", %w[Top\ Up\ Anggaran]],
  ["Justifikasi Top Up", "text", %w[Top\ Up\ Anggaran]],
  ["Kategori arsip", "string", %w[Dokumen\ Proyek]], ["Lokasi arsip", "string", %w[Dokumen\ Proyek]],
  ["Masa retensi", "string", %w[Dokumen\ Proyek]],
  # RASCI tambahan (§5.3): A, R, I sudah bawaan
  ["Supporting (S)", "user", ALL, nil, true], ["Consulted (C)", "user", ALL, nil, true],
]

def apply_opts(cf, fmt, opts, multi)
  cf.possible_values = opts if fmt == "list" && opts
  cf.multi_value = true if multi
end

sec_pos = 0
PROJ.each do |sec_name, fields|
  sec = ProjectCustomFieldSection.find_or_create_by!(name: sec_name) { |s| s.position = (sec_pos += 1) }
  fields.each do |name, fmt, req, opts|
    cf = ProjectCustomField.find_or_initialize_by(name: name)
    cf.field_format = fmt if cf.new_record?
    cf.project_custom_field_section = sec
    cf.is_required = req
    apply_opts(cf, fmt, opts, false) if cf.new_record?
    cf.save!
  end
end

WP.each do |name, fmt, types, opts, multi|
  cf = WorkPackageCustomField.find_or_initialize_by(name: name)
  cf.field_format = fmt if cf.new_record?
  cf.is_for_all = true
  apply_opts(cf, fmt, opts, multi) if cf.new_record?
  cf.type_variants = TypeVariant.where(is_default_variant: true, type_id: Type.where(name: types).select(:id))
  cf.save!
end
puts "custom fields ok: proyek #{ProjectCustomField.count}, WP #{WorkPackageCustomField.count}"
