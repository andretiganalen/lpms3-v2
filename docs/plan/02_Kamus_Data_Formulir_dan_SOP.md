# Kamus Data Formulir & Prosedur BOP-001 → LPMS3

> Dokumen ini **dibangkitkan otomatis** dari `docs/data-dictionary/spec_forms.py` (sumber: template di `docs/template-bop001`).
> Setiap tabel dan kolom pada formulir dipetakan ke tabel database `lpms3_form.*` beserta tipe, pilihan (dropdown asli formulir), dan kewajiban isi.

Kolom standar setiap tabel baris: `id`, `form_instance_id`, `line_no`. Tabel header: `form_instance_id` sebagai kunci.

Kolom standar setiap dokumen (tabel `lpms3_form.form_instance`): proyek, node WBS (folder bukti), nomor dokumen, periode, revisi, status, level publikasi, unit & struktur organisasi saat dibuat, sumber data, PDF hasil render, audit.

## Ringkasan

| Kode | Rev | Formulir | Fase | Menu LPMS3 | Tabel | Kolom |
|---|---|---|---|---|---|---|
| FFR-706 | 11 | Pengajuan Kode Kegiatan | Inisiasi | PHASE › [Inisiasi] › ringkasan (Kode Proyek) | 1 | 18 |
| FLP-01 | 15 | Checklist Persyaratan Dokumen Pengajuan Pembukaan Kode Proyek/Program/Transfer Load | Inisiasi | PHASE › [Inisiasi] › ringkasan › Checklist FLP-01 | 2 | 9 |
| BOT-001 | 00 | Template Project Charter | Inisiasi | PHASE › [Inisiasi] › Project Charter (Gate G1) | 6 | 31 |
| SFR-028 | 00 | Rapat Tinjauan Order/Kontrak – Go/No Go | Pra-proyek → Inisiasi | PROJECT › Add New (lampiran dari LPMS 2 / pra-proyek) & PHASE › [Inisiasi] ringkasan | 1 | 18 |
| RFR-004 | 02 | Profil Proyek | Pra-proyek → Inisiasi | PHASE › [Inisiasi] › Preliminary PM Aspect (Risiko) & Risk Status | 1 | 58 |
| RFR-005 | 00 | Profil Risiko Program | Inisiasi (program) | PHASE › [Inisiasi] (jenis kode Program) | 1 | 25 |
| RFR-002 | 03 | Project Risk Register | Inisiasi → Closing (update bulanan) | PHASE › [Monitoring] › Risk Status | 2 | 33 |
| RFR-001 | 05 | Risk Register Unit Kerja (kertas kerja) | Eksekusi & Monitoring (risiko operasional) | PHASE › [Monitoring] › Risk Status (tab Risiko Operasional) | 2 | 34 |
| VFR-015 | 05 | Identifikasi dan Penilaian Bahaya-Risiko K3 dan Aspek-Dampak Lingkungan (HIRA) | Perencanaan → Eksekusi (review saat perubahan) | PHASE › [Monitoring] › K3LH Status | 2 | 30 |
| CFR-022 | 01 | Risalah Rapat | Semua fase (Kick-Off, Rapat Tinjauan, Top-Up, Pergeseran, ABT, Adendum) | PHASE › [Perencanaan] Reviu PMP & Kick-Off / [Eksekusi] ringkasan Rapat | 4 | 21 |
| BFR-001 | 00 | Formulir Change Log / Change Request | Eksekusi & Monitoring (Integrated Change Control) | PHASE › [Eksekusi] › Change Request (BFR-001) | 1 | 19 |
| FFR-708 | 09 | Laporan Kemajuan Proyek/Program/Transfer Load (LKP) | Eksekusi & Monitoring (bulanan); Closing (LKP 100%) | PHASE › [Monitoring] › Laporan Kemajuan (LKP / FFR-708) | 5 | 56 |
| CFR-027 | 00 | Ketidaksesuaian dan Tindakan Koreksi (Keluhan Pelanggan / Ketidaksesuaian SKU / Operasional) | Eksekusi & Monitoring | PHASE › [Monitoring] › Quality Status / Issue Status | 1 | 20 |
| PFR-037 | 00 | Pengajuan Proposal Pengadaan Barang/Jasa PMN | Perencanaan → Eksekusi (pengadaan PMN) | PHASE › [Monitoring] › Procurement Pipeline › Pra Procurement up to PR (jenis PMN) | 2 | 8 |
| FFR-710 | 02 | Laporan Dokumentasi Proyek (Daftar Isi Kelengkapan Dokumen + Tabel Realisasi) | Seluruh fase; wajib lengkap saat Closing | Dokumen proyek (folder WBS) & PHASE › [Closing] › Pendokumentasian Arsip | 8 | 81 |
| WFR-014 | 03 | Berita Acara Serah Terima Pekerjaan / Pemeliharaan (BAST) | Eksekusi (serah terima deliverable) & Closing | PHASE › [Eksekusi] ringkasan (Deliverable diterima) & [Closing] | 1 | 18 |
| WFR-010 | 03 | Bukti Pengembalian Bahan Sisa Proyek/Sisa Produksi | Closing | PHASE › [Closing] langkah Arsip & Persediaan | 2 | 19 |
| WFR-028 | 02 | Berita Acara Pemeriksaan Fisik Persediaan (Stock Opname) | Eksekusi (bulanan) & Closing | PHASE › [Monitoring] (laporan persediaan bulanan) & [Closing] | 1 | 11 |
| **WBS-LPMS** | – | WBS Template LPMS (tabel 'WBS' & 'Settings') | Perencanaan → Closing | PHASE › [Perencanaan] › WBS Generation | 1 | 15 |

**Total:** 18 formulir, 43 tabel, 509 kolom formulir + 15 kolom WBS.

## FFR-706 rev.11 — Pengajuan Kode Kegiatan

- **Sumber template:** `form/FFR-706 Formulir Pengajuan Kode Kegiatan rev.11.xlsx`
- **Fase:** Inisiasi  ·  **Prosedur:** FOP-700, BOP-001 §5.1.1
- **Pemilik/pengisi:** Fungsi Manajemen Proyek (Eselon I pemilik kode)
- **Menu LPMS3:** PHASE › [Inisiasi] › ringkasan (Kode Proyek)
- **Pengesahan (tabel `form_signature`):** Diajukan oleh: Eselon I pemilik kode (nama, NIK, tanggal)

### Tabel `lpms3_form.ffr706_pengajuan_kode` (header)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `nama_kegiatan` | Nama Proyek / Program / Transfer Load | teks |  | Ya |
| 2 | `kode_unit_kerja` | Kode Unit Kerja | Bagian | unit organisasi |  | Ya |
| 3 | `jenis_kegiatan` | Kegiatan (Proyek/Program/Transfer Load) | pilihan | Proyek Bisnis, Proyek Litbang, Proyek Investasi, Prospek Proyek, Purnajual Proyek, Program Persediaan Produk, Program Produksi, Program Internal Litbang, Program Eksternal Litbang, Program Rekayasa Produksi, Program Kajian Bisnis, Program Investasi, Transfer Load Produksi dan Persediaan Produk, Transfer Load Litbang dan POC | Ya |
| 4 | `lini_bisnis` | Lini Bisnis | pilihan | Defense (D), Commercial (C), Others (O) | Ya |
| 5 | `lini_bisnis_lainnya` | Lini Bisnis – Others (uraian) | teks |  | – |
| 6 | `metode_revenue` | Metode Revenue | pilihan | By Accrue, By Billing, Transfer Load | Ya |
| 7 | `kode_wbs_induk` | Kode WBS Induk (petunjuk no.6) | teks | kode proyek induk bila ada | – |
| 8 | `customer` | Customer** | teks | khusus proyek | – |
| 9 | `nilai_kontrak_netto` | Nilai Kontrak/Anggaran (netto) | uang (Rp) |  | Ya |
| 10 | `sumber_dana` | Sumber Dana | teks | pilih salah satu | – |
| 11 | `nomor_kontrak` | Nomor Kontrak** | teks | khusus proyek | – |
| 12 | `tanggal_kontrak` | Tanggal Kontrak** | tanggal |  | – |
| 13 | `jadwal_awal` | Jadwal Kontrak/Program – Awal | tanggal |  | Ya |
| 14 | `jadwal_akhir` | Jadwal Kontrak/Program – Akhir | tanggal |  | Ya |
| 15 | `account_manager` | Account Manager | NIK | pengguna |  | – |
| 16 | `pimpinan_proyek` | Pimpinan Proyek/Program/Transfer Load | NIK | pengguna |  | Ya |
| 17 | `target_rkap` | Ditargetkan dalam RKAP | pilihan | Ya, Tidak | Ya |
| 18 | `tempat_tanggal` | Bandung, (tanggal) | tanggal |  | Ya |

## FLP-01 rev.15 — Checklist Persyaratan Dokumen Pengajuan Pembukaan Kode Proyek/Program/Transfer Load

- **Sumber template:** `form/FLP-01 Lampiran Persyaratan Dokumen ... rev.15.xlsx`
- **Fase:** Inisiasi  ·  **Prosedur:** FOP-700
- **Pemilik/pengisi:** Fungsi Pengendali Anggaran (verifikasi) / Fungsi Manajemen Proyek (pengaju)
- **Menu LPMS3:** PHASE › [Inisiasi] › ringkasan › Checklist FLP-01

### Tabel `lpms3_form.flp01_master_persyaratan` (master)

_42 baris dokumen persyaratan × 14 jenis kode (matriks wajib/tidak). Dimuat sebagai data referensi, bukan diketik ulang per proyek._

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `no` | No | bilangan bulat |  | Ya |
| 2 | `dokumen_persyaratan` | Dokumen Persyaratan | teks | mis. FFR-706, SFR-003, SFR-006, RFR-002, RFR-004, FFR-714, FFR-721, Quality Plan, HSE Plan, Kurva S, ... | Ya |
| 3 | `kode_formulir` | Kode formulir terkait | teks |  | – |
| 4 | `berlaku_untuk` | Kolom checklist per jenis kode (14 kolom) | daftar/terstruktur | Proyek Bisnis, Proyek Litbang, Proyek Investasi, Prospek Proyek, Purnajual Proyek, Program Persediaan Produk, Program Produksi, Program Internal Litbang, Program Eksternal Litbang, Program Rekayasa Produksi, Program Kajian Bisnis, Program Investasi, Transfer Load Produksi dan Persediaan Produk, Transfer Load Litbang dan POC | Ya |

### Tabel `lpms3_form.flp01_checklist` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `persyaratan_no` | No dokumen persyaratan | bilangan bulat | FK flp01_master_persyaratan | Ya |
| 2 | `jenis_kode` | Jenis kode yang diajukan | pilihan | Proyek Bisnis, Proyek Litbang, Proyek Investasi, Prospek Proyek, Purnajual Proyek, Program Persediaan Produk, Program Produksi, Program Internal Litbang, Program Eksternal Litbang, Program Rekayasa Produksi, Program Kajian Bisnis, Program Investasi, Transfer Load Produksi dan Persediaan Produk, Transfer Load Litbang dan POC | Ya |
| 3 | `checklist` | Checklist (ü) | ya/tidak |  | Ya |
| 4 | `dokumen_ref` | Dokumen/berkas bukti | berkas |  | – |
| 5 | `catatan_verifikator` | Catatan verifikasi Fungsi Pengendali Anggaran | teks panjang |  | – |

## BOT-001 rev.00 — Template Project Charter

- **Sumber template:** `form/BOT-001 Template Project Charter rev.00 (sign).pdf`
- **Fase:** Inisiasi  ·  **Prosedur:** BOP-001 §5.1.3
- **Pemilik/pengisi:** Fungsi Manajemen Proyek (Pelaksanaan Proyek)
- **Menu LPMS3:** PHASE › [Inisiasi] › Project Charter (Gate G1)
- **Pengesahan (tabel `form_signature`):** Sponsor / Pemberi Otorisasi; Project Manager (Pimpro)

