# LPMS3 — MASTER PLAN v2.0
## Len Project Management System 3 · BOP-001 Manajemen Proyek dari Inisiasi sampai Closing
### Deploy bersih di VM Ubuntu `192.168.125.14:5100` · Database utama StarRocks `default_catalog.lpms3`

| Item | Nilai |
|---|---|
| Dokumen | PLAN-LPMS3-MASTER v2.0 (menggantikan v1.3; v1.3 dipertahankan sebagai Buku Teknis — `10_Spesifikasi_Teknis_v1.3.md`) |
| Tanggal | 9 November 2026 |
| Penyusun | Andre Tigana (dibantu Claude) |
| Repo | `https://github.com/andretiganalen/lpms3-v2` (folder kerja `C:\Projects\lpms3-v2`) |
| Acuan wajib | **BOP-001 rev.01** + seluruh formulir & prosedur di `docs/template-bop001/` (26 berkas formulir, 52 berkas prosedur) + **WBS Template LPMS** (`docs/wbs/WBS_Template_LPMS.xlsx`) + PMBOK 7th/8th |
| Lampiran | `01_Katalog_Form_SOP.md` · `02_Kamus_Data_Formulir_dan_SOP.md` (509 kolom) · `docs/data-dictionary/LPMS3_Data_Dictionary.xlsx` · `db/*.sql` · `db/starrocks/*.sql` · `10_Spesifikasi_Teknis_v1.3.md` |

---

## 0. TUJUAN UTAMA (TIDAK BOLEH MELESET)

LPMS3 dibangun untuk **menjalankan BOP-001 secara utuh di dalam satu aplikasi** — bukan sekadar mencatat. Ukuran keberhasilannya adalah tujuan BOP-001 §1.0 itu sendiri:

> "…membangun *operational excellence* dalam pengelolaan Proyek, sehingga Proyek dapat berjalan dan diselesaikan sesuai dengan rencana … memenuhi sasaran dalam semua aspek yang disyaratkan termasuk aspek kualitas, anggaran, jadwal, keselamatan dan kesehatan kerja dan lingkungan."

Karena itu setiap fitur di plan ini harus menjawab salah satu dari tujuh janji berikut (dipakai sebagai *checklist* saat review desain dan UAT):

| # | Janji LPMS3 terhadap BOP-001 | Bukti di sistem |
|---|---|---|
| J1 | **Lima tahap BOP-001** (Inisiasi, Perencanaan, Eksekusi, Pengawasan & Pengendalian, Penutupan) dijalankan berurutan dengan **gate** yang dapat diaudit | Fase & Gate G1–G4, alur §5 |
| J2 | **Setiap formulir & prosedur pendukung** diisi di aplikasi dengan **tabel dan kolom yang sama** dengan template resmi, dan dapat dicetak kembali dalam format resmi | 18 formulir, 43 tabel, 509 kolom (§6, Lampiran 02) |
| J3 | **WBS Template LPMS** menjadi satu-satunya cara mengisi WBS, **folder bukti**, dan **dasar Kurva-S** & bobot LKP | §3 |
| J4 | **RASCI** BOP-001 (Tabel 1–6) dan peserta rapat (Tabel 2, 4) berlaku otomatis per proyek | §7, `ref_rasci`, `ref_peserta_rapat` |
| J5 | **Integrated Change Control** (BFR-001, CCM, BOG-003, SOP-009) — tidak ada perubahan scope/jadwal/biaya/Kurva-S tanpa jejak & persetujuan sesuai matriks kewenangan | §5.4, `ref_matriks_kewenangan` |
| J6 | **Pengawasan berkelanjutan**: LKP bulanan (FFR-708) ≤ tgl 5, rapat tinjauan, risiko, mutu, K3L, pengadaan, stakeholder — data naik berjenjang Admin Teknis → Direksi | §5.5, §8 |
| J7 | **Penutupan** sesuai FOP-705: LKP 100 %, BAST, sisa bahan, stock opname, realisasi pagu, L/R, arsip FFR-710 lengkap, purnajual | §5.6 |

---

## 1. KEPUTUSAN KUNCI v2.0

| # | Keputusan | Isi |
|---|---|---|
| K1 | Platform aplikasi | OpenProject Community (branch `stable/17`, image dipin) + plugin **`openproject-lpms3`** (sidebar, halaman fase, formulir, WBS, Kurva-S, approval) + layanan **`lpms3-data`** (Python: ETL LKP, sinkron StarRocks, render PDF) |
| K2 | URL | `http://192.168.125.14:5100` (TLS internal menyusul) |
| K3 | **Database utama** | **StarRocks `default_catalog.lpms3`** di `192.168.125.29:9030` (JDBC `jdbc:mysql://192.168.125.29:9030/lpms3`; driver StarRocks/MySQL) — seluruh data domain LPMS3 (formulir, WBS, Kurva-S, LKP, mart, BI) |
| K4 | Database runtime OpenProject | **PostgreSQL** (wajib; OpenProject tidak dapat berjalan di StarRocks). PG menjadi *system of entry* transaksional; setiap perubahan **disinkron ke StarRocks ≤ 1 menit** lewat outbox |
| K5 | Kredensial StarRocks | `root` hanya untuk inisialisasi oleh admin saat deployment; aplikasi memakai `lpms3_app`, ETL `lpms3_etl`, BI `lpms3_bi`. Password **hanya di `.env` VM / vault**, tidak pernah di Git |
| K6 | WBS | **WBS Template LPMS** wajib: Level 0–7 (+ Activity), Weigh Factor relatif terhadap induk, Weight berantai, % Complete diskrit 0/25/50/75/100, Evidence Files per node → folder bukti |
| K7 | Formulir | Dibangun dari **kamus data** (`spec_forms.py`) → DDL PG + DDL StarRocks + layar + PDF; formulir yang templatenya belum ada di folder ditangani sebagai dokumen terstruktur generik (§6.4) |
| K8 | Pusat pengguna | **Fungsi Manajemen Proyek** (Pimpro, Admin Teknis, Tim — disebut "Fungsi Pelaksanaan Proyek" di BOP-001) dan **Fungsi Pengawasan Proyek** + **Fungsi Perencanaan Proyek** (CLP-001 no. 5, 7, 8) |
| K9 | Struktur organisasi | Fungsi Generik CLP-001 (35 fungsi) → Unit Aktual (SKEP.HC/DU/I/2026, Nota 021) berversi → kapabilitas user |
| K10 | Implementasi DB | Skrip `db/*.sql` dan `db/starrocks/*.sql` dijalankan **saat deployment di VM Ubuntu** (runbook §11) |

> **Koreksi terhadap v1.3:** (a) CLP-001 tidak memuat "Fungsi Pelaksanaan Proyek"; padanannya adalah **Fungsi Manajemen Proyek** (FFR-708 rev.09, BFR-001, BOG-003, SOP-009 sudah memakai istilah ini). Kapabilitas & approver memakai kode `F-MPR`, alias BOP-001 dicatat di `fungsi_generik.bop_alias`. (b) `lpms3_dw` di PostgreSQL diganti StarRocks `default_catalog.lpms3`. (c) Skala risiko mengikuti ROP-911: skor 1–25 → Rendah, Rendah-Menengah, Menengah, Menengah-Tinggi, Tinggi.

---

## 2. ARSITEKTUR