### Tabel `lpms3_form.bot001_charter` (header)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `nama_proyek` | Nama Proyek | teks |  | Ya |
| 2 | `nomor_kode_proyek` | Nomor / Kode Proyek | teks |  | Ya |
| 3 | `sponsor` | Sponsor / Pemberi Otorisasi (Nama & Jabatan) | pengguna |  | Ya |
| 4 | `project_manager` | Project Manager Ditugaskan | pengguna |  | Ya |
| 5 | `tanggal_penerbitan` | Tanggal Penerbitan | tanggal |  | Ya |
| 6 | `versi_dokumen` | Versi Dokumen | teks | Rev. 0, 1, ... | Ya |
| 7 | `purpose_justification` | 1. Purpose / Justification | teks panjang | 2–4 kalimat | Ya |
| 8 | `high_level_requirements` | 3. High-Level Requirements | daftar/terstruktur | daftar butir | Ya |
| 9 | `in_scope` | 4. Scope Boundaries – In-Scope | daftar/terstruktur | daftar butir | Ya |
| 10 | `out_of_scope` | 4. Scope Boundaries – Out-of-Scope | daftar/terstruktur | daftar butir | Ya |
| 11 | `total_estimasi_anggaran` | 7. Summary Budget – Total Estimasi Anggaran | uang (Rp) |  | Ya |
| 12 | `mata_uang` | Mata uang (Rp/USD ...) | pilihan | IDR, USD, EUR, Lainnya | Ya |
| 13 | `sumber_pendanaan` | 7. Sumber Pendanaan | teks | Internal / Loan / Grant / dll. | Ya |
| 14 | `approval_requirements` | 9. Approval Requirements | teks panjang |  | Ya |
| 15 | `pm_nik` | 10. Nomor Induk Karyawan PM | teks |  | Ya |
| 16 | `pm_otoritas_anggaran` | 10. Tingkat Otoritas Anggaran | teks | mis. persetujuan hingga Rp ... | Ya |
| 17 | `pm_otoritas_penugasan_sd` | 10. Otoritas Penugasan Sumber Daya | teks panjang |  | Ya |
| 18 | `pm_otoritas_keputusan_teknis` | 10. Otoritas Pengambilan Keputusan Teknis | teks panjang |  | Ya |
| 19 | `authorization_text` | 11. Authorization (pernyataan otorisasi) | teks panjang |  | Ya |

### Tabel `lpms3_form.bot001_success_criteria` (lines)

_baris tetap: Scope, Waktu, Biaya, Kualitas_

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `aspek` | Aspek | pilihan | Scope, Waktu (Schedule), Biaya (Budget), Kualitas | Ya |
| 2 | `target` | Target | teks |  | Ya |
| 3 | `kriteria_sukses` | Kriteria Sukses | teks |  | Ya |

### Tabel `lpms3_form.bot001_high_level_risks` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `deskripsi_risiko` | Deskripsi Risiko | teks panjang |  | Ya |
| 2 | `dampak` | Dampak (H/M/L) | pilihan | H, M, L | Ya |

### Tabel `lpms3_form.bot001_timeline` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `milestone` | Milestone | teks | Project Kick-off … Project Closure | Ya |
| 2 | `target_tanggal` | Target Tanggal | tanggal |  | Ya |

### Tabel `lpms3_form.bot001_term_of_payment` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `urutan` | Term of Payment ke- | bilangan bulat |  | Ya |
| 2 | `persen_atau_nominal` | % atau nominal | teks |  | Ya |

### Tabel `lpms3_form.bot001_key_stakeholders` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `nama_instansi` | Nama / Instansi | teks |  | Ya |
| 2 | `peran` | Peran | teks |  | Ya |
| 3 | `kepentingan_pengaruh` | Kepentingan / Pengaruh | teks |  | Ya |

## SFR-028 rev.00 — Rapat Tinjauan Order/Kontrak – Go/No Go

- **Sumber template:** `form/SFR-028 Formulir Rapat Tinjauan Order_Kontrak Go atau No Go rev.00.xlsx`
- **Fase:** Pra-proyek → Inisiasi  ·  **Prosedur:** SOP-001, SOP-004
- **Pemilik/pengisi:** Fungsi Pemasaran (mengajukan) / Fungsi Pengawasan Pra Proyek (memeriksa)
- **Menu LPMS3:** PROJECT › Add New (lampiran dari LPMS 2 / pra-proyek) & PHASE › [Inisiasi] ringkasan
- **Pengesahan (tabel `form_signature`):** Mengajukan: Fungsi Pemasaran; Memeriksa: Fungsi Pengawasan Pra Proyek; Menyetujui: Pemimpin Rapat Tinjauan (Direktur…); Penyelenggara Rapat Tinjauan (Direktur…); Peninjau Aspek (Direktur…)

### Tabel `lpms3_form.sfr028_go_nogo` (header)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `nomor` | No.: NN/SFR-028/XXX/MMM/YYYY | teks | penomoran otomatis | Ya |
| 2 | `jenis_tinjauan` | Tinjauan Order / Kontrak | pilihan | Order, Kontrak | Ya |
| 3 | `nama_proyek` | Nama Proyek | teks |  | Ya |
| 4 | `nilai_proyek` | Nilai Proyek | uang (Rp) |  | Ya |
| 5 | `nama_pelanggan` | Nama Pelanggan | teks |  | Ya |
| 6 | `sumber_anggaran` | Sumber Anggaran | teks |  | Ya |
| 7 | `lini_bisnis` | Lini Bisnis | pilihan | Pertahanan, Non-Pertahanan - Energi, Non-Pertahanan - Transportasi, Non-Pertahanan - ICT, Non-Pertahanan - Retail, Lainnya | Ya |
| 8 | `tanggal` | Tanggal | tanggal |  | Ya |
| 9 | `tempat` | Tempat | teks |  | Ya |
| 10 | `pemimpin_tinjauan` | Pemimpin Tinjauan | pengguna |  | Ya |
| 11 | `kesimpulan_teknis` | 1. Kesimpulan Hasil Tinjauan Order/Kontrak – Teknis | teks panjang |  | Ya |
| 12 | `kesimpulan_costing` | 2. Kesimpulan Hasil Tinjauan Order/Kontrak – Costing | teks panjang |  | Ya |
| 13 | `aspek_risiko` | 3. Aspek Risiko Tinjauan Order/Kontrak | teks panjang |  | Ya |
| 14 | `paparan` | 4. Paparan Tinjauan – Teknis, Costing, Go/No Go | teks panjang |  | Ya |
| 15 | `keputusan_forum` | Keputusan Forum | pilihan | Menyetujui (Go), Menolak (No Go) | Ya |
| 16 | `catatan` | catatan | teks panjang |  | – |
| 17 | `kelas_tinjauan` | Kelas tinjauan (penentu penanda tangan) | pilihan | Kecil, Sedang, Besar | Ya |
| 18 | `daftar_hadir` | Daftar hadir terlampir | berkas |  | Ya |

## RFR-004 rev.02 — Profil Proyek

- **Sumber template:** `form/RFR-004 Formulir Profil Proyek rev.02.xlsx`
- **Fase:** Pra-proyek → Inisiasi  ·  **Prosedur:** ROP-911, SOP-001
- **Pemilik/pengisi:** Fungsi Pemasaran / Fungsi Perencanaan Proyek; reviu Fungsi Manajemen Risiko
- **Menu LPMS3:** PHASE › [Inisiasi] › Preliminary PM Aspect (Risiko) & Risk Status
- **Pengesahan (tabel `form_signature`):** Yang Membuat (Nama, NIK)

### Tabel `lpms3_form.rfr004_profil_proyek` (header)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `nama_proyek` | Nama Proyek | teks |  | Ya |
| 2 | `customer` | Customer | teks |  | Ya |
| 3 | `lini_bisnis` | Lini Bisnis | pilihan | Pertahanan, Non-Pertahanan - Energi, Non-Pertahanan - Transportasi, Non-Pertahanan - ICT, Non-Pertahanan - Retail, Lainnya | Ya |
| 4 | `risk_owner` | Risk Owner | pengguna |  | Ya |
| 5 | `project_manager` | Project Manager | pengguna |  | Ya |
| 6 | `tanggal_update` | Tanggal Update | tanggal |  | Ya |
| 7 | `revisi` | Revisi | bilangan bulat |  | Ya |
| 8 | `deskripsi_singkat` | 1 Deskripsi Singkat Proyek | teks panjang |  | Ya |
| 9 | `lokasi_proyek` | 2 Lokasi Proyek | teks |  | Ya |
| 10 | `kondisi_lokasi` | 2 Lokasi – kondisi | pilihan | Aman dan mudah akses, Sebagian lokasi sulit akses dan/atau tidak aman, Sulit akses dan/atau daerah rawan | Ya |
| 11 | `skema_perolehan` | 4 Skema Perolehan Proyek | pilihan | Tender, Penunjukan Langsung | Ya |
| 12 | `tgl_ttd_perjanjian` | 5 Tanggal Penandatanganan Perjanjian | tanggal |  | Ya |
| 13 | `status_ttd` | 5 Status validasi | pilihan | target akan ditandatangan, sudah ditandatangan | Ya |
| 14 | `jenis_waktu` | 6 Waktu Pelaksanaan – Jenis | pilihan | Single Year, Multi Year | Ya |
| 15 | `kecukupan_waktu` | 6 Kecukupan Jangka Waktu | pilihan | Cukup, Ketat, Tidak Cukup | Ya |
| 16 | `waktu_mulai` | 6 waktu pelaksanaan (… s/d …) mulai | tanggal |  | Ya |
| 17 | `waktu_selesai` | 6 waktu pelaksanaan (… s/d …) selesai | tanggal |  | Ya |
| 18 | `mata_uang` | 7 Nilai Proyek (Netto) – Mata Uang | pilihan | IDR, USD, EUR, GBP, JPY, SGD, AUD, Lainnya | Ya |
| 19 | `nilai_proyek_netto` | 7 Nilai Proyek (Netto) | uang (Rp) |  | Ya |
| 20 | `bdp_pct` | 8 BDP | HPP (%) – BDP | persen 0–100 | ideal ≤ 86,5% | Ya |
| 21 | `hpp_pct` | 8 BDP | HPP (%) – HPP | persen 0–100 |  | Ya |
| 22 | `lbdp` | 9 LBDP | Laba Bruto – LBDP | uang (Rp) |  | Ya |
| 23 | `laba_bruto` | 9 LBDP | Laba Bruto – Laba Bruto | uang (Rp) |  | Ya |
| 24 | `ebitda_pct` | 10 EBITDA (%) | persen 0–100 |  | Ya |
| 25 | `ebitda_nilai` | 10 EBITDA (nilai) | uang (Rp) |  | – |
| 26 | `nama_customer` | 11 Nama Customer | teks |  | Ya |
| 27 | `jenis_customer` | 11 Jenis Customer | pilihan | Kementrian / Lembaga Pemerintah, BUMN / BUMD, Swasta, Asing | Ya |
| 28 | `status_customer` | 12 Status Customer | pilihan | New Customer, Existing Customer | Ya |
| 29 | `sumber_anggaran` | 13 Sumber Anggaran | pilihan | APBN, APBD, BUMN/ BUMD, Swasta, PDN, PLN, Lainnya | Ya |
| 30 | `nama_sumber_anggaran` | 13 Nama Sumber Anggaran | teks |  | – |
| 31 | `term_of_payment` | 14 Term of Payment | pilihan | Pelunasan Di muka, Termin (Jelaskan di kolom keterangan), Turnkey | Ya |
| 32 | `metode_pembayaran` | 15 Metode Pembayaran | pilihan | T/T, SKBDN, L/C, SCF, Giro mundur, Lainnya | Ya |
| 33 | `umur_piutang` | 16 Jatuh Tempo Pembayaran Setelah Tagihan | pilihan | 0 Hari Kalender / Segera, 15 Hari Kalender, 30 Hari Kalender, 45 Hari Kalender, 60 Hari Kalender, 120 Hari Kalender, 180 Hari Kalender, Lainnya | Ya |
| 34 | `jaminan_penawaran_pct` | 17 Jaminan Penawaran (%) | persen 0–100 |  | – |
| 35 | `jaminan_uang_muka_pct` | 17 Jaminan Uang Muka (%) | persen 0–100 |  | – |
| 36 | `jaminan_pelaksanaan_pct` | 17 Jaminan Pelaksanaan (%) | persen 0–100 |  | – |
| 37 | `jaminan_pembayaran_pct` | 17 Jaminan Pembayaran (%) | persen 0–100 |  | – |
| 38 | `jaminan_pemeliharaan_pct` | 17 Jaminan Pemeliharaan (%) | persen 0–100 |  | – |
| 39 | `jaminan_fungsional_pct` | 17 Jaminan Fungsional (%) | persen 0–100 |  | – |
| 40 | `jaminan_lainnya` | 17 Jaminan Lainnya (% & uraian) | teks |  | – |
| 41 | `ppn` | 18 PPN | pilihan | Ada, Tidak dipungut, Bebas PPN, Tidak ada | Ya |
| 42 | `pph_final` | 18 PPh Final (Ada/Tidak Ada, %) | teks |  | Ya |
| 43 | `bea_impor` | 18 Bea Impor (Ada/Tidak Ada, %) | teks |  | Ya |
| 44 | `pajak_lainnya` | 18 Pajak/Bea Lainnya | teks |  | – |
| 45 | `posisi_len` | 19 Posisi Len dalam Proyek | pilihan | Kontraktor Utama, Sub-Kontraktor, Retail | Ya |
| 46 | `kebutuhan_partnership` | 20 Kebutuhan Partnership | pilihan | Tidak Perlu, Konsorsium/ KSO/ Joint Operation, Joint Venture, ToT Pemilik Teknologi, Lainnya | Ya |
| 47 | `kategori_proyek` | 21 Kategori Proyek | pilihan | Proyek EPC, Proyek MRO, Proyek Investasi, Proyek Penelitian dan Pengembangan, Retail | Ya |
| 48 | `jenis_order` | 22 Jenis Order/ Proyek | pilihan | Proyek Perdana, Sudah Ada Proyek Sejenis, Repeat Order | Ya |
| 49 | `regulasi_khusus` | 23 Dipengaruhi Regulasi/ Peraturan Khusus (+penjelasan) | teks | Ya, Tidak | Ya |
| 50 | `lingkup_pekerjaan` | 24 Ruang Lingkup: Survey, Perizinan, Desain, Pengadaan, Software, Konstruksi/infrastruktur, Instalasi, Integrasi Sistem, Pemeliharaan, Pelatihan, Produksi (Transfer Load), Operator, Lainnya | daftar/terstruktur | 13 butir Ya/Tidak | Ya |
| 51 | `ketergantungan_pihak_ketiga` | 25 Ketergantungan Penyelesaian atas Pekerjaan Pihak Ketiga | pilihan | Ada, Tidak Ada | Ya |
| 52 | `pct_material_impor` | 26 Persentase Pengadaan Material Impor terhadap HPP | persen 0–100 |  | Ya |
| 53 | `barang_spesifik` | 27 Pengadaan Barang Spesifik/ Khusus/ Customize | pilihan | Ada, Tidak Ada | Ya |
| 54 | `ketersediaan_personel` | 28 Ketersediaan Jumlah Personel | pilihan | Cukup, Tidak Cukup | Ya |
| 55 | `kebutuhan_kompetensi` | 29 Kebutuhan Kompetensi Personel Proyek | pilihan | Ya, Tidak | Ya |
| 56 | `skema_bisnis` | 30 Skema Bisnis (gambar) | berkas |  | Ya |
| 57 | `timeline_proyek` | 31 Timeline Proyek (gambar) | berkas |  | Ya |
| 58 | `keterangan_per_butir` | Kolom KETERANGAN per butir | daftar/terstruktur |  | – |