```
 Pengguna (browser, LAN Len) ──http://192.168.125.14:5100──┐
                                                             ▼
┌──────────────────────── VM Ubuntu 24.04 · 192.168.125.14 (Docker Compose "lpms3") ────────────────────────┐
│ proxy(Caddy:80→5100) → web (OpenProject 17 + plugin openproject-lpms3) ── worker ── cron ── hocuspocus     │
│                              │ ActiveRecord                      │                                         │
│                              ▼                                   ▼                                         │
│                   PostgreSQL 17 (db, internal)          lpms3-data (Python, internal, tanpa port publik)   │
│                   ├─ public.*  (OpenProject)            ├─ /extract  ETL LKP multi-format (§8)             │
│                   ├─ lpms3.*   (org, WBS, baseline,      ├─ /render   PDF format resmi formulir           │
│                   │            kapabilitas, outbox)      ├─ sync worker: outbox → StarRocks (≤ 1 menit)    │
│                   └─ lpms3_form.* (18 formulir)          └─ rekonsiliasi harian jumlah baris PG vs SR      │
│  Volume: /srv/lpms3/{pgdata,opdata,lkp-raw,backup}                                                         │
└──────────────────────────────────────────────┬──────────────────────────────────────────────────────────┘
                                               │ MySQL protocol 9030 (firewall: hanya dari .14)
                                               ▼
                        StarRocks 192.168.125.29 · default_catalog.lpms3  (DATABASE UTAMA LPMS3)
                        ├─ form_*            mirror 43 tabel formulir + form_instance/signature/attachment
                        ├─ org_*, fungsi_*, project*, wbs_*, baseline*, scurve_plan  (mirror PG)
                        ├─ lkp_*             raw → stg → core LKP (ditulis langsung oleh ETL & approval)
                        └─ mart_*            Project Health, Kurva-S, LKP published  (Dashboard & BI)
```

**Penempatan data**

| Data | Ditulis di | Dibaca dari | Alasan |
|---|---|---|---|
| User, proyek, work package, Gantt, lampiran | PG (OpenProject) | Aplikasi; mirror ringkas ke SR | Kebutuhan runtime OpenProject |
| Formulir BOP-001 (`lpms3_form.*`), WBS, baseline, organisasi | PG (transaksi, FK, CHECK) | Layar: PG · Laporan/BI: SR | Integritas saat input & approval |
| LKP raw/stg/core, koreksi, approval LKP | **SR langsung** | SR | Volume & analitik; log approval append-only |
| Mart (Dashboard, Project Health, Kurva-S, portofolio) | SR (view) | Aplikasi & BI | Agregasi cepat lintas proyek |

Sinkronisasi: trigger/hook plugin menulis `lpms3.sync_outbox` dalam transaksi yang sama → `lpms3-data` meng-*upsert* ke tabel Primary Key StarRocks (idempoten, retry dengan backoff) → kolom `synced_at`. Rekonsiliasi malam membandingkan jumlah baris & checksum per tabel; selisih memicu sinkron ulang dan alarm.

---

## 3. WBS TEMPLATE LPMS — STRUKTUR WBS, FOLDER BUKTI, DAN DASAR KURVA-S

### 3.1 Struktur tabel (sama persis dengan `WBS Template LPMS.xlsx`, tabel `WBS` A1:O)

| Kolom template | Kolom DB (`lpms3.wbs_node`) | Aturan |
|---|---|---|
| WBS | `wbs_code` | Pola `0`, `1`, `1.1`, `1.1.1` … (daftar `Settings!A`); unik per proyek |
| Level | `level` | `Level 0` … `Level 7` dan `Level 5/6/7 Activity` (daftar `Settings!B`). **Activity = baris yang dikerjakan & diberi progres** |
| Tasks | `tasks` | Nama pekerjaan (mengikuti SoW/BoQ kontrak untuk Level 1–2) |
| Notes | `notes` | mis. "Daftar Checklist Survey" |
| Resource | `resource` | Daftar `Settings!E` (34 nilai: Pimpro, Engineer, Admin, Vendor, Keuangan, Pengadaan, Sponsor, Eselon 1/2, Staff, K3LH, Kualitas, Pengawas, Developer, Direksi, Perencanaan, Pemasaran, End User, Deputi Pimpro, Risiko, Innovation, Auditor, Sub-Vendor, Konsultan, Mekanikal, Elektrikal, Plumbing, Sipil, Perangkat Lunak/Keras, Jaringan, Bowheer, Lainnya, Unknown) |
| Date Plan Start / Finish | `date_plan_start/finish` | Wajib untuk Activity; induk = min/max anak |
| Date Actual Start / Finish | `date_actual_start/finish` | Terisi otomatis saat progres pertama > 0 % / mencapai 100 % (dapat dikoreksi dengan bukti) |
| Weigh Factor | `weigh_factor` | Porsi terhadap **induk langsung**; **Σ Weigh Factor saudara = 100 %** (template memakai pola `=100%-J…` untuk saudara terakhir) |
| Weight | `weight` | **= Weight induk × Weigh Factor**; Level 0 = 100 % |
| % Complete | `pct_complete` | Diskrit **0 / 25 / 50 / 75 / 100 %** (`Settings!C`) — hanya pada Activity, wajib bukti |
| % Progress | `pct_progress` | Activity: Weight × % Complete · Induk: Σ % Progress anak |
| Priority | `priority` | Low / Medium / High |
| Evidence Files | lampiran per node | Tersimpan di **folder bukti** node tersebut |

**Contoh dari template** (Level 0 = 100 %): 1 = 45 % → 1.1 = 45 % × 45 % = 20,25 % → 1.1.1 = 9,1125 % → Level 4 pertama = 4,1006 % → Activity "Survey Plan" (Weigh Factor 30 %) = **1,2302 %** bobot proyek; saudara Level 4 kedua = 100 % − 45 % = 55 % dari 1.1.1 = 5,0119 %; 1.2 = 24,75 %; 2 = 55 %.

### 3.2 Aturan validasi WBS (diterapkan saat simpan & impor)

1. Σ Weigh Factor tiap kelompok saudara = 100 % (toleransi 0,01 %) — blok simpan bila tidak.
2. Hanya Activity yang boleh menerima % Complete; induk dihitung.
3. Setiap Activity wajib: Tasks, Resource, Date Plan Start/Finish (finish ≥ start), Weigh Factor.
4. Kode WBS harus konsisten dengan hierarki (anak dari `1.1` berawalan `1.1.`).
5. % Complete hanya naik (turun = wajib alasan + persetujuan Fungsi Pengawasan Proyek).
6. % Complete > 0 wajib **minimal satu berkas bukti** di folder node; 100 % wajib bukti penerimaan (BA/hasil uji/BAST).
7. Bila kontrak mensyaratkan bobot harga (BOP-001 §5.4.1 *Bobot = Harga Pekerjaan per scope / Total Nilai Kontrak*), sistem menghitung Weigh Factor Level 1–2 dari `harga_pekerjaan` dan mengunci kolom tersebut; Σ harga = nilai kontrak.

### 3.3 Cara mengisi WBS (sesuai template)

- **Unduh template** dari layar WBS Generation (berkas resmi `WBS_Template_LPMS.xlsx` dengan dropdown `Settings`), isi di Excel, **unggah** → pratinjau & validasi baris per baris → simpan.
- **Isi langsung** di grid ala Excel (tempel dari Excel, tab/enter, tarik untuk indent/outdent yang otomatis mengubah Level & kode).
- **Salin** dari proyek sejenis atau dari LPMS 2 (Add New).
- Setiap node otomatis menjadi **work package** OpenProject (Gantt, notifikasi, relasi), dan **folder bukti** dibuat.

### 3.4 Folder bukti = struktur WBS

```
/<Kode Proyek> – <Nama Proyek>/
  00 Administrasi Proyek/                      ← dokumen non-WBS menurut taksonomi FFR-710 (A–E)
     A Pemasaran/ B Perencanaan & Pelaksanaan (Teknis)/ C Pengadaan/ D Keuangan/ E Penutupan/
  0 <Tasks Level 0>/
     1 <Tasks>/
        1.1 <Tasks>/
           1.1.1 <Tasks>/
              <Activity> – Evidence Files
```

- Setiap berkas memiliki dua label: **node WBS** (di mana bukti melekat) dan **butir FFR-710** (taksonomi kelengkapan dokumen), sehingga checklist FFR-710 terisi otomatis dari unggahan harian.
- Nama berkas distandarkan: `<KodeProyek>_<WBS>_<KodeFormulir/jenis>_<YYYYMMDD>_v<n>`; versi lama tetap tersimpan.
- Retensi & pemusnahan mengikuti COP-002 (§5.10–5.12).

### 3.5 Kurva-S dari WBS