## RFR-005 rev.00 — Profil Risiko Program

- **Sumber template:** `form/RFR-005 Profil Risiko Program rev.00.pdf`
- **Fase:** Inisiasi (program)  ·  **Prosedur:** ROP-911, EOP-304
- **Pemilik/pengisi:** Unit Pengusul Program
- **Menu LPMS3:** PHASE › [Inisiasi] (jenis kode Program)
- **Pengesahan (tabel `form_signature`):** Disiapkan, Diperiksa, Disahkan (Nama)

### Tabel `lpms3_form.rfr005_profil_program` (header)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `nama_program` | Nama Program Pengembangan | teks |  | Ya |
| 2 | `unit_pengusul` | Unit Pengusul | unit organisasi |  | Ya |
| 3 | `jenis_program` | Jenis Program Pengembangan | pilihan | daftar di form | Ya |
| 4 | `tanggal_update` | Tanggal Update | tanggal |  | Ya |
| 5 | `revisi` | Revisi ke | bilangan bulat |  | Ya |
| 6 | `deskripsi_singkat` | 1 Deskripsi Singkat Program Pengembangan | teks panjang |  | Ya |
| 7 | `sumber_usulan` | 3 Sumber Usulan Pengembangan | pilihan | daftar di form | Ya |
| 8 | `lini_bisnis` | 4 Lini Bisnis Terkait Produk | pilihan | Pertahanan, Non-Pertahanan - Energi, Non-Pertahanan - Transportasi, Non-Pertahanan - ICT, Non-Pertahanan - Retail, Lainnya | Ya |
| 9 | `output_pengembangan` | 5 Output Pengembangan | pilihan | daftar di form | Ya |
| 10 | `pihak_eksternal` | 6 Keterlibatan pihak eksternal (+posisi) | teks | Ya, Tidak | Ya |
| 11 | `haki` | 7 Potensi Kepemilikan HAKI | pilihan | daftar di form | Ya |
| 12 | `sertifikasi_produk` | 8 Potensi Kebutuhan Sertifikasi Produk | teks | Ya, Tidak | Ya |
| 13 | `kajian_kelayakan` | 10 Kajian Kelayakan | pilihan | daftar di form | Ya |
| 14 | `mata_uang` | 11 Biaya Pengembangan – Mata Uang | pilihan | IDR, USD, EUR, Lainnya | Ya |
| 15 | `biaya_pengembangan` | 11 Biaya Pengembangan (Netto) | uang (Rp) |  | Ya |
| 16 | `regulasi_khusus` | 13 Dipengaruhi Regulasi / Aturan Khusus | teks | Ya, Tidak | Ya |
| 17 | `jenis_waktu` | 14 Waktu Pelaksanaan Program (jenis, tgl s/d tgl) | teks |  | Ya |
| 18 | `ruang_lingkup` | 15 Ruang Lingkup Pekerjaan (Inovasi Produk, dst.) | daftar/terstruktur |  | Ya |
| 19 | `pct_material_impor` | 16 Persentase Pengadaan Material Impor | persen 0–100 |  | Ya |
| 20 | `barang_spesifik` | 17 Pengadaan Barang Spesifik/Khusus | pilihan | Ada, Tidak Ada | Ya |
| 21 | `ketersediaan_personel` | 18 Ketersediaan Jumlah Personel | pilihan | Cukup, Tidak Cukup | Ya |
| 22 | `personel_khusus` | 19 Kebutuhan personel berkualifikasi khusus | pilihan | Ya, Tidak | Ya |
| 23 | `sertifikasi_tkdn` | 20 Sertifikasi TKDN | pilihan | Ya, Tidak | Ya |
| 24 | `struktur_organisasi` | 21 Struktur Organisasi & Kebutuhan Kompetensi | berkas |  | Ya |
| 25 | `skema_proses` | 22 Skema Proses Pengembangan Ide Produk | berkas |  | Ya |

## RFR-002 rev.03 — Project Risk Register

- **Sumber template:** `form/RFR-002 Project Risk Register rev.03.xlsx`
- **Fase:** Inisiasi → Closing (update bulanan)  ·  **Prosedur:** ROP-911, BOP-001 §5.2.1.7, §5.3.6, §5.4.9
- **Pemilik/pengisi:** Fungsi Manajemen Proyek (Risk Owner); reviu Fungsi Manajemen Risiko
- **Menu LPMS3:** PHASE › [Monitoring] › Risk Status

### Tabel `lpms3_form.rfr002_header` (header)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `nama_proyek` | Nama Proyek | teks |  | Ya |
| 2 | `customer` | Customer | teks |  | Ya |
| 3 | `lini_bisnis` | Lini Bisnis | pilihan | Pertahanan, Non-Pertahanan - Energi, Non-Pertahanan - Transportasi, Non-Pertahanan - ICT, Non-Pertahanan - Retail, Lainnya | Ya |
| 4 | `risk_owner` | Risk Owner | pengguna |  | Ya |
| 5 | `project_manager` | Project Manager | pengguna |  | Ya |
| 6 | `tanggal_update` | Tanggal Update | tanggal |  | Ya |
| 7 | `revisi` | Revisi | bilangan bulat |  | Ya |
| 8 | `referensi` | Referensi (Ref) 1..3 | daftar/terstruktur |  | – |

### Tabel `lpms3_form.rfr002_risiko` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `kategori_risiko` | (2) Kategori Risiko *merujuk Standar Risiko | pilihan | Kelangsungan bisnis jangka panjang (strategis), Gagal tender, Keterlambatan pengadaan barang, Wanprestasi pekerjaan pihak ketiga, Keterlambatan penyelesaian pekerjaan, Kenaikan biaya proyek (harga, operasional, pemeliharaan), Ketidakhandalan produk, Kerusakan produk, Progres pekerjaan tidak diakui customer, Keterlambatan pembayaran customer (piutang), Pengurangan Scope of Work (SoW), Penghentian pekerjaan, Overstock, Fluktuasi kurs, Perpajakan, Legal, Kehilangan SDM, Pelanggaran SMAP, (Proyek Investasi) Target output tidak tercapai, Keamanan, Lainnya | Ya |
| 2 | `peristiwa_risiko` | (3) Peristiwa Risiko *merujuk Standar Risiko | pilihan | sheet Standar Risiko | Ya |
| 3 | `kode_risiko` | (4) Kode Risiko (Risk Id) | teks | otomatis dari standar | Ya |
| 4 | `peristiwa_lainnya` | (5) Peristiwa Risiko Lainnya | teks panjang |  | – |
| 5 | `penyebab_risiko` | (6) Penyebab Risiko (bisa >1) | daftar/terstruktur |  | Ya |
| 6 | `dampak_inheren_rp` | (7) Dampak Risiko Inheren – Kuantitatif (Rp) | uang (Rp) |  | Ya |
| 7 | `dampak_inheren_kualitatif` | (8) Dampak Risiko Inheren – Kualitatif (bisa >1) | daftar/terstruktur |  | Ya |
| 8 | `inheren_skala_dampak` | (9) Risiko Inheren – Skala Dampak | pilihan | 1, 2, 3, 4, 5 | Ya |
| 9 | `inheren_skala_kemungkinan` | (10) Risiko Inheren – Skala Kemungkinan | pilihan | 1, 2, 3, 4, 5 | Ya |
| 10 | `inheren_level` | (11) Risiko Inheren – Level Risiko | pilihan | Rendah (1-5), Rendah-Menengah (6-11), Menengah (12-15), Menengah-Tinggi (16-19), Tinggi (20-25) | Ya |
| 11 | `rencana_penanganan` | (12) Rencana Penanganan Risiko (bisa >1) | daftar/terstruktur |  | Ya |
| 12 | `pic` | (13) PIC | pengguna |  | Ya |
| 13 | `target_waktu_penanganan` | (14) Target Waktu Penanganan Risiko | tanggal |  | Ya |
| 14 | `target_res_skala_dampak` | (15) Target Risiko Residual – Skala Dampak | pilihan | 1, 2, 3, 4, 5 | Ya |
| 15 | `target_res_skala_kemungkinan` | (16) Target Risiko Residual – Skala Kemungkinan | pilihan | 1, 2, 3, 4, 5 | Ya |
| 16 | `target_res_level` | (17) Target Risiko Residual – Level Risiko | pilihan | Rendah (1-5), Rendah-Menengah (6-11), Menengah (12-15), Menengah-Tinggi (16-19), Tinggi (20-25) | Ya |
| 17 | `realisasi_penanganan` | (18) Deskripsi Realisasi Penanganan Risiko | teks panjang |  | – |
| 18 | `realisasi_waktu_penanganan` | (19) Realisasi Waktu Penanganan Risiko | tanggal |  | – |
| 19 | `res_skala_dampak` | (20) Risiko Residual – Skala Dampak | pilihan | 1, 2, 3, 4, 5 | – |
| 20 | `res_skala_kemungkinan` | (21) Risiko Residual – Skala Kemungkinan | pilihan | 1, 2, 3, 4, 5 | – |
| 21 | `res_level` | (22) Risiko Residual – Level Risiko | pilihan | Rendah (1-5), Rendah-Menengah (6-11), Menengah (12-15), Menengah-Tinggi (16-19), Tinggi (20-25) | – |
| 22 | `dampak_residual_rp` | (23) Dampak Risiko Residual – Kuantitatif (Rp) | uang (Rp) |  | – |
| 23 | `dampak_residual_kualitatif` | (24) Dampak Risiko Residual – Kualitatif | daftar/terstruktur |  | – |
| 24 | `kejadian_risiko` | (25) Kejadian Risiko | pilihan | Terjadi, Tidak Terjadi | – |
| 25 | `catatan` | (26) Catatan | teks panjang |  | – |