- **Rencana:** untuk setiap Activity, Weight didistribusikan ke periode (bulanan; mingguan opsional) antara Date Plan Start–Finish — default **linear**, dapat diubah **front/back-loaded/manual** (bila kontrak memberi jadwal bobot per bulan). Disimpan di `scurve_plan` per **baseline**.
- **Realisasi:** Σ (Weight × % Complete terverifikasi) per periode dari `wbs_progress`.
- **Baseline 0** dibuat saat Kick-Off (Gate G2); **rebaseline hanya lewat BFR-001 yang disetujui** (kategori JADWAL/KURVA-S) dan menyimpan "Kurva S awal" & "Kurva S perubahan" sebagai lampiran BFR-001.
- **LKP (FFR-708)** dihasilkan dari WBS: *Rincian Kegiatan* = node Level 1–2 (atau level yang ditetapkan per proyek sesuai SoW/BoQ), *Bobot a* = Weight node, *b* = rencana kumulatif node, *d/f/h* = progres node. Lembar "4. Kurva S" FFR-708 dirender langsung dari data ini.
- Catatan konsistensi: progres Activity diskrit (25 %), tetapi progres node induk & LKP menjadi kontinu (mis. 67,30 %) karena agregasi berbobot — sesuai pola LKP yang berjalan.

---

## 4. PENGALAMAN PENGGUNA (UX) — "BETAH DIPAKAI SEPANJANG WAKTU"

### 4.1 Prinsip

1. **Satu layar = satu pekerjaan BOP-001.** Judul layar memakai bahasa prosedur ("Reviu PMP", "Ajukan Change Request"), bukan istilah sistem.
2. **Selalu tahu langkah berikutnya.** Setiap halaman fase menampilkan *stepper* tahap BOP-001, status gate, dan kartu "Yang perlu Anda lakukan" sesuai peran.
3. **Isi sekali, pakai di mana-mana.** Data master (kode proyek, kontrak, nilai, Pimpro, pelanggan) terisi otomatis di semua formulir; tidak ada ketik ulang.
4. **Formulir terasa seperti formulirnya.** Urutan field & penomoran kolom mengikuti template resmi (mis. RFR-002 kolom (1)–(26)), dengan tombol **"Pratinjau PDF resmi"**.
5. **Excel-friendly.** Grid untuk tabel berbaris (WBS, risk register, C1–D7a FFR-710): tempel dari Excel, unduh/unggah template, isi massal.
6. **Validasi lembut tapi tegas.** Pesan inline di kolom ("Σ Weigh Factor 1.1 = 95 %, kurang 5 %"), bukan pop-up; tombol Submit baru aktif saat lengkap.
7. **Tidak pernah kehilangan pekerjaan.** *Autosave* draf tiap 5 detik, riwayat versi, "kembalikan versi".
8. **Cepat.** Target: halaman < 1,5 s (p95), grid 1.000 baris lancar, sidebar < 300 ms.

### 4.2 Sistem desain

- Komponen **Primer (OpenProject)** + token tema LPMS3 (warna korporat Len, font, logo dari Settings — §12 Buku Teknis); mode terang/gelap; ukuran sentuh ≥ 40 px; kontras WCAG AA.
- Pola baku: *Page header* (judul, kode proyek, fase, status), *Stepper* fase, *Card* ringkasan, *Data grid*, *Side panel* detail (tanpa pindah halaman), *Wizard* untuk proses berlangkah (Add New, Kode Proyek, Closing), *Inbox approval*.
- Status warna konsisten: abu (draf), biru (diajukan), kuning (perlu tindakan/peringatan), hijau (disetujui/on track), merah (ditolak/terlambat/risiko tinggi).
- Microcopy Bahasa Indonesia baku, istilah BOP-001; tooltip definisi BOP-001 §3.0 pada istilah (Baseline, CCM, Scope Creep, dll.).

### 4.3 Beranda per persona

| Persona | Beranda | Isi utama |
|---|---|---|
| Admin Teknis | Fase aktif proyek | Update progres + unggah bukti, LKP yang perlu dibersihkan, formulir draf |
| Pimpro | Fase aktif proyek | Gate berikutnya, tugas BOP-001 jatuh tempo, CR/risiko/isu yang menunggu, deviasi Kurva-S |
| Fungsi Pengawasan Proyek | Project Health | Proyek merah/kuning, LKP & CR menunggu verifikasi, jadwal rapat tinjauan |
| Fungsi pendukung | "Permintaan untuk Fungsi Saya" | WO, item pengadaan, NCR, K3L, konsultasi CR |
| Eselon I / Direksi | Dashboard | Portofolio, tren, keputusan yang menunggu, catatan arahan |

### 4.4 Kebiasaan harian yang didukung

- **Mingguan:** Admin Teknis/Tim memperbarui % Complete + bukti (≤ 5 menit per proyek).
- **Bulanan (tgl 1–5):** LKP otomatis dari WBS → reviu Pimpro → approval berjenjang; Risk Register diperbarui; tabel FFR-710 C1–D7a diperbarui.
- **Saat terjadi:** isu, NCR, CR, rapat.
- Notifikasi ringkas (in-app + email harian terkonsolidasi), tautan langsung ke aksi.

---

## 5. ALUR END-TO-END: PRA-PROYEK → INISIASI → PERENCANAAN → EKSEKUSI → PENGAWASAN & PENGENDALIAN → PENUTUPAN

Notasi kolom: **Fungsi** memakai CLP-001 (MPR = Manajemen Proyek/Pimpro/Tim, PWP = Pengawasan Proyek, PRP = Perencanaan Proyek, ANG = Pengendali Anggaran, dst.). **Menu** = posisi di sidebar LPMS3. **Data** = tabel `lpms3_form.*`/`lpms3.*` (lihat Lampiran 02).

### 5.0 Pra-proyek & serah terima ke LPMS3 (SOP-001, SOP-004)

| # | Langkah | Fungsi | Menu | Formulir / data | Aturan |
|---|---|---|---|---|---|
| 0.1 | Proyek dibuat dari **Add New (LPMS 2)** atau manual | PMO / Pembuat proyek | PROJECT › Add New | `project`, atribut kontrak; lampiran SFR-003/006/020/021/024/026/027 bila ada | Tidak boleh duplikat (lpms2_project_id); kelas kontrak dihitung dari nilai (SOP-004: < 25 M Kecil, 25–100 M Sedang, > 100 M Besar) |
| 0.2 | Hasil Tinjauan Go/No Go dicatat | F. Pemasaran (mengajukan), F. Pengawasan Pra Proyek (memeriksa), Direksi | [Inisiasi] ringkasan | **SFR-028** `sfr028_go_nogo` | Kelas Sedang/Besar wajib SFR-028 Go; Kecil → SFR-024 |
| 0.3 | Profil proyek & kajian risiko pra-proyek | F. Pemasaran / PRP, reviu F. Manajemen Risiko | [Inisiasi] › Preliminary Aspect (Risiko) | **RFR-004** `rfr004_profil_proyek`; **RFR-002** awal | 31 butir RFR-004 wajib; RFR-002 minimal risiko bawaan dari "Contoh Identifikasi Risiko" |

### 5.1 Tahap INISIASI (BOP-001 §5.1) → Gate **G1 Project Charter ditetapkan**