## RFR-001 rev.05 — Risk Register Unit Kerja (kertas kerja)

- **Sumber template:** `form/Kertas Kerja RFR-001 Formulir Risk Register Unit Kerja rev.05_20250210.xlsx`
- **Fase:** Eksekusi & Monitoring (risiko operasional)  ·  **Prosedur:** ROP-910
- **Pemilik/pengisi:** Unit kerja pelaksana proyek
- **Menu LPMS3:** PHASE › [Monitoring] › Risk Status (tab Risiko Operasional)

### Tabel `lpms3_form.rfr001_header` (header)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `jenis_unit` | Divisi/Bagian | pilihan | DIVISI, BAGIAN | Ya |
| 2 | `unit_kerja` | Unit kerja | unit organisasi |  | Ya |
| 3 | `tahun` | Tahun | bilangan bulat |  | Ya |
| 4 | `revisi_ke` | Revisi ke | bilangan bulat |  | Ya |
| 5 | `periode` | Periode | pilihan | Awal Tahun, Januari, Februari, Maret, April, Mei, Juni, Juli, Agustus, September, Oktober, November, Desember | Ya |
| 6 | `tanggal_update` | Tanggal update | tanggal |  | Ya |

### Tabel `lpms3_form.rfr001_risiko` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `sasaran` | 2 Sasaran | teks | (Usulan) KPI / SKU, Tupoksi Unit Kerja, Arahan Pimpinan / Harapan Stakeholders, ISO / standar lainnya, Regulasi, Kebijakan, Aturan Eksternal dan Internal, Lainnya | Ya |
| 2 | `peristiwa_risiko` | 3 Peristiwa Risiko | teks panjang |  | Ya |
| 3 | `taksonomi_risiko` | 4 Kategori / Taksonomi Risiko | pilihan | sheet Taksonomi Risiko (1.1.1 …) | Ya |
| 4 | `penyebab_risiko` | 5 Penyebab Risiko | teks panjang |  | Ya |
| 5 | `uraian_dampak` | 6 Uraian Dampak | teks panjang |  | Ya |
| 6 | `nilai_dampak_rp` | 7 Nilai Dampak (Rp) | uang (Rp) |  | Ya |
| 7 | `kontrol_existing` | 8 Kontrol Yang Ada (Existing Control) | teks panjang |  | Ya |
| 8 | `kecukupan` | 9 Kecukupan | pilihan | Cukup, Tidak Cukup | Ya |
| 9 | `efektivitas` | 10 Efektivitas | pilihan | Efektif, Efektif Sebagian, Tidak Efektif | Ya |
| 10 | `inheren_skala_dampak` | 11 Risiko Inheren – Skala Dampak | pilihan | 1, 2, 3, 4, 5 | Ya |
| 11 | `inheren_skala_kemungkinan` | 12 Risiko Inheren – Skala Kemungkinan | pilihan | 1, 2, 3, 4, 5 | Ya |
| 12 | `inheren_level` | 13 Risiko Inheren – Level Risiko | pilihan | Rendah (1-5), Rendah-Menengah (6-11), Menengah (12-15), Menengah-Tinggi (16-19), Tinggi (20-25) | Ya |
| 13 | `program_kerja` | 14 Program Kerja / Rencana Perlakuan Risiko | teks panjang |  | Ya |
| 14 | `unit_terkait` | 15 Unit Kerja Terkait | teks |  | – |
| 15 | `anggaran_program_rp` | 16 Anggaran Biaya Program Kerja (Rp) | uang (Rp) |  | – |
| 16 | `target_res_skala_dampak` | 17 Target Risiko Residual – Skala Dampak | pilihan | 1, 2, 3, 4, 5 | Ya |
| 17 | `target_res_skala_kemungkinan` | 18 Target Risiko Residual – Skala Kemungkinan | pilihan | 1, 2, 3, 4, 5 | Ya |
| 18 | `target_res_level` | 19 Target Risiko Residual – Level Risiko | pilihan | Rendah (1-5), Rendah-Menengah (6-11), Menengah (12-15), Menengah-Tinggi (16-19), Tinggi (20-25) | Ya |
| 19 | `risiko_positif` | 20 Risiko Positif | teks panjang |  | – |
| 20 | `jadwal_jan_des` | 21–32 Target & Realisasi Waktu Pelaksanaan Program Kerja (JAN … DES) | daftar/terstruktur | 12 bulan × {target, realisasi} | Ya |
| 21 | `deskripsi_realisasi` | 33 Deskripsi Realisasi Program Kerja | teks panjang |  | – |
| 22 | `pct_realisasi` | 34 % Realisasi Program Kerja | persen 0–100 |  | – |
| 23 | `realisasi_biaya_rp` | 35 Realisasi Biaya Program Kerja (Rp) | uang (Rp) |  | – |
| 24 | `real_res_skala_dampak` | 36 Realisasi Risiko Residual – Skala Dampak | pilihan | 1, 2, 3, 4, 5 | – |
| 25 | `real_res_skala_kemungkinan` | 37 Realisasi Risiko Residual – Skala Kemungkinan | pilihan | 1, 2, 3, 4, 5 | – |
| 26 | `real_res_level` | 38 Realisasi Risiko Residual – Level Risiko | pilihan | Rendah (1-5), Rendah-Menengah (6-11), Menengah (12-15), Menengah-Tinggi (16-19), Tinggi (20-25) | – |
| 27 | `status_terjadi` | 39 Status Terjadinya Risiko | pilihan | Terjadi, Tidak Terjadi | – |
| 28 | `catatan` | 40 Catatan | teks panjang |  | – |

## VFR-015 rev.05 — Identifikasi dan Penilaian Bahaya-Risiko K3 dan Aspek-Dampak Lingkungan (HIRA)

- **Sumber template:** `form/VFR-015 ... rev.05_20191230.xlsx (+ contoh HIRA PMO & Marketing)`
- **Fase:** Perencanaan → Eksekusi (review saat perubahan)  ·  **Prosedur:** VOP-505, VOP-513, BOP-001 §5.3.6
- **Pemilik/pengisi:** Fungsi K3L / P2K3 bersama Pimpro
- **Menu LPMS3:** PHASE › [Monitoring] › K3LH Status
- **Pengesahan (tabel `form_signature`):** Disusun: P2K3 / Team Leader-Site Manager / Subcon; Direview: HSE Korporasi / HSE Koordinator / P2K3 Unit; Disetujui: Kepala Unit Kerja / Pimpinan Proyek

### Tabel `lpms3_form.vfr015_header` (header)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `divisi_bagian_unit` | Divisi/Bag/Unit | unit organisasi |  | Ya |
| 2 | `no_review` | No. Review | bilangan bulat |  | Ya |
| 3 | `tanggal` | Tgl | tanggal |  | Ya |
| 4 | `lingkup` | Proyek / Korporasi / Subcon | pilihan | Proyek, Korporasi, Subcon | Ya |

### Tabel `lpms3_form.vfr015_aspek_bahaya` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `aktivitas` | 2 Aktifitas / Obyek / Produk | teks |  | Ya |
| 2 | `rutin` | 3 Aktifitas Rutin (R) / Non Rutin (NR) | pilihan | R, NR | Ya |
| 3 | `no_aspek_bahaya` | 4 No. Aspek / Bahaya | teks |  | Ya |
| 4 | `aspek_bahaya` | 5 Aspek / Bahaya | pilihan | sheet Pilihan RisikoDampak | Ya |
| 5 | `dampak_risiko` | 6 Dampak / Resiko | pilihan | sheet Pilihan RisikoDampak | Ya |
| 6 | `kondisi_operasional` | 7 Kondisi Operasional (N, Ab, E) | pilihan | N, Ab, E | Ya |
| 7 | `jenis_dampak` | 8 Jenis Dampak (+/-) | pilihan | +, - | Ya |
| 8 | `pengendalian_ada` | 9 Pengendalian Yang Ada (hierarki) | pilihan | Administrasi, APD, Eliminasi, Pengelolaan limbah, Pengolahan limbah, Recycle, Reduce, Rekayasa Teknik, Reuse, Substitusi | Ya |
| 9 | `pengendalian_uraian` | 9 Pengendalian Yang Ada – uraian | teks panjang |  | – |
| 10 | `keparahan` | 10 Nilai Dampak/Resiko – Keparahan | pilihan | 1, 2, 3, 4 | Ya |
| 11 | `kemungkinan` | 11 Nilai Dampak/Resiko – Kemungkinan | pilihan | 1, 2, 3, 4 | Ya |
| 12 | `total` | 12 Total (Keparahan × Kemungkinan) | bilangan bulat | dihitung | Ya |
| 13 | `level_risiko` | 13 Level Risiko | teks | dihitung (LOW/MEDIUM/HIGH …) | Ya |
| 14 | `aspek_signifikan` | 14 Aspek significant (Yes/No) | pilihan | Yes, No | Ya |
| 15 | `legal` | 15 Legal (peraturan terkait) | teks | sheet Pilihan RisikoDampak | – |
| 16 | `risiko` | 16 Risiko | teks |  | – |
| 17 | `peluang` | 17 Peluang | teks |  | – |
| 18 | `eval_legal` | 18 Evaluasi – Legal and Other Requirement | pilihan | 0, 1, 3, 5 | – |
| 19 | `eval_teknologi` | 19 Evaluasi – Technological Option | pilihan | 1, 3, 5 | – |
| 20 | `eval_finansial` | 20 Evaluasi – Financial | pilihan | 1, 3, 5 | – |
| 21 | `eval_operasional` | 21 Evaluasi – Operational and Business Requirement | pilihan | 1, 3, 5 | – |
| 22 | `eval_pihak_berkepentingan` | 22 Evaluasi – View of Interested parties | pilihan | 1, 3, 5 | – |
| 23 | `eval_total` | 23 Evaluasi – Total | bilangan bulat | dihitung | – |
| 24 | `pertimbangan_otp` | 24 Pertimbangan OTP? | teks |  | – |
| 25 | `action_plan` | 25 Action Plan (hierarki pengendalian) | teks panjang |  | – |
| 26 | `no_action_plan` | 26 No Action Plan | teks |  | – |