| # | Langkah BOP-001 | Fungsi (A / R) | Menu | Formulir / data | Aturan & validasi |
|---|---|---|---|---|---|
| 1.1 | **Pembukaan Kode Proyek** (§5.1.1, FOP-700) | A: Struktural F. MPR · R: F. MPR · S: F. ANG · C: F. PRP | [Inisiasi] › Kode Proyek (wizard) | **FFR-706** `ffr706_pengajuan_kode`; **FLP-01** `flp01_checklist` (42 dokumen × 14 jenis kode) | Jenis kode (FOP-700, 14 jenis) menentukan butir FLP-01 wajib; submit hanya bila semua butir wajib ✓ + berkas; verifikasi F. ANG → Kode SAP diisi → proyek aktif |
| 1.2 | **Penetapan Pimpro & Tim** (§5.1.2, HOP-609) | A: Struktural F. MPR · R: F. MPR · S: F. ANG, PRP, SDM · C: F. PWP | [Inisiasi] › Team Assignment | `project` (pimpro), memberships, `user_position`; lampiran SK Pimpro, SFR-022 (kelas proyek & Pimpro), HFR-073/075 | Tim inti **≤ 2 minggu** sejak kode dibuka (hitung mundur, kuning H-3, merah lewat); kelas proyek & Pimpro mengikuti SFR-022 |
| 1.3 | **Penetapan Project Charter** (§5.1.3) | A: Struktural F. MPR · R: F. MPR · S: F. PRP · C: ANG, KEU | [Inisiasi] › ringkasan › Project Charter | **BOT-001** `bot001_*` (11 bagian, 5 tabel) | Semua bagian wajib; Success Criteria 4 aspek; risiko H/M/L; timeline Kick-off…Closure |
| 1.4 | PMP preliminary 9 aspek diterima | F. PRP → F. MPR | [Inisiasi] › Preliminary PM Aspect (9) | WP "Dokumen Rencana" × 9 + lampiran | 9 kartu: Ruang Lingkup, Jadwal, Biaya, Mutu, SDM, Komunikasi, Risiko & K3L, Pengadaan, Stakeholder |
| G1 | **Gate G1** | A: Struktural F. MPR | [Inisiasi] | `project_gate` | Kode aktif + FLP-01 lengkap + Pimpro & tim inti + BOT-001 disahkan; checklist pengawasan tahap Inisiasi oleh F. PWP |

### 5.2 Tahap PERENCANAAN (BOP-001 §5.2) → Gate **G2 Kick-Off / Baseline 0**

| # | Langkah | Fungsi | Menu | Formulir / data | Aturan |
|---|---|---|---|---|---|
| 2.1 | **Reviu dokumen PMP 9 aspek** (§5.2.1, Tabel 2 RASCI) | A: Pimpro · R: Tim · S/C sesuai Tabel 2 | [Perencanaan] › Reviu PMP & Kick-Off | 9 WP Dokumen Rencana: Scope Baseline (WBS Plan, Requirements, RMP, Scope Statement, Assumption Log, CDRL), Schedule Mgmt Plan (Activity List, Estimasi Durasi, Schedule Baseline), PIS + Cash Flow + pendanaan (FFR-714/721/716), Quality Mgmt Plan (QOG-002), Resource Mgmt Plan (+Team Charter), Communication Matrix (+Project Dashboard), Risk Mgmt Plan + HSE Plan, Procurement Plan (PFR-034), Stakeholder Engagement Plan | Status Draft → Reviu → Revisi → Disahkan per aspek; keluaran wajib per aspek ditandai |
| 2.2 | **WBS Generation** (WBS Template LPMS) | R: Pimpro/Admin Teknis · S: F. PRP, Rekayasa Sistem | [Perencanaan] › WBS Generation | `lpms3.wbs_node` (15 kolom template) | §3.2 aturan WBS; total bobot 100 %; selaras SoW/BoQ |
| 2.3 | Kurva-S rencana | R: Pimpro · C: F. PWP | [Perencanaan] › Baseline & Rebaseline | `scurve_plan` | Distribusi linear/manual; total = 100 % pada akhir jadwal |
| 2.4 | Risiko & K3L direncanakan | R: Tim · C: F. MRS, F. K3L | [Monitoring] › Risk / K3LH Status | **RFR-002** (26 kolom), **VFR-015** (26 kolom + header) | Level risiko ROP-911; HIRA disusun–direview–disetujui |
| 2.5 | **Kick-Off Meeting** (§5.2.2, peserta Tabel 2) | Pemimpin: Es. I/II F. PWP · Pemapar: Pimpro | [Perencanaan] › Reviu PMP & Kick-Off | **CFR-022** `cfr022_*` (agenda, kesimpulan & tindak lanjut, peserta) | Undangan otomatis dari `ref_peserta_rapat`; delegasi struktural tercatat; tindak lanjut → Action Item |
| 2.6 | **Baseline 0** | A: F. PWP | [Perencanaan] › Baseline & Rebaseline | `baseline` v0, `baseline_item` | Hanya setelah risalah Kick-Off disahkan |
| 2.7 | **Top Up Anggaran** (§5.2.3, BOG-003 §5.1–5.2) | F. MPR → F. ANG (tembusan F. PWP) | [Perencanaan] › Baseline › tab Biaya | permohonan + CFR-022 Rapat Tinjauan Top-Up | Cek ketersediaan anggaran (PIS) → proses SAP → PR (oleh F. PWP); status sinkron manual/ERP |
| G2 | **Gate G2** | A: Es. I/II F. PWP | [Perencanaan] | `project_gate` | 9 aspek Disahkan + WBS valid + Kurva-S + CFR-022 Kick-Off + Baseline 0 |

### 5.3 Tahap EKSEKUSI (BOP-001 §5.3)

| # | Proses BOP-001 | Fungsi | Menu | Formulir / data | Aturan |
|---|---|---|---|---|---|
| 3.1 | **Mengarahkan & mengelola pekerjaan** (§5.3.1) | A/R: Pimpro/Tim | [Eksekusi] › Work Order; WBS | Work Order (WP), `wbs_progress` + bukti | % Complete diskrit + bukti; verifikasi internal → validasi pelanggan → **WFR-014 BAST** |
| 3.2 | **Pengelolaan Pengetahuan** (§5.3.2) | Pimpro | [Eksekusi] ringkasan › Lessons Learned | WP Lesson Learned + wiki | Dibahas di rapat rutin; dipublikasikan lintas proyek |
| 3.3 | **Tim proyek** (§5.3.3) | Pimpro, F. SDM | [Inisiasi] › Team Assignment | assignment, job desc, KPI; evaluasi Pimpro HFR-074 | CR bila perubahan tim signifikan |
| 3.4 | **Pengelolaan Mutu** (§5.3.4, QOG-001/002) | Tim + F. PMT | [Monitoring] › Quality Status | Quality Report, Inspeksi, **CFR-027** (19 kolom), MFR-001, QFR-026/027 | NCR terbuka kritikal memblok penerimaan deliverable |
| 3.5 | **Komunikasi** (§5.3.5) | Tim + F. PMS | [Eksekusi] ringkasan › Rapat | **CFR-022**, project dashboard | Distribusi risalah otomatis ke peserta |
| 3.6 | **Risk Response & K3L** (§5.3.6) | Tim + F. MRS, F. K3L | [Monitoring] › Risk / K3LH Status | **RFR-002** bulanan, **RFR-001** (risiko operasional), **VFR-015** | Perubahan metode/lapangan → review VFR-015; strategi baru → BFR-001 |
| 3.7 | **Pengadaan** (§5.3.7, POP-100…109, WOP-207) | F. PGD + Tim | [Monitoring] › Procurement Pipeline (4 halaman) | Item Pengadaan (PR/PFR-003 → RFQ/SPPH PFR-007 → BA Nego PFR-009 → PO PFR-010/SPK PFR-011 → BAPB/WFR-002 → GR/SES → bayar), **PFR-037** (PMN), **FFR-710 C1/C2** | Metode sesuai POP-102 (langsung/terbatas/penunjukan/umum); kendala → Issue Log |
| 3.8 | **Engagement Stakeholder** (§5.3.8) | Pimpro + F. PMS | [Monitoring] (Stakeholder) | Stakeholder Register | Keterlibatan current/desired |
| 3.9 | **Change Request** (§5.3.1, §5.4.2) | Pimpro mengajukan | [Eksekusi] › Change Request | **BFR-001** (kategori ANGGARAN/SCOPE/JADWAL/KURVA-S, checklist 18 + rekomendasi 9) | Ambang: < Rp1 M Es. II, ≥ Rp1 M Es. I (F. MPR & F. PWP); adendum → SOP-009 (SFR-025, rapat tinjauan adendum) |
| 3.10 | **Pergeseran / Revisi Anggaran** (BOG-003 §5.3–5.4) | F. MPR → F. ANG | [Perencanaan] › Baseline › Biaya | permohonan + CFR-022 | ≤ 200 jt: ES II (1 hari) · 200–500 jt: ES I & II (2 hari) · > 500 jt: Direksi (3 hari); HPP naik → Rapat ABT dipimpin Direktur Keuangan & SDM |
| 3.11 | Persediaan proyek (WOP-207) | Gudang proyek, Rendal, Site Manager | [Monitoring] (Persediaan) | FFR-710 C2, WFR-035/004/037/038 (generik), **WFR-028** bulanan | Stock opname bulanan diperiksa Es. II, disetujui Es. I |