## CFR-022 rev.01 — Risalah Rapat

- **Sumber template:** `form/CFR-022 Formulir Risalah Rapat rev.01.docx`
- **Fase:** Semua fase (Kick-Off, Rapat Tinjauan, Top-Up, Pergeseran, ABT, Adendum)  ·  **Prosedur:** BOP-001 §5.2.2, §5.3.5, §5.4.8, BOG-003, SOP-004, SOP-009
- **Pemilik/pengisi:** Penyelenggara rapat (umumnya Fungsi Pengawasan Proyek)
- **Menu LPMS3:** PHASE › [Perencanaan] Reviu PMP & Kick-Off / [Eksekusi] ringkasan Rapat
- **Pengesahan (tabel `form_signature`):** Persetujuan Hasil Rapat: Pimpinan rapat & peserta (nama, fungsi, tanda tangan)

### Tabel `lpms3_form.cfr022_risalah` (header)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `nomor` | No. 00/CFR-022/XXXX/MM/YYYY | teks | penomoran otomatis per unit | Ya |
| 2 | `jenis_rapat` | Jenis rapat (LPMS3) | pilihan | Kick-Off Meeting, Rapat Tinjauan Proyek, Rapat Tinjauan Top-Up, Rapat Tinjauan Pergeseran Anggaran, Rapat Tinjauan ABT, Rapat Tinjauan Adendum, Rapat CCM, Lainnya | Ya |
| 3 | `judul_rapat` | Judul / perihal rapat | teks |  | Ya |
| 4 | `tanggal` | Tanggal | tanggal |  | Ya |
| 5 | `waktu_mulai` | Waktu mulai | teks |  | Ya |
| 6 | `waktu_selesai` | Waktu selesai | teks |  | – |
| 7 | `tempat` | Tempat / media | teks |  | Ya |
| 8 | `pimpinan_rapat` | Pimpinan rapat | pengguna |  | Ya |
| 9 | `notulis` | Notulis | pengguna |  | Ya |

### Tabel `lpms3_form.cfr022_agenda` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `agenda_bahasan` | I. Agenda Bahasan | teks |  | Ya |
| 2 | `resume_bahasan` | I. Resume Bahasan | teks panjang |  | Ya |

### Tabel `lpms3_form.cfr022_tindak_lanjut` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `isu` | II. Isu | teks panjang |  | Ya |
| 2 | `tindak_lanjut` | II. Tindak-Lanjut | teks panjang |  | Ya |
| 3 | `deadline` | II. Deadline | tanggal |  | Ya |
| 4 | `pic` | II. PIC | pengguna | → dibuat sebagai Action Item WP | Ya |

### Tabel `lpms3_form.cfr022_peserta` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `nama` | Peserta – Nama | pengguna |  | Ya |
| 2 | `fungsi_jabatan` | Peserta – Fungsi/Jabatan | teks |  | Ya |
| 3 | `peran_rapat` | Peran (Pemimpin, Penyelenggara, Pemapar, Peninjau aspek, Narasumber, Peserta) | pilihan | Pemimpin, Penyelenggara, Pemapar, Pendukung Pemapar, Peninjau Aspek, Narasumber, Peserta, Delegasi | Ya |
| 4 | `hadir` | Kehadiran | ya/tidak |  | Ya |
| 5 | `delegasi_dari` | Mewakili (delegasi struktural) | pengguna |  | – |
| 6 | `persetujuan` | Persetujuan hasil rapat (tanda tangan) | ya/tidak |  | – |

## BFR-001 rev.00 — Formulir Change Log / Change Request

- **Sumber template:** `form/BFR-001 Formulir Change Log.pdf`
- **Fase:** Eksekusi & Monitoring (Integrated Change Control)  ·  **Prosedur:** BOP-001 §5.3.1, §5.4.2, BOG-003, SOP-009
- **Pemilik/pengisi:** Pimpinan Proyek (pengaju)
- **Menu LPMS3:** PHASE › [Eksekusi] › Change Request (BFR-001)
- **Pengesahan (tabel `form_signature`):** Diajukan oleh: Pimpinan Proyek; Menyetujui: Eselon II/I Fungsi Manajemen Proyek (< Rp1 M: Es.II; ≥ Rp1 M: Es.I); Diperiksa oleh: Fungsi Pengawasan Proyek; Menyetujui: Eselon II/I Fungsi Pengawasan Proyek (ambang sama)

### Tabel `lpms3_form.bfr001_change_request` (header)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `unit_kerja` | Unit Kerja | unit organisasi |  | Ya |
| 2 | `nama_proyek` | Nama Proyek | teks |  | Ya |
| 3 | `kode_proyek` | Kode Proyek | teks | valid sesuai daftar kode | Ya |
| 4 | `progres_lkp_pct` | Progres proyek (% LKP) | persen 0–100 | otomatis dari LKP terakhir published | Ya |
| 5 | `change_request_no` | Change Request No. NN/BFR-001/XXXX/MM/YYYY | teks | penomoran otomatis | Ya |
| 6 | `kategori_perubahan` | Kategori Perubahan | daftar/terstruktur | ANGGARAN, SCOPE, JADWAL, KURVA-S | Ya |
| 7 | `latar_belakang` | Latar belakang perubahan | teks panjang |  | Ya |
| 8 | `anggaran_jenis` | Perubahan Anggaran – jenis | pilihan | Pergeseran Anggaran (WBS Eksisting), Pergeseran Anggaran (WBS Baru) | – |
| 9 | `anggaran_nilai_kebutuhan` | Nilai Kebutuhan Anggaran | uang (Rp) |  | – |
| 10 | `anggaran_dari_wbs` | pergeseran dari WBS (Kode & Nama) | node WBS |  | – |
| 11 | `anggaran_ke_wbs` | ke WBS / WBS Baru (Kode & Nama) | node WBS |  | – |
| 12 | `scope_jenis` | Perubahan Scope Pekerjaan | pilihan | Perubahan Scope Pekerjaan, Penambahan Scope Pekerjaan, Pengurangan Scope pekerjaan | – |
| 13 | `jadwal_selesai_kontrak_awal` | Tanggal penyelesaian – kontrak awal | tanggal |  | – |
| 14 | `jadwal_selesai_addendum` | Tanggal penyelesaian – addendum | tanggal |  | – |
| 15 | `kurva_s_awal` | Kurva S awal (terlampir) | berkas | snapshot baseline | – |
| 16 | `kurva_s_perubahan` | Kurva S perubahan (terlampir) | berkas | snapshot usulan | – |
| 17 | `catatan_pengawasan` | Catatan Fungsi Pengawasan Proyek (checklist 18 butir) | daftar/terstruktur | anggaran 4, scope 8, jadwal 4, kurva-S 4 | Ya |
| 18 | `catatan_eselon_pengawasan` | Catatan Eselon I/II Fungsi Pengawasan Proyek (rekomendasi 9 butir) | daftar/terstruktur |  | Ya |
| 19 | `ambang_persetujuan` | Ambang persetujuan (dihitung) | pilihan | < Rp1 Miliar → Eselon II, ≥ Rp1 Miliar → Eselon I | Ya |

## FFR-708 rev.09 — Laporan Kemajuan Proyek/Program/Transfer Load (LKP)

- **Sumber template:** `form/FFR-708 Formulir Laporan Kemajuan Proyek(Program) rev.09.xlsx`
- **Fase:** Eksekusi & Monitoring (bulanan); Closing (LKP 100%)  ·  **Prosedur:** BOP-001 §5.3.1, §5.4.1, FOP-705
- **Pemilik/pengisi:** Pimpinan Proyek (dibuat), Es.II Fungsi Manajemen Proyek (diperiksa), Es.I (disetujui bila 100%/akhir tahun)
- **Menu LPMS3:** PHASE › [Monitoring] › Laporan Kemajuan (LKP / FFR-708)
- **Pengesahan (tabel `form_signature`):** Dibuat: Pimpro (Fungsi Manajemen Proyek); Diperiksa: Eselon 2 Fungsi Manajemen Proyek; Disetujui: Eselon 1 Fungsi Manajemen Proyek **); Disetujui oleh Pemberi Kerja; Dibukukan: Fungsi Akuntansi (Kode, Debet, Kredit, Catatan)

### Tabel `lpms3_form.ffr708_cover` (header)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `jenis_laporan` | Laporan Kemajuan Proyek/Program/Transfer Load *) | pilihan | Proyek, Program, Transfer Load | Ya |
| 2 | `nama_proyek` | Nama Proyek/Program | teks |  | Ya |
| 3 | `kode_proyek` | Kode Proyek/Program | teks |  | Ya |
| 4 | `nomor_kontrak` | Nomor Kontrak | teks |  | Ya |
| 5 | `nilai_proyek` | Nilai Proyek/Program (Nilai tanpa PPn) | uang (Rp) |  | Ya |
| 6 | `tanggal_mulai` | Tanggal Mulai | tanggal |  | Ya |
| 7 | `tanggal_selesai` | Tanggal Selesai | tanggal |  | Ya |
| 8 | `termin_pembayaran` | Termin Pembayaran | daftar/terstruktur | daftar termin % | Ya |
| 9 | `institusi_pemberi_kerja` | Institusi Pemberi Kerja | teks |  | Ya |
| 10 | `pimpro_nama` | Nama Lengkap Pimpinan Proyek | pengguna |  | Ya |
| 11 | `pimpro_telepon` | No. Telepon | teks |  | Ya |
| 12 | `unit_kerja` | Unit Kerja | unit organisasi |  | Ya |
| 13 | `nama_dokumen` | Nama Dokumen | teks |  | Ya |
| 14 | `periode_dari` | Periode Pelaporan – Dari | tanggal |  | Ya |
| 15 | `periode_sampai` | Periode Pelaporan – Sampai | tanggal |  | Ya |
| 16 | `akumulasi_progress_pct` | Akumulasi Progress (%) | persen 0–100 |  | Ya |
| 17 | `disiapkan_nama` | Disiapkan Oleh – Nama | pengguna |  | Ya |
| 18 | `disiapkan_jabatan` | Disiapkan Oleh – Jabatan | teks |  | Ya |
| 19 | `tanggal_pembuatan` | Tanggal Pembuatan | tanggal |  | Ya |
| 20 | `pemberi_kerja_nama` | Disetujui oleh Pemberi Kerja – Nama | teks |  | – |
| 21 | `pemberi_kerja_nik_nrp` | Pemberi Kerja – NIK/NRP | teks |  | – |
| 22 | `pemberi_kerja_jabatan` | Pemberi Kerja – Jabatan | teks |  | – |
| 23 | `tembusan` | Tembusan (Perencanaan Perusahaan, Keuangan, Akuntansi, Audit Internal, Es.1 Fungsi Manajemen Proyek, Arsip) | daftar/terstruktur |  | Ya |

### Tabel `lpms3_form.ffr708_rekap` (lines)