### 5.4 Tahap PENGAWASAN & PENGENDALIAN (BOP-001 §5.4) — berjalan paralel dengan Eksekusi

| # | Proses | Fungsi (A/R) | Menu | Data | Aturan |
|---|---|---|---|---|---|
| 4.1 | **Monitoring & Controlling Project Work / LKP** (§5.4.1) | A/R: F. PWP; dibuat Pimpro | [Monitoring] › LKP (FFR-708) | **FFR-708** `ffr708_cover/rekap/kurva_s/permasalahan/pembukuan` (dari WBS) **atau** unggahan multi-format (ETL §8) | Bobot = harga/nilai kontrak bila disyaratkan; c=a×b … j=i−c; laporan ke F. Akuntansi **≤ tgl 5**; approval L0→L5 |
| 4.2 | **Integrated Change Control / CCM** (§5.4.2) | A/R: F. PWP | [Eksekusi] › Change Request | BFR-001, CFR-022 (Rapat CCM), Change Log | Tidak ada perubahan baseline tanpa BFR-001 disetujui; Change Log = semua CR |
| 4.3 | **Kontrol & validasi ruang lingkup** (§5.4.3) | F. PWP | [Eksekusi] ringkasan | Deliverable vs scope baseline | Scope creep → CR |
| 4.4 | **Pemantauan jadwal** (§5.4.4) | F. PWP | Baseline & Rebaseline; Kurva-S | mart_scurve_monthly | Mingguan & bulanan; milestone; SPI |
| 4.5 | **Pemantauan biaya** (§5.4.5) | F. PWP + F. ANG | [Monitoring] (Anggaran) | **FFR-710 D1** (penyerapan), D2–D4/D7a (beban), D5a (pendapatan) | Realisasi vs RAB & cash flow; input penagihan |
| 4.6 | **Pengendalian mutu** (§5.4.6) | A: F. PWP · R: F. PMT | Quality Status | CFR-027, inspeksi, audit (QOP-803/COP-004) | T&C internal sebelum pelanggan |
| 4.7 | **Pemantauan SDM** (§5.4.7) | F. PWP | Team Assignment | rencana vs aktual | — |
| 4.8 | **Pemantauan komunikasi & Rapat Tinjauan Proyek** (§5.4.8, Tabel 4) | Pemimpin: Es. I/II F. PWP | Rapat | CFR-022 (agenda baku: kemajuan, anggaran, risiko & peluang, pengadaan, umpan balik, mutu, lainnya) | Peserta otomatis per Tabel 4; delegasi tercatat |
| 4.9 | **Pemantauan risiko & K3L** (§5.4.9) | F. PWP + F. MRS + F. K3L | Risk / K3LH Status | RFR-002, RFR-001, VFR-015 | Level Menengah-Tinggi/Tinggi wajib tindakan; lewat tanggal review → merah |
| 4.10 | **Pemantauan pengadaan** (§5.4.10) | F. PWP | Procurement Pipeline | FFR-710 C1 (status kedatangan: Belum…Wanprestasi) | Item jalur kritis terlambat → merah |
| 4.11 | **Pemantauan stakeholder engagement** (§5.4.11) | F. PWP | Stakeholder | register & plan | — |

### 5.5 Tahap PENUTUPAN (BOP-001 §5.5, FOP-705) → Gate **G4 Proyek ditutup**

| # | Langkah | Fungsi | Menu | Formulir / data | Aturan |
|---|---|---|---|---|---|
| 5.1 | LKP **100 %** | Pimpro; diperiksa Es. II; **disetujui Es. I & Pemberi Kerja** | [Monitoring] › LKP | FFR-708 | Wajib tanda tangan Es. I (catatan kaki FFR-708) |
| 5.2 | **BAST** pekerjaan/pemeliharaan | Pimpro & Pemberi Kerja | [Closing] langkah 1 | **WFR-014** | Didistribusikan ke F. Keuangan, Akuntansi, Pemberi Kerja |
| 5.3 | Pengembalian **bahan sisa** + **stock opname** | Pimpro → Gudang; Akuntansi | [Closing] langkah 2 | **WFR-010**, **WFR-028** | Distribusi ke Perencanaan Perusahaan, ANG, KEU, AKT, Audit Internal |
| 5.4 | Realisasi penyerapan pagu & cash flow; Laporan L/R | F. ANG (SAP), F. AKT | [Closing] langkah 3 | dokumen generik + angka ke `project` | Diserahkan ke Pimpro & Audit Internal |
| 5.5 | **Proyek Selesai 100 %** atau **Terminasi** (§5.5.1–5.5.2) | A: Struktural F. MPR / Direksi (terminasi via Radir) | [Closing] pilihan jalur | FLP-03 (syarat dokumen penutupan), **FFR-713** Tinjauan Penutupan | Terminasi: 3 sebab BOP-001; laporan F. PWP |
| 5.6 | Penutupan **Kode Proyek** (FOP-705) | F. ANG verifikasi | [Closing] | status kode SAP | Dokumen lengkap → kode ditutup |
| 5.7 | **Kode Purnajual** (§5.5.3, FOP-700) | A: Struktural F. MPR · R: F. MPR | [Closing] | sub-proyek LPMS3-Purnajual | Bila kontrak mensyaratkan |
| 5.8 | **Pendokumentasian arsip** (§5.5.4) | Pimpro & Tim | [Closing] › Arsip | **FFR-710** Daftar Isi (A–E) + tabel C1–D7a | Semua butir wajib "Ada (tanggal)" atau "Tidak Ada" + alasan; retensi COP-002 |
| 5.9 | Laporan Akhir & Lessons Learned | Pimpro | [Closing] | Laporan Akhir, LL | Dipublikasikan |
| G4 | **Gate G4** | Pimpro (arsip) / Direksi (terminasi) | [Closing] | `project_gate` | Proyek diarsipkan read-only; data tetap di StarRocks |

### 5.6 Pengawasan per tahap (swimlane bawah Alur §7.0 BOP-001)

Setiap fase memiliki **checklist pengawasan F. Pengawasan Proyek** (Pengawasan Tahap Inisiasi/Perencanaan/Eksekusi/Pengendalian/Penutupan) yang wajib "selesai" sebelum gate dapat diputuskan.

---

## 6. FORMULIR & PROSEDUR — CAKUPAN PENUH

### 6.1 Ringkasan cakupan

| Kelompok | Jumlah | Status di LPMS3 |
|---|---|---|
| Formulir dengan template di folder (struktur penuh dipetakan) | **18 formulir · 43 tabel · 509 kolom** | Layar input + tabel PG `lpms3_form.*` + mirror StarRocks `form_*` + PDF resmi |
| WBS Template LPMS | 1 tabel · 15 kolom + daftar `Settings` | `lpms3.wbs_node` + `wbs_progress` + Kurva-S |
| Tabel di dalam prosedur (SOP) | 16 tabel referensi/aturan | `lpms3.ref_*`, `capability_rule`, `ffr710_daftar_isi` |
| Formulir dirujuk SOP, template belum di folder | ±60 kode | Dokumen terstruktur generik + slot checklist; dilengkapi saat template diserahkan |
| Prosedur (SOP/pedoman) | 50 dokumen | Dipetakan ke langkah alur §5 (Lampiran 01) |

Daftar lengkap per kolom — **Lampiran 02 `02_Kamus_Data_Formulir_dan_SOP.md`** dan **`LPMS3_Data_Dictionary.xlsx`** (sheet Formulir, Kolom, Pilihan, Tabel_SOP, Belum_di_folder).

### 6.2 Formulir yang dipetakan penuh

| Kode | Formulir | Fase | Tabel LPMS3 |
|---|---|---|---|
| FFR-706 rev.11 | Pengajuan Kode Kegiatan | Inisiasi | `ffr706_pengajuan_kode` |
| FLP-01 rev.15 | Checklist persyaratan pembukaan kode (42 × 14) | Inisiasi | `flp01_master_persyaratan`, `flp01_checklist` |
| BOT-001 rev.00 | Project Charter | Inisiasi | `bot001_charter` + 5 tabel |
| SFR-028 rev.00 | Rapat Tinjauan Order/Kontrak Go/No Go | Pra-proyek | `sfr028_go_nogo` |
| RFR-004 rev.02 | Profil Proyek (31 butir) | Pra-proyek/Inisiasi | `rfr004_profil_proyek` |
| RFR-005 rev.00 | Profil Risiko Program | Inisiasi (program) | `rfr005_profil_program` |
| RFR-002 rev.03 | Project Risk Register (26 kolom) | Semua | `rfr002_header`, `rfr002_risiko` |
| RFR-001 rev.05 | Risk Register Unit Kerja (40 kolom) | Eksekusi/Monitoring | `rfr001_header`, `rfr001_risiko` |
| VFR-015 rev.05 | HIRA K3 & Aspek-Dampak Lingkungan | Perencanaan/Eksekusi | `vfr015_header`, `vfr015_aspek_bahaya` |
| CFR-022 rev.01 | Risalah Rapat | Semua | `cfr022_risalah`, `_agenda`, `_tindak_lanjut`, `_peserta` |
| BFR-001 rev.00 | Change Log / Change Request | Eksekusi/Monitoring | `bfr001_change_request` |
| FFR-708 rev.09 | Laporan Kemajuan Proyek/Program/TL | Monitoring/Closing | `ffr708_cover`, `_rekap`, `_kurva_s`, `_permasalahan`, `_pembukuan` |
| CFR-027 rev.00 | Ketidaksesuaian & Tindakan Koreksi (= QFR-017 di LKP) | Eksekusi/Monitoring | `cfr027_ketidaksesuaian` |
| PFR-037 rev.00 | Pengajuan Proposal Pengadaan PMN | Pengadaan | `pfr037_header`, `pfr037_item` |
| FFR-710 rev.02 | Laporan Dokumentasi Proyek (Daftar Isi A–E + 9 tabel) | Semua/Closing | `ffr710_*` (8 tabel) |
| WFR-014 rev.03 | BAST Pekerjaan/Pemeliharaan | Eksekusi/Closing | `wfr014_bast` |
| WFR-010 rev.03 | Bukti Pengembalian Bahan Sisa | Closing | `wfr010_header`, `wfr010_item` |
| WFR-028 rev.02 | BA Pemeriksaan Fisik Persediaan | Monitoring/Closing | `wfr028_stock_opname` |

### 6.3 Tabel dari prosedur yang menjadi aturan sistem

CLP-001 (35 fungsi generik) · FOP-700 (14 jenis kode) · FLP-01 (matriks dokumen) · SOP-004 (kelas kontrak; peserta tinjauan teknis/costing/Go sedang/besar; **akses informasi per fungsi: Copy Value / HPS / Kelas Proyek / Akses Penuh**) · SOP-009 (peserta tinjauan adendum; akses informasi) · BOG-003 (matriks pergeseran anggaran + SLA; peserta ABT) · BFR-001 (ambang CR) · ROP-911 (skala & level risiko, kriteria dampak/kemungkinan) · BOP-001 (RASCI Tabel 1–6, peserta Tabel 2 & 4) · FFR-710 (taksonomi dokumen) · COP-002 (pengesahan & retensi) · WOP-207 (alur persediaan).

### 6.4 Formulir yang dirujuk tetapi templatenya belum ada di folder

Antara lain SFR-003/006/020/021/022/024/025/026/027/030/031, FFR-709/713/714/716/721/722, FLP-03, HFR-073/074/075, PFR-001…034, WFR-002/004/035/037/038, WCR-001, MFR-001, QFR-026/027/028, SFR-005/007, VFR-020/044/051/055/058 (daftar lengkap di Lampiran 02). Perlakuan: **dokumen terstruktur generik** (nomor, tanggal, pihak, status, tanda tangan, lampiran PDF/Excel asli, tautan WBS & butir FFR-710) sehingga alur & checklist tidak terhambat. **Tindakan:** PMO menyerahkan template tersebut → kolom ditambahkan ke `spec_forms.py` → DDL & layar dibangkitkan ulang.

### 6.5 PDF resmi

Setiap formulir dapat dirender ke **PDF dengan tata letak template resmi** (kop, nomor formulir & revisi, kolom pengesahan, tembusan) oleh `lpms3-data/render`; PDF yang sudah ditandatangani disimpan sebagai rekaman (COP-002) di folder bukti.

---

## 7. PERAN, RASCI, APPROVAL & KAPABILITAS

- **RASCI BOP-001** (Tabel 1, 2, 3, 5, 6 — ±32 aktivitas) dimuat ke `lpms3.ref_rasci` dan diterapkan ke WP aktivitas template: Accountable (tunggal, BOP-001 §3.25), Responsible = assignee, Supporting & Consulted = field user, Informed = watcher.
- **Approver ditentukan dari Fungsi → Struktur Organisasi** (CLP-001 + SKEP + Nota 021; rincian Buku Teknis §14).
- **Matriks kewenangan** (`ref_matriks_kewenangan`): BFR-001 (< Rp1 M Es. II; ≥ Rp1 M Es. I), BOG-003 (≤ 200 jt ES II/1 hari; 200–500 jt ES I & II/2 hari; > 500 jt Direksi/3 hari), ABT (Rapat Tinjauan dipimpin Direktur Keuangan & SDM).
- **Hierarki approval LKP & dokumen**: L0 Admin Teknis → L1 Pimpro → L2 F. Pengawasan Proyek → L3 Es. II F. Manajemen Proyek → L4 Es. I → L5 Direksi; **data hanya terlihat oleh level k setelah level k−1 menyetujui** (Buku Teknis §13.6–13.7).
- **Akses informasi tingkat kolom** (SOP-004/009): Pemasaran & Keuangan = *Copy Value*; Pengadaan = *HPS*; SDM & Manajemen Risiko = *Kelas Proyek*; Pengawasan Pra Proyek/Perencanaan Proyek/Pengendali Anggaran = *Akses Penuh* → diterapkan sebagai `capability_rule.info_access` (kolom biaya/RAP disembunyikan sesuai hak).
- **Pusat pengguna**: Tier 1 F. Manajemen Proyek, F. Pengawasan Proyek, F. Perencanaan Proyek; Tier 2 fungsi kontributor (DIRECT/PROXY); Tier 3 pimpinan & tembusan.

---

## 8. LKP MULTI-FORMAT (RINGKAS; rinci di Buku Teknis §13)

- Target utama: **LKP lahir dari WBS LPMS3** (FFR-708 rev.09 dirender otomatis).
- Masa transisi: unggahan Pimpro (V1 SAP ZSFPS001, V2 SAP+lampiran, V3 Print-to-PDF, V4 Excel FFR-708, V5 workbook .xlsx) diekstrak ke **StarRocks `lkp_*`**, divalidasi V01–V22, dikoreksi Admin Teknis, lalu masuk approval L0–L5.
- Rekonsiliasi LKP unggahan vs WBS: selisih progres per Rincian Kegiatan > 0,5 poin ditampilkan dan wajib dijelaskan.
- Rekomendasi rilis 2: tarik progres dari SAP PS (form ZSFPS001) secara langsung.

---

## 9. DATA DI STARROCKS `default_catalog.lpms3`

| Berkas | Isi |
|---|---|
| `db/starrocks/000_init.sql` | `CREATE DATABASE lpms3`, role `lpms3_writer/reader/bi`, user `lpms3_app/etl/bi` (password dari `.env`) |
| `db/starrocks/100_core_mirror.sql` | Mirror organisasi, fungsi, posisi, proyek, gate, referensi SOP, WBS, baseline, Kurva-S |
| `db/starrocks/110_lpms3_forms_mirror.sql` | Mirror 43 tabel formulir + `form_instance/signature/attachment/definition` (dibangkitkan) |
| `db/starrocks/200_lkp.sql` | LKP raw/stg/core, validasi, koreksi (append-only), approval (append-only), `v_lkp_status` |
| `db/starrocks/300_marts.sql` | `mart_scurve_monthly`, `mart_lkp_published`, `mart_project_health` |
| `db/starrocks/990_grants.sql` | Hak akses per role |