_Rekap Proyek/Program dan Rekap TL memakai struktur sama; nomor laporan & bulan ke di header_

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `no_laporan` | No. Laporan | bilangan bulat | header | Ya |
| 2 | `bulan` | Bulan | tanggal | header | Ya |
| 3 | `bulan_ke` | Bulan Ke | bilangan bulat | header | Ya |
| 4 | `no` | No. (I, II, …) | teks |  | Ya |
| 5 | `wbs_node` | Rincian Kegiatan (mengikuti SoW & BoQ kontrak) → node WBS | node WBS |  | Ya |
| 6 | `bobot_a` | Bobot Kegiatan (%) a | persen 0–100 |  | Ya |
| 7 | `rencana_kum_keg_b` | Akumulasi Rencana s/d Bulan ini – Kegiatan (%) b | persen 0–100 |  | Ya |
| 8 | `rencana_kum_tot_c` | Akumulasi Rencana – Total (%) c = a × b | persen 0–100 | dihitung | Ya |
| 9 | `prestasi_lalu_keg_d` | Prestasi s/d Bulan Lalu – Kegiatan (%) d | persen 0–100 |  | Ya |
| 10 | `prestasi_lalu_tot_e` | Prestasi s/d Bulan Lalu – Total (%) e = a × d | persen 0–100 | dihitung | Ya |
| 11 | `prestasi_ini_keg_f` | Prestasi Bulan Ini – Kegiatan (%) f | persen 0–100 |  | Ya |
| 12 | `prestasi_ini_tot_g` | Prestasi Bulan Ini – Total (%) g = a × f | persen 0–100 | dihitung | Ya |
| 13 | `prestasi_kum_keg_h` | Akumulasi Prestasi – Kegiatan (%) h = d + f | persen 0–100 | dihitung | Ya |
| 14 | `prestasi_kum_tot_i` | Akumulasi Prestasi – Total (%) i = e + g | persen 0–100 | dihitung | Ya |
| 15 | `deviasi_j` | Deviasi (%) j = i − c | persen 0–100 | dihitung | Ya |

### Tabel `lpms3_form.ffr708_kurva_s` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `wbs_node` | Rincian Kegiatan | node WBS |  | Ya |
| 2 | `bobot` | Bobot (%) | persen 0–100 |  | Ya |
| 3 | `tahun` | (Tahun) | bilangan bulat |  | Ya |
| 4 | `bulan_ke` | Bulan 1 … Bulan 12 | bilangan bulat |  | Ya |
| 5 | `rencana_pct` | Rencana (P) | persen 0–100 |  | Ya |
| 6 | `realisasi_pct` | Realisasi (A) | persen 0–100 |  | – |

### Tabel `lpms3_form.ffr708_permasalahan` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `rincian_permasalahan` | Rincian Permasalahan | teks panjang |  | Ya |
| 2 | `rencana` | Rencana | teks panjang |  | Ya |
| 3 | `realisasi` | Realisasi | teks panjang |  | – |
| 4 | `analisa_penyebab` | Analisa Penyebab (Man, Method, Material, Machine, Money, Environment) | daftar/terstruktur | 5M 1E | Ya |
| 5 | `tindakan_koreksi_pencegahan` | Tindakan Koreksi & Pencegahan (5M 1E) | daftar/terstruktur | 5M 1E | Ya |
| 6 | `pic` | PIC | pengguna |  | Ya |
| 7 | `due_date` | Due Date | tanggal |  | Ya |

### Tabel `lpms3_form.ffr708_pembukuan` (lines)

_diisi oleh Fungsi Akuntansi **)_

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `dibukukan_oleh` | Dibukukan Oleh | pengguna |  | Ya |
| 2 | `kode_perkiraan` | Kode Perkiraan | teks |  | Ya |
| 3 | `debet` | Debet | uang (Rp) |  | Ya |
| 4 | `kredit` | Kredit | uang (Rp) |  | Ya |
| 5 | `catatan` | Catatan | teks panjang |  | – |

## CFR-027 rev.00 — Ketidaksesuaian dan Tindakan Koreksi (Keluhan Pelanggan / Ketidaksesuaian SKU / Operasional)

- **Sumber template:** `form/CFR-027 Form Ketidaksesuaian dan Tindakan Koreksi rev.00.xls (identik QFR-017 di LKP Sigma)`
- **Fase:** Eksekusi & Monitoring  ·  **Prosedur:** QOG-001 §5.6.2–5.6.3, BOP-001 §5.3.4, §5.4.6
- **Pemilik/pengisi:** Unit pelapor; verifikasi Fungsi Penjaminan Mutu
- **Menu LPMS3:** PHASE › [Monitoring] › Quality Status / Issue Status
- **Pengesahan (tabel `form_signature`):** Verifikator (nama & ttd)

### Tabel `lpms3_form.cfr027_ketidaksesuaian` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `jenis` | Jenis (Keluhan Pelanggan / Ketidaksesuaian SKU / Operasional) | pilihan | Keluhan Pelanggan, Ketidaksesuaian SKU, Operasional | Ya |
| 2 | `tanggal_laporan` | Tanggal Laporan | tanggal |  | Ya |
| 3 | `pelapor_tipe` | Dilaporkan oleh – Unit Kerja/Pelanggan | pilihan | Unit kerja, Pelanggan | Ya |
| 4 | `pelapor_unit` | Dilaporkan oleh – Unit Kerja/Pelanggan (nama) | teks |  | Ya |
| 5 | `pelapor_nama` | Dilaporkan oleh – Nama Personil | teks |  | Ya |
| 6 | `penerima_unit` | Kepada/Diterima oleh – Unit Kerja | unit organisasi |  | Ya |
| 7 | `penerima_nama` | Kepada/Diterima oleh – Nama Personil | pengguna |  | Ya |
| 8 | `kategori` | Kategori Permasalahan | pilihan | Permasalahan operasional/proyek, Ketidaksesuaian pencapaian SKU, Keluhan Pelanggan, Keluhan pihak eksternal | Ya |
| 9 | `detail` | Detail Permasalahan | teks panjang |  | Ya |
| 10 | `analisa_penyebab` | Analisa Penyebab Masalah [Man/Material/Machine/Method/Environment] | teks panjang |  | Ya |
| 11 | `tindakan_koreksi` | Tindak Lanjut – Tindakan Koreksi | teks panjang |  | Ya |
| 12 | `tindakan_korektif` | Tindak Lanjut – Tindakan Korektif | teks panjang |  | Ya |
| 13 | `target_tanggal` | Target Tanggal Penyelesaian / Batas Waktu | tanggal |  | Ya |
| 14 | `penanggung_jawab` | Penanggung Jawab | pengguna |  | Ya |
| 15 | `status` | Status (OK / On Progress / Not OK) | pilihan | OK, On Progress, Not OK | Ya |
| 16 | `realisasi_tanggal` | Realisasi Tanggal Penyelesaian | tanggal |  | – |
| 17 | `verifikasi` | Verifikasi Tindak Lanjut (Belum Efektif / Sudah Efektif) | pilihan | Belum Efektif, Sudah Efektif | – |
| 18 | `tanggal_verifikasi` | Tanggal Verifikasi | tanggal |  | – |
| 19 | `verifikator` | Verifikator (nama & ttd) | pengguna |  | – |
| 20 | `keterangan` | Keterangan | teks panjang |  | – |

## PFR-037 rev.00 — Pengajuan Proposal Pengadaan Barang/Jasa PMN

- **Sumber template:** `procedure/PFR-037 Formulir Pengajuan Proposal Pengadaan PMN rev.00.xlsx`
- **Fase:** Perencanaan → Eksekusi (pengadaan PMN)  ·  **Prosedur:** POP-109
- **Pemilik/pengisi:** Project Manager (pengaju)
- **Menu LPMS3:** PHASE › [Monitoring] › Procurement Pipeline › Pra Procurement up to PR (jenis PMN)
- **Pengesahan (tabel `form_signature`):** Diajukan: Project Manager; Diketahui: Fungsi Pelaksanaan PMN; Diperiksa: Fungsi Pengawasan PMN & Fungsi Perencanaan PMN; Disetujui: Program Executive Director

### Tabel `lpms3_form.pfr037_header` (header)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `nomor` | Nomor | teks |  | Ya |
| 2 | `tempat_tanggal` | Bandung, DD-MM-YYYY | tanggal |  | Ya |

### Tabel `lpms3_form.pfr037_item` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `alokasi_mata_anggaran` | Alokasi Mata Anggaran | teks |  | Ya |
| 2 | `deskripsi` | Deskripsi Barang/Jasa | teks panjang |  | Ya |
| 3 | `jumlah` | Jumlah | angka |  | Ya |
| 4 | `satuan` | Satuan | teks |  | Ya |
| 5 | `rencana_kebutuhan` | Rencana Kebutuhan PMN | uang (Rp) |  | Ya |
| 6 | `keterangan` | Keterangan | teks panjang |  | – |

## FFR-710 rev.02 — Laporan Dokumentasi Proyek (Daftar Isi Kelengkapan Dokumen + Tabel Realisasi)

- **Sumber template:** `form/FFR-710 Formulir Laporan Dokumentasi Proyek rev.02.xlsx (rev.01 juga tersedia)`
- **Fase:** Seluruh fase; wajib lengkap saat Closing  ·  **Prosedur:** BOP-001 §5.5.4, FOP-705, COP-002
- **Pemilik/pengisi:** Pimpro & Tim Proyek; Es.II/Es.I Fungsi Manajemen Proyek
- **Menu LPMS3:** Dokumen proyek (folder WBS) & PHASE › [Closing] › Pendokumentasian Arsip
- **Pengesahan (tabel `form_signature`):** Dibuat: Pimpinan Proyek/Program; Diperiksa: Es.II Fungsi Manajemen Proyek; Disetujui: Es.I Fungsi Manajemen Proyek

### Tabel `lpms3_form.ffr710_header` (header)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `unit_bisnis` | Unit Bisnis | unit organisasi |  | Ya |
| 2 | `account_manager` | Account Manager | pengguna |  | Ya |
| 3 | `nama_proyek` | Nama Proyek/Program | teks |  | Ya |
| 4 | `pimpinan_proyek` | Pimpinan Proyek/Program | pengguna |  | Ya |
| 5 | `kode_sap` | Kode Proyek/Program (Kode SAP) | teks |  | Ya |
| 6 | `nilai_kontrak_netto` | Nilai Kontrak (Netto) | uang (Rp) |  | Ya |
| 7 | `jadwal` | Jadwal Proyek/Program | teks |  | Ya |

### Tabel `lpms3_form.ffr710_daftar_isi` (checklist)

_±200 butir dalam 5 bagian A–E + bagian Pelaksanaan & Penutupan; dimuat sebagai master taksonomi dokumen_

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `bagian` | Bagian | pilihan | A. Pemasaran Proyek, B. Perencanaan & Pelaksanaan Proyek (Teknis), C. Pelaksanaan Proyek (Pengadaan), D. Pelaksanaan Proyek (Keuangan), E. Penutupan Proyek | Ya |
| 2 | `no` | No. | teks | 1, 2, … / a, b, … | Ya |
| 3 | `uraian` | Uraian | teks |  | Ya |
| 4 | `ada_tanggal` | Checklist Kelengkapan – Ada (Tanggal) | tanggal |  | – |
| 5 | `tidak_ada` | Checklist – Tidak Ada | ya/tidak |  | – |
| 6 | `pj_nama` | Penanggungjawab – Nama | pengguna |  | – |
| 7 | `pj_bagian` | Penanggungjawab – Bagian | fungsi |  | – |
| 8 | `keterangan` | Keterangan (Dokumen Pembukaan / Penutupan Kode Proyek / Jika ada) | teks |  | – |
| 9 | `dokumen` | Berkas (tautan ke repositori dokumen) | berkas |  | – |

### Tabel `lpms3_form.ffr710_c1_pengadaan` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `tanggal` | Tanggal | tanggal |  | Ya |
| 2 | `no_dpbj` | No DPB/J | teks |  | Ya |
| 3 | `nilai_dpbj` | Nilai DPB/J (Rp) | uang (Rp) |  | Ya |
| 4 | `no_spph` | No SPPH | teks |  | – |
| 5 | `no_po` | No PO | teks |  | – |
| 6 | `nilai_po` | Nilai PO (Rp) | uang (Rp) |  | – |
| 7 | `supplier` | Supplier | teks |  | – |
| 8 | `barang_tiba` | Barang Tiba/ Progres Pekerjaan | pilihan | Merah, Hijau, Kuning | – |
| 9 | `status_kedatangan` | Status Kedatangan Barang/ Progres Pekerjaan | pilihan | Belum, Parsial Bertahap, Parsial Termin 1, Parsial Termin 2, Parsial Termin 3, Parsial Termin 4, Parsial Termin 5, Lengkap, Tepat Waktu, Lengkap, Terlambat, Wanprestasi, Batal | – |
| 10 | `no_bapbj` | No BAPB/J (Internal) | teks |  | – |
| 11 | `kelengkapan_bast_subkon` | Kelengkapan BAST Subkontrak (Eksternal) | pilihan | Ada, Tidak | – |
| 12 | `keterangan` | Keterangan | teks panjang |  | – |