Prinsip: tabel **Primary Key** untuk data yang di-*upsert*, **Duplicate Key** untuk log append-only; tidak ada FK/transaksi multi-statement → konsistensi dijaga oleh outbox idempoten + rekonsiliasi harian; status approval diturunkan dari log. **Backup StarRocks**: `BACKUP SNAPSHOT` ke repository NAS (dikoordinasikan dengan admin StarRocks) + kemampuan rebuild mirror dari PG; data `lkp_*` (primer di StarRocks) wajib masuk snapshot harian.

---

## 10. PENGUJIAN

| Lapisan | Isi | Kriteria |
|---|---|---|
| Skema | Jalankan `db/*.sql` 2× (idempoten) di PG & StarRocks staging | 0 error; jumlah tabel sesuai (PG 70 tabel; SR ±80 objek) — DDL PG sudah diuji pada PostgreSQL 16 |
| Kamus data | Setiap kolom formulir punya padanan DB & layar | 509/509 kolom tampil di layar & PDF |
| WBS | Impor `WBS_Template_LPMS.xlsx` contoh + 3 WBS proyek nyata | Weight & Kurva-S = perhitungan Excel (selisih 0) |
| LKP | Golden-file 10 sampel Oktober 2026 + LKP dari WBS | E01–E10 (Buku Teknis §13.9) |
| Alur BOP-001 | Skenario end-to-end per tahap §5 (UAT U01–U26 + baru: U27 WBS Template, U28 FLP-01 per jenis kode, U29 BOG-003 tiga ambang, U30 FFR-710 lengkap, U31 Closing FOP-705 penuh) | ≥ 95 % lulus, 0 kritikal |
| Sidebar & kapabilitas | S01–S12, F01–F08 | Lulus |
| Sinkron StarRocks | Ubah 1.000 baris → cek SR | p95 ≤ 60 detik; rekonsiliasi 0 selisih |
| UX | Uji kegunaan 8 pengguna (Pimpro, Admin Teknis, PMO, Pengadaan, Es. II) | SUS ≥ 80; tugas inti selesai tanpa bantuan; update progres mingguan ≤ 5 menit |
| Kinerja & keamanan | 50 proyek, 20.000 WP; pemindaian kerentanan image | p95 halaman < 1,5 s; 0 temuan tinggi |

---

## 11. RUNBOOK DEPLOYMENT DI VM UBUNTU (urutan eksekusi)

> Prasyarat jaringan: VM `192.168.125.14` dapat menjangkau `192.168.125.29:9030` (StarRocks FE) dan GitHub; port `5100` dibuka untuk subnet pengguna. Rincian perintah OS/Docker/hardening: Buku Teknis §4 (F1–F3).

| Langkah | Perintah / tindakan | Verifikasi |
|---|---|---|
| D0 | Siapkan VM (Ubuntu 24.04, disk `/srv/lpms3`), Docker, UFW (Buku Teknis F1) | `docker run hello-world` |
| D1 | `git clone https://github.com/andretiganalen/lpms3-v2.git /srv/lpms3/app` | commit = tag rilis |
| D2 | `cp deploy/.env.example deploy/.env` → isi secret (SECRET_KEY_BASE, PG, **STARROCKS_ROOT_PASSWORD** hanya untuk langkah D4, password user `lpms3_app/etl/bi`) → `chmod 600` | `.env` tidak ter-track git |
| D3 | `bash ops/compose_up.sh` (clone upstream `stable/17`, build image `lpms3/openproject` + `lpms3/data`, `docker compose up -d`) | `curl http://192.168.125.14:5100/health_checks/full` = PASSED |
| D4 | `bash ops/starrocks_apply.sh` — menjalankan `db/starrocks/000→990` memakai root **sekali**, membuat `default_catalog.lpms3` & user aplikasi | `SHOW DATABASES` berisi `lpms3`; `SHOW TABLES` ≈ 80 objek; login `lpms3_app` berhasil |
| D5 | `bash ops/pg_apply.sh` — menjalankan `db/010_lpms3_forms.sql`, `020_lpms3_core.sql`, `030_lpms3_seed_ref.sql` ke database OpenProject | jalankan 2× tanpa error; `select count(*) from lpms3_form.form_definition` = 18 |
| D6 | Hapus `STARROCKS_ROOT_PASSWORD` dari `.env` setelah D4 (root tidak dipakai aplikasi) | grep kosong |
| D7 | Seed LPMS3 (tipe, status, workflow, template proyek) — Buku Teknis §5.10 | idempoten |
| D8 | Muat struktur organisasi (SKEP, Nota 021, posisi, user) via Settings › User & Access atau impor HC | F01–F05 |
| D9 | Uji sinkron: buat proyek uji → cek `lpms3.project` di StarRocks ≤ 60 detik | `synced_at` terisi |
| D10 | Smoke test alur Inisiasi→Closing proyek uji; hapus data uji | U01–U31 inti |
| D11 | Backup: PG (dump), `opdata`, `lkp-raw`, `.env`; StarRocks snapshot harian | restore drill |
| D12 | Go-live sesuai Buku Teknis §7.4 | BA go-live |

Variabel `.env` StarRocks:

```dotenv
STARROCKS_HOST=192.168.125.29
STARROCKS_PORT=9030
STARROCKS_CATALOG=default_catalog
STARROCKS_DATABASE=lpms3
STARROCKS_JDBC_URL=jdbc:mysql://192.168.125.29:9030/lpms3      # padanan jdbc:starrocks://192.168.125.29:9030/
STARROCKS_ROOT_USER=root
STARROCKS_ROOT_PASSWORD=          # diisi saat D4 saja, lalu dikosongkan
STARROCKS_APP_PASSWORD=
STARROCKS_ETL_PASSWORD=
STARROCKS_BI_PASSWORD=
```

---

## 12. JADWAL & TIM (diperbarui)

| Minggu | Platform & data | Plugin LPMS3 | Formulir & WBS | Milestone |
|---|---|---|---|---|
| 0 | Keputusan terbuka §14, akses VM & StarRocks | — | Serah template formulir yang belum ada | M0 |
| 1 | VM, Docker, staging, StarRocks `lpms3` (D4) | S1 sidebar & kapabilitas dasar | Generator kamus data → DDL | M1 staging + DB siap |
| 2 | PG schema (D5), outbox & sync worker | S2 Settings, User & Access, Inisiasi | FFR-706, FLP-01, BOT-001, SFR-028, RFR-004/005 | — |
| 3 | Rekonsiliasi PG↔SR | S3 Perencanaan | **WBS Template engine**, Kurva-S, baseline | M2 WBS & Kurva-S |
| 4 | Render PDF formulir | S4 Eksekusi | RFR-002, RFR-001, VFR-015, CFR-022, BFR-001, CFR-027 | — |
| 5 | ETL LKP (E1–E2) | S5 Procurement | PFR-037, FFR-710 C1–D7a, WFR-014/010/028 | — |
| 6 | ETL E3–E4, mart | S6 Dashboard, Health, Closing | FFR-708 dari WBS | M3 fitur lengkap |
| 7 | Uji kinerja & sinkron | S7 stabilisasi | Uji 509 kolom & PDF | — |
| 8 | **Gate G-SB/ETL/FORM** | | | M4 |
| 9 | **Deploy produksi bersih :5100** + StarRocks produksi | | Pilot (2 proyek, impor LPMS 2) | M5 |
| 10–11 | UAT U01–U31, uji kegunaan (SUS) | perbaikan | perbaikan | M6 BA UAT |
| 12 | Pelatihan & go-live | | | M7 go-live |
| 13–14 | Hypercare, backfill LKP 12 bulan, serah terima operasi | | template tambahan | M8 |

Tim minimum: 2 developer Rails (plugin), 1 data engineer Python (lpms3-data, StarRocks), 1 UI/UX designer (paruh waktu, minggu 1–6), 1 analis bisnis PMO (kamus data & UAT), 1 penguji, 1 admin TI/StarRocks.

---

## 13. RISIKO UTAMA (tambahan terhadap Buku Teknis §9)