### Tabel `lpms3_form.ffr710_c2_persediaan` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `kode_barang` | Kode Barang (header) | teks |  | Ya |
| 2 | `nama_barang` | Nama Barang (header) | teks |  | Ya |
| 3 | `lokasi_barang` | Lokasi Barang (header) | teks |  | Ya |
| 4 | `satuan` | Satuan (header) | teks |  | Ya |
| 5 | `pj_gudang` | Penanggung Jawab Gudang (header) | pengguna |  | Ya |
| 6 | `tanggal` | Tanggal | tanggal |  | Ya |
| 7 | `no_po` | PO Pembelian (Subkontrak) – No PO | teks |  | – |
| 8 | `nilai_po` | PO – Nilai (Rp) | uang (Rp) |  | – |
| 9 | `qty_po` | PO – Kuantitas | angka |  | – |
| 10 | `qty_bapb` | BAPB – Kuantitas | angka |  | – |
| 11 | `tanggal_bast` | Tanggal (BAST) | tanggal |  | – |
| 12 | `no_bast` | BAST Pemberi Kerja – No BAST | teks |  | – |
| 13 | `nilai_bast` | BAST – Nilai (Rp) | uang (Rp) |  | – |
| 14 | `qty_bast` | BAST – Kuantitas | angka |  | – |
| 15 | `sisa` | Sisa persediaan (kolom lanjutan) | angka | dihitung | – |

### Tabel `lpms3_form.ffr710_d1_anggaran` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `periode_ke` | Periode ke-n (Bulan ke-n) | bilangan bulat |  | Ya |
| 2 | `jenis_anggaran` | Total Anggaran – Jenis Anggaran (Beban Rutin, Beban Perjalanan Dinas, …) | teks |  | Ya |
| 3 | `nilai_anggaran` | Total Anggaran – Nilai (Rp) | uang (Rp) |  | Ya |
| 4 | `nilai_penyerapan` | Total Penyerapan – Nilai (Rp) | uang (Rp) |  | Ya |
| 5 | `pct_penyerapan` | Total Penyerapan – % | persen 0–100 | dihitung | Ya |
| 6 | `pct_progres_lkp` | % Progres – LKP | persen 0–100 | dari LKP | Ya |
| 7 | `pct_progres_kurva_s` | % Progres – Kurva-S | persen 0–100 | dari baseline | Ya |

### Tabel `lpms3_form.ffr710_d2_d4_d7_beban` (lines)

_dipakai untuk D2 Beban SPD, D3 UM Swakelola, D4 Beban Lain-lain, D7a Beban Pemasaran (kolom jenis_tabel)_

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `jenis_tabel` | Jenis tabel | pilihan | D2 Beban SPD, D3 UM Swakelola, D4 Beban Lain-lain, D7a Beban Pemasaran | Ya |
| 2 | `tanggal` | Tanggal | tanggal |  | Ya |
| 3 | `no_bukti` | No Bukti | teks |  | Ya |
| 4 | `uraian` | Uraian | teks panjang |  | Ya |
| 5 | `saldo` | Saldo | uang (Rp) |  | Ya |
| 6 | `nama` | Nama | teks |  | Ya |
| 7 | `jenis_kegiatan_marketing` | Jenis Kegiatan Marketing (D7a) | teks |  | – |
| 8 | `status` | Status (pilih) | pilihan | Lumpsum, Sudah Ptjwb, Belum Ptjwb | Ya |
| 9 | `ptjwb_saldo_kurang` | Pertanggungjawaban (Rp) – Saldo Kurang | uang (Rp) |  | – |
| 10 | `ptjwb_saldo_lebih` | Pertanggungjawaban (Rp) – Saldo Lebih | uang (Rp) |  | – |
| 11 | `keterangan` | Keterangan (pilih) | pilihan | Belum Diterima, Saldo lebih sudah dikembalikan, Saldo lebih belum dikembalikan, Saldo kurang sudah dibayar, Saldo kurang belum dibayar | – |

### Tabel `lpms3_form.ffr710_d5a_pendapatan` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `tanggal` | Tanggal | tanggal |  | Ya |
| 2 | `termin` | Termin | teks |  | Ya |
| 3 | `progres_lkp_pct` | Progres LKP Approval – % | persen 0–100 | dari LKP published | Ya |
| 4 | `progres_lkp_nilai` | Progres LKP Approval – Nilai (Rp) | uang (Rp) |  | Ya |
| 5 | `invoice_pct` | Invoice – % | persen 0–100 |  | – |
| 6 | `invoice_nilai` | Invoice – Nilai (Rp) | uang (Rp) |  | – |
| 7 | `nilai_penerimaan` | Nilai Penerimaan Pendapatan (Rp) | uang (Rp) |  | – |
| 8 | `tagihan_bruto` | Tagihan Bruto (Rp) | uang (Rp) | dihitung | – |
| 9 | `piutang_usaha` | Piutang Usaha (Rp) | uang (Rp) | dihitung | – |

### Tabel `lpms3_form.ffr710_d5c_penjualan_retail` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `tanggal` | Tanggal | tanggal |  | Ya |
| 2 | `no_po` | No PO | teks |  | Ya |
| 3 | `no_transfer_load` | No Transfer Load | teks |  | – |
| 4 | `no_ppbj` | No PPBJ | teks |  | – |
| 5 | `uraian` | Uraian | teks panjang |  | Ya |
| 6 | `nilai` | Nilai (Rp) | uang (Rp) |  | Ya |
| 7 | `customer` | Customer | teks |  | Ya |
| 8 | `no_bpbj` | No BPBJ | teks |  | – |
| 9 | `status_penerimaan_barang` | Status Penerimaan Barang | pilihan | Belum Dikirim, Sudah Diterima, Batal | Ya |
| 10 | `status_pembayaran` | Status Pembayaran | pilihan | Belum Dibayar, Sudah Dibayar, Batal | Ya |
| 11 | `keterangan` | Keterangan | teks panjang |  | – |

## WFR-014 rev.03 — Berita Acara Serah Terima Pekerjaan / Pemeliharaan (BAST)

- **Sumber template:** `form/WFR-014 ... rev.03_20031205.xls`
- **Fase:** Eksekusi (serah terima deliverable) & Closing  ·  **Prosedur:** FOP-705, BOP-001 §5.3.1
- **Pemilik/pengisi:** Pimpinan Proyek
- **Menu LPMS3:** PHASE › [Eksekusi] ringkasan (Deliverable diterima) & [Closing]
- **Pengesahan (tabel `form_signature`):** PIHAK PERTAMA (menyerahkan): Nama, Jabatan, Instansi, NIK; PIHAK KEDUA (menerima): Nama, Jabatan, Instansi

### Tabel `lpms3_form.wfr014_bast` (header)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `jenis` | Serah Terima Pekerjaan / Pemeliharaan | pilihan | Pekerjaan, Pemeliharaan | Ya |
| 2 | `nama_proyek` | Nama Proyek / Program | teks |  | Ya |
| 3 | `lokasi` | Lokasi | teks |  | Ya |
| 4 | `no_kontrak` | No. Kontrak | teks |  | Ya |
| 5 | `nilai_kontrak` | Nilai Kontrak | uang (Rp) |  | Ya |
| 6 | `jadwal_pelaksanaan` | Jadwal Pelaksanaan | teks |  | Ya |
| 7 | `tanggal_bast` | Pada hari ini … tanggal … bulan … tahun | tanggal |  | Ya |
| 8 | `tempat` | Tempat | teks |  | Ya |
| 9 | `pihak1_nama` | PIHAK PERTAMA – Nama | teks |  | Ya |
| 10 | `pihak1_jabatan` | PIHAK PERTAMA – Jabatan | teks |  | Ya |
| 11 | `pihak1_instansi` | PIHAK PERTAMA – Instansi | teks |  | Ya |
| 12 | `pihak2_nama` | PIHAK KEDUA – Nama | teks |  | Ya |
| 13 | `pihak2_jabatan` | PIHAK KEDUA – Jabatan | teks |  | Ya |
| 14 | `pihak2_instansi` | PIHAK KEDUA – Instansi | teks |  | Ya |
| 15 | `bobot_pct` | bobot pekerjaan/pemeliharaan sebesar …% | persen 0–100 |  | Ya |
| 16 | `nilai_rp` | dengan nilai Rp … | uang (Rp) |  | Ya |
| 17 | `wbs_deliverable` | Deliverable/WBS yang diserahterimakan | daftar/terstruktur | relasi node WBS | Ya |
| 18 | `distribusi` | Lembar ke: Pimpro (asli), Bag. Keuangan, Bag. … | daftar/terstruktur |  | Ya |

## WFR-010 rev.03 — Bukti Pengembalian Bahan Sisa Proyek/Sisa Produksi

- **Sumber template:** `form/WFR-010 ... rev.03_20031205.xls`
- **Fase:** Closing  ·  **Prosedur:** FOP-705, WOP-207
- **Pemilik/pengisi:** Pimpro / Bag. Rekayasa / Bag. Produksi; Fungsi Akuntansi; Gudang
- **Menu LPMS3:** PHASE › [Closing] langkah Arsip & Persediaan
- **Pengesahan (tabel `form_signature`):** Diserahkan: Pimpro / Bag. Manaj.&Rek. Proyek / Bag. Produksi; Diperiksa: Pemeriksa Kualitas; Diketahui: Ka. UB / Kabag. Produksi; Diterima: Kabag. Gudang

### Tabel `lpms3_form.wfr010_header` (header)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `nomor` | No. | teks |  | Ya |
| 2 | `nama_proyek` | Nama Proyek/Program | teks |  | Ya |
| 3 | `kode_proyek` | Kode Proyek/Program | teks |  | Ya |
| 4 | `no_penerimaan_gudang` | No. Penerimaan Gudang | teks |  | Ya |
| 5 | `tanggal` | Bandung, … | tanggal |  | Ya |
| 6 | `total_rp` | Jumlah Rp. | uang (Rp) | dihitung | Ya |

### Tabel `lpms3_form.wfr010_item` (lines)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `kode_barang` | Kode Barang | teks |  | Ya |
| 2 | `nama_barang` | Nama Barang | teks |  | Ya |
| 3 | `satuan` | Satuan | teks |  | Ya |
| 4 | `jumlah` | Jumlah | angka |  | Ya |
| 5 | `harga_satuan` | Harga Satuan (Fungsi Akuntansi) | uang (Rp) |  | – |
| 6 | `jumlah_harga` | Jumlah Harga | uang (Rp) | dihitung | – |
| 7 | `kode_rek` | Kode Rek. | teks |  | – |
| 8 | `debet` | Debet | uang (Rp) |  | – |
| 9 | `kredit` | Kredit | uang (Rp) |  | – |
| 10 | `kondisi_baik` | Bahan – Baik | angka |  | – |
| 11 | `kondisi_reject` | Bahan – Reject | angka |  | – |
| 12 | `masih_diperlukan` | Keterangan – Masih diperlukan | ya/tidak |  | – |
| 13 | `tidak_diperlukan` | Keterangan – Tidak diperlukan | ya/tidak |  | – |

## WFR-028 rev.02 — Berita Acara Pemeriksaan Fisik Persediaan (Stock Opname)