| ID | Risiko | P | D | Respons |
|---|---|---|---|---|
| R22 | Template formulir rujukan belum lengkap → formulir generik terlalu lama | 4 | 3 | Prioritaskan SFR-003/006/022/024, FFR-713/714/721, FLP-03, PFR-003/010 untuk diserahkan minggu 0–2 |
| R23 | Sinkron PG→StarRocks tertinggal / gagal | 3 | 4 | Outbox idempoten, retry, alarm, rekonsiliasi harian, rebuild mirror |
| R24 | Akses jaringan 192.168.125.14 → .29:9030 tertutup | 3 | 4 | Minta pembukaan firewall minggu 0; uji D4 di staging |
| R25 | Penggunaan akun root StarRocks oleh aplikasi | 2 | 5 | Root hanya D4; user hak minimum; audit grants |
| R26 | Pengguna menolak WBS diskrit 25 % | 3 | 3 | Granularitas cukup dengan memecah Activity; sosialisasi; aturan bukti |
| R27 | Inkonsistensi aturan antar dokumen (§14) menyebabkan approval salah | 3 | 4 | Keputusan D-v2 sebelum minggu 2; matriks dapat dikonfigurasi |
| R28 | UX kompleks karena banyak formulir | 3 | 4 | Wizard per tahap, isi otomatis dari master, uji kegunaan berulang |

---

## 14. KEPUTUSAN TERBUKA BARU (wajib diputus sebelum minggu 2)

| # | Isu (ditemukan dari dokumen) | Opsi / usulan |
|---|---|---|
| DV1 | Ambang persetujuan berbeda: **BFR-001** (< Rp1 M Es. II, ≥ Rp1 M Es. I) vs **BOG-003** pergeseran anggaran (≤ 200 jt ES II; 200–500 jt ES I & II; > 500 jt Direksi) | Usulan: BFR-001 untuk persetujuan *perubahan* (CR); BOG-003 untuk eksekusi *pergeseran anggaran* di SAP — keduanya berjalan berurutan; konfirmasi PMO & Pengendali Anggaran |
| DV2 | Istilah "Fungsi Pelaksanaan Proyek" (BOP-001) vs "Fungsi Manajemen Proyek" (CLP-001, FFR-708 rev.09) | Pakai CLP-001 di sistem, alias BOP-001 ditampilkan; usulkan penyeragaman pada revisi BOP-001 |
| DV3 | FFR-710 rev.01 vs rev.02 (cover "SFR-710", petunjuk "SFR-070") | Pakai rev.02; konfirmasi kode petunjuk |
| DV4 | Rujukan adendum SOP-009 vs SFR-009 (BOP-001 §5.4.1) | Pakai SOP-009 |
| DV5 | Level WBS: tabel contoh sampai Level 5 Activity, `Settings` sampai Level 7 | Izinkan hingga Level 7; template proyek default Level 0–5 |
| DV6 | Granularitas Kurva-S (bulanan vs mingguan, contoh Kodal mingguan) | Default bulanan; mingguan per proyek bila kontrak meminta |
| DV7 | Sumber nilai bobot LKP: Weight WBS vs harga pekerjaan/nilai kontrak (§5.4.1) | Per proyek: "Bobot = Harga" bila kontrak memakai BoQ berbobot harga |
| DV8 | Template formulir yang belum ada di folder (§6.4) | Serahkan berkas; sementara formulir generik |
| DV9 | Kebijakan BI langsung ke StarRocks (siapa, alat apa) | Role `lpms3_bi` hanya mart; daftar pengguna BI disetujui PMO |

---

## 15. TELUSUR BOP-001 → LPMS3 (tidak ada yang terlewat)

| BOP-001 | Isi | Diwujudkan di |
|---|---|---|
| 1.0 Tujuan | Operational excellence; mutu, anggaran, jadwal, K3L | §0 J1–J7; Project Health (jadwal, biaya, mutu, risiko, K3L, pengadaan) |
| 2.0 Ruang lingkup | Tahapan oleh Pimpro & tim; rujuk PMBOK; boleh diperinci per jenis proyek | Template per jenis kode (FOP-700); tailoring Prediktif/Hibrid/Program/Purnajual |
| 3.1–3.39 Definisi | Baseline, CCM, CR, Baseline 0, Change Log, Deliverable, Dokumen Kontrak, ICC, Issue Log, Kick-Off, Kode Proyek, Kontrak, Lessons Learned, … WBS | Glosarium in-app (tooltip) + objek data: `baseline`, BFR-001, CFR-022, `project`, Issue/LL WP, `wbs_node`, RASCI |
| 4.0 Dokumen terkait | PERDIR MSM-001, SKEP struktur, Nota 021, COP-002, FOP-700/705, HOP-609, POP series, QOP-803/814, ROP-911, ROP series, SOP-001/004/009, VOP series, WOP-207, BOG-003, QOG-001/002 | Lampiran 01 (peta prosedur → langkah); `docs/template-bop001/procedure` |
| 5.0 Lima tahap + pengawasan & penjaminan mutu tiap tahap | | Fase & gate; checklist pengawasan per tahap (§5.6); Quality Status |
| 5.1.1–5.1.3 | Kode Proyek, Pimpro & Tim (≤ 2 minggu), Project Charter | §5.1 (FFR-706, FLP-01, HOP-609, BOT-001) |
| Tabel 1 | RASCI Inisiasi | `ref_rasci` |
| 5.2.1 (9 aspek) | Reviu PMP | §5.2 langkah 2.1 |
| Tabel 2 | RASCI Reviu PMP & peserta Kick-Off | `ref_rasci`, `ref_peserta_rapat` |
| 5.2.2–5.2.3 | Kick-Off → Baseline 0; Top Up (BOG-003) | §5.2 langkah 2.5–2.7 |
| 5.3.1–5.3.8 + Tabel 3 | Eksekusi 8 proses | §5.3 |
| 5.4.1–5.4.11 + Tabel 4, 5 | Pengawasan & pengendalian 11 proses, rapat tinjauan | §5.4 |
| 5.5.1–5.5.4 + Tabel 6 | Selesai 100 %, Terminasi, Purnajual, Arsip | §5.5 |
| 6.0 Formulir terkait | BFR-001, CFR-022, FFR-708, FFR-710, RFR-002, VFR-015, BOT-001 | §6.2 (semua dipetakan penuh) |
| 7.0 Alur/Flow | Swimlane fase + pengawasan tahap | Stepper fase, gate, §5.6 |
| 8.0 Matriks perubahan | Rev.00 → Rev.01 | Versi template formulir (`form_definition.rev`); perubahan BOP-001 berikutnya = perubahan data `ref_*` & `spec_forms.py` |

---

## 16. ISI REPOSITORI `lpms3-v2`

```
README.md                         ← indeks & cara memakai
docs/plan/00_LPMS3_Master_Plan.md ← dokumen ini
docs/plan/01_Katalog_Form_SOP.md  ← peta 78 berkas formulir & prosedur → fase/langkah
docs/plan/02_Kamus_Data_Formulir_dan_SOP.md ← 18 formulir · 43 tabel · 509 kolom (dibangkitkan)
docs/plan/10_Spesifikasi_Teknis_v1.3.md     ← Buku Teknis (deploy rinci, sidebar §12, LKP §13, fungsi §14)
docs/data-dictionary/LPMS3_Data_Dictionary.xlsx, spec_forms.py
docs/wbs/WBS_Template_LPMS.xlsx
docs/template-bop001/form|procedure/        ← sumber resmi (tidak diubah)
db/010_lpms3_forms.sql · 020_lpms3_core.sql · 030_lpms3_seed_ref.sql   (PostgreSQL, teruji PG16)
db/starrocks/000_init.sql · 100 · 110 · 200 · 300 · 990                 (StarRocks default_catalog.lpms3)
deploy/.env.example · deploy/docker-compose.override.yml
ops/starrocks_apply.sh · ops/pg_apply.sh · ops/backup.sh
tools/gen_data_dictionary.py
```

*Setiap perubahan plan atau skema setelah disahkan diproses melalui Change Request dan dicatat di `CHANGELOG.md`.*