- **Sumber template:** `form/WFR-028 ... rev02_20030605.docx`
- **Fase:** Eksekusi (bulanan) & Closing  ·  **Prosedur:** FOP-705, WOP-207
- **Pemilik/pengisi:** Penanggungjawab Gudang & Pimpro
- **Menu LPMS3:** PHASE › [Monitoring] (laporan persediaan bulanan) & [Closing]
- **Pengesahan (tabel `form_signature`):** Membuat: Penanggungjawab Gudang, Pimpinan Proyek/Program; Menyetujui: Manager PPO Gudang / Manajemen Proyek; Mengetahui: VP Logistik / GM Unit Bisnis

### Tabel `lpms3_form.wfr028_stock_opname` (header)

| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `tanggal_pemeriksaan` | Pada hari ini … tanggal … bulan … tahun | tanggal |  | Ya |
| 2 | `metode` | Metode pemeriksaan | pilihan | Perhitungan keseluruhan, Sampling | Ya |
| 3 | `metode_uraian` | Uraian metode (dasar sampling) | teks panjang |  | Ya |
| 4 | `lokasi_jenis` | Pemeriksaan berdasarkan | pilihan | Gudang Len, Gudang Proyek/Program | Ya |
| 5 | `lokasi_uraian` | Gudang Len – uraian | teks panjang |  | – |
| 6 | `gudang_kode` | Gudang Proyek – Kode | teks |  | – |
| 7 | `gudang_nama` | Gudang Proyek – Nama | teks |  | – |
| 8 | `gudang_jadwal` | Gudang Proyek – Jadwal | teks |  | – |
| 9 | `cakupan` | Meliputi material on stock (milik Len) & on site (milik bowheer) | daftar/terstruktur |  | Ya |
| 10 | `hasil_pemeriksaan` | Hasil Pemeriksaan Persediaan | teks panjang |  | Ya |
| 11 | `lampiran_laporan` | Laporan terlampir | berkas |  | Ya |

## WBS-LPMS — WBS Template LPMS

Tabel ini menjadi **struktur wajib** pengisian WBS, dasar folder bukti (Evidence Files), dan dasar Kurva-S. Skema: `db/020_lpms3_wbs.sql`.

| # | Kolom DB | Kolom template | Tipe | Pilihan / aturan | Wajib |
|---|---|---|---|---|---|
| 1 | `wbs_code` | WBS | teks | 0, 1, 1.1, 1.1.1 … (Settings!A) | Ya |
| 2 | `level` | Level | pilihan | Level 0, Level 1, Level 2, Level 3, Level 4, Level 5 Activity, Level 6, Level 6 Activity, Level 7, Level 7 Activity | Ya |
| 3 | `tasks` | Tasks | teks |  | Ya |
| 4 | `notes` | Notes | teks panjang | mis. 'Daftar Checklist Survey' | – |
| 5 | `resource` | Resource | pilihan | Pimpro, Engineer, Admin, Vendor, Keuangan, Pengadaan, Sponsor, Eselon 1, Eselon 2, Staff, K3LH, Kualitas, Pengawas, Developer, Direksi, Perencanaan, Pemasaran, End User, Lainnya, Unknown, Deputi Pimpro, Risiko, Innovation, Auditor, Sub-Vendor, Konsultan, Mekanikal, Elektrikal, Plumbing, Sipil, Perangkat Lunak, Perangkat Keras, Jaringan, Bowheer | – |
| 6 | `date_plan_start` | Date Plan Start | tanggal |  | Ya |
| 7 | `date_plan_finish` | Date Plan Finish | tanggal |  | Ya |
| 8 | `date_actual_start` | Date Actual Start | tanggal |  | – |
| 9 | `date_actual_finish` | Date Actual Finish | tanggal |  | – |
| 10 | `weigh_factor` | Weigh Factor | persen 0–100 | porsi terhadap induk; Σ saudara = 100% | Ya |
| 11 | `weight` | Weight | persen 0–100 | = Weight induk × Weigh Factor (Level 0 = 100%) | Ya |
| 12 | `pct_complete` | % Complete | pilihan | 0%, 25%, 50%, 75%, 100% | Ya |
| 13 | `pct_progress` | % Progress | persen 0–100 | = Weight × % Complete (diagregasi ke induk) | Ya |
| 14 | `priority` | Priority | pilihan | Low, Medium, High | – |
| 15 | `evidence_files` | Evidence Files | berkas | folder bukti per node WBS | – |

## Tabel di dalam Prosedur (SOP) yang diakomodasi

| Prosedur | Tabel | Struktur kolom | Tabel LPMS3 | Pemakaian |
|---|---|---|---|---|
| CLP-001 | Nomenklatur Fungsi Generik | No | Unit Generik | Definisi (35 fungsi) | ref_fungsi_generik | Master Fungsi (§14) |
| FOP-700 | Jenis Kode | No | Jenis Kode | Pemilik Kode | Tujuan | Output | Dasar Pengajuan Dokumen (14 jenis) | ref_jenis_kode | Jenis proyek/program; menentukan checklist FLP-01 & template |
| FLP-01 | Matriks persyaratan dokumen | 42 dokumen × 14 jenis kode | flp01_master_persyaratan | Checklist pembukaan kode |
| SOP-004 | Kelas Kontrak | No | Nilai Kontrak | Kelas Kontrak | Tinjauan Kontrak Go (<25 M Kecil; 25–100 M Sedang; >100 M Besar) | ref_kelas_kontrak | Kelas tinjauan & penanda tangan SFR-028 |
| SOP-004 | Peserta Tinjauan Kontrak (Teknis, Costing, Go sedang, Go besar) | No | Peran | Peserta | ref_peserta_rapat | Template undangan rapat |
| SOP-004 / SOP-009 | Akses Informasi per Fungsi | No | Fungsi | Kebutuhan | Lingkup Akses Informasi (Copy Value / HPS / Kelas Proyek / Akses Penuh) | ref_akses_informasi | Kapabilitas tingkat field (§14) |
| SOP-009 | Peserta Tinjauan Adendum (kelas biasa & Direksi) | No | Peran | Peserta | ref_peserta_rapat | Template rapat adendum |
| BOG-003 | Matriks Pergeseran Anggaran | No | Nominal | Mengajukan | Menyetujui | SLA | Keterangan (≤200 jt ES II 1 hari; 200–500 jt ES I & II 2 hari; >500 jt Direksi 3 hari) | ref_matriks_kewenangan | Approval Top-Up/Pergeseran |
| BOG-003 | Peserta Rapat Tinjauan ABT | No | Peran | Peserta | ref_peserta_rapat | Template rapat ABT |
| BFR-001 | Ambang persetujuan Change Request | < Rp1 M Es.II; ≥ Rp1 M Es.I (Manajemen Proyek & Pengawasan Proyek) | ref_matriks_kewenangan | Approval CR |
| ROP-911 | Skala & Level Risiko | Skor 1–25 → Rendah, Rendah-Menengah, Menengah, Menengah-Tinggi, Tinggi + tindakan | ref_level_risiko | Peta panas & aturan eskalasi |
| ROP-911 | Kriteria Dampak & Kemungkinan | Parameter × (Sangat Rendah … Sangat Tinggi) ; Kemungkinan 1–5 | ref_kriteria_risiko | Bantuan penilaian RFR-002 |
| BOP-001 | RASCI Tabel 1–6 & Peserta Kick-Off / Rapat Tinjauan (Tabel 2, 4) | No | Aktivitas | A | R | S | C | I | ref_rasci | RASCI per aktivitas & template rapat |
| FFR-710 | Daftar Isi Kelengkapan Dokumen Proyek | Bagian A–E | ffr710_daftar_isi | Taksonomi folder dokumen |
| COP-002 | Jenis dokumen & pengesahan; masa retensi rekaman | No | Jenis Dokumen | Disiapkan | Disetujui | Disahkan | ref_retensi | Aturan arsip & retensi |
| WOP-207 | Alur barang persediaan proyek | Unit Pengadaan | Gudang Proyek | QC | Manajemen Proyek | Pengelola Gudang | Site Manager | Rendal | Pimpro | proses | Alur stok proyek (WFR-002/004/035/037/038) |

## Formulir yang dirujuk prosedur tetapi templatenya belum ada di folder

Ditangani sebagai **dokumen terstruktur generik** (`form_instance` + metadata + lampiran + tanda tangan) dan diberi slot di checklist FLP-01/FFR-710. Begitu template diserahkan, kolomnya ditambahkan ke `spec_forms.py` dan DDL dibangkitkan ulang (tanpa mengubah alur).

- **Inisiasi:** SFR-003 Tinjauan Order – Teknis; SFR-020 Tinjauan Order – Costing; SFR-024 Persetujuan Order/Kontrak Kecil; SFR-026 Analisa Kelayakan Bisnis; SFR-027 Analisa Kelayakan Proyek; SFR-030 Analisis Kelayakan Order (AKO); SFR-031 Komite Persetujuan Order Sedang_Besar; SFR-006 Tinjauan Kontrak – Teknis; SFR-021 Tinjauan Kontrak – Costing / Daftar Hadir; SFR-022 Matriks Penentuan Kelas Proyek & Pimpro; SFR-016 Uji Kelayakan SMAP Transaksi/Proyek; FFR-042 Persyaratan Dokumen Pengajuan Pembukaan Kode; FFR-714 Rencana Cash Flow; FFR-716 Rincian Anggaran Swakelola; FFR-721 Rincian Anggaran Proyek; RFR-006 Program Risk Register; HFR-073 Wawancara & Rekomendasi Calon Pimpro; HFR-075 Pengesahan Calon Pimpro; HFR-023 Uji Kelayakan SMAP Personel; SFR-004 Kesepakatan Transfer Load; SFR-017 Hasil Tinjauan Transfer Load
- **Perencanaan:** Quality Plan (QOG-002); HSE Plan (template HSE Plan); PFR-034 Procurement Plan; FFR-717 (BOG-003)
- **Eksekusi & Monitoring:** FFR-709 Monitoring Pelaksanaan Proyek/Program; SFR-025 Tinjauan Adendum Kontrak; PFR-001 Data Calon Rekanan; PFR-003 Purchase Requisition (DPB/J); PFR-007 SPPH; PFR-009 Berita Acara Negosiasi; PFR-010 Purchase Order; PFR-011 Surat Perintah Kerja; PFR-014 Penilaian Calon Rekanan; PFR-016 Persetujuan Kenaikan Harga; PFR-017 Perubahan HPS; PFR-018 Persetujuan Penunjukan Langsung; PFR-019 Evaluasi Penyedia; PFR-020 BA Evaluasi Penawaran; PFR-021 Monitoring Pelaksanaan Kontrak Pengadaan Barang; PFR-023 Penetapan HPS; PFR-026 Pengumuman Pemenang; PFR-030 Daftar Hitam Penyedia; WFR-002 BA Penerimaan Barang/Jasa; WFR-004 Bukti Pengeluaran Barang; WFR-035 Permintaan Pengeluaran Barang; WFR-037 History Barang Persediaan; WFR-038 Rekapitulasi Barang Persediaan; WCR-001 Kartu Barang; MFR-001 Incoming Inspection; QFR-026/027/028/038 Kalibrasi & Alat Ukur; SFR-005 Umpan Balik Keluhan Pelanggan; SFR-007 Kuesioner Kepuasan Pelanggan; VFR-020 Evaluasi Pemenuhan Perundang-undangan K3L; VFR-055 Aspek-Dampak & Bahaya (form baru); VFR-044/051 Ijin Kerja; VFR-058 Pengendalian Perancangan/Perubahan; HFR-074 Evaluasi Kinerja Pimpro
- **Closing:** FFR-713 Tinjauan Penutupan Proyek/Program; FLP-03 Syarat Dokumen Pengajuan Penutupan Kode; FFR-722 (FOP-705); Laporan Akhir Proyek/Program; Realisasi Penyerapan Pagu Anggaran; Laporan Laba/(Rugi) Proyek

