# Rancangan Penerima Pemicu LenO untuk LPMS3 v2 (:5100)

Status: **draf untuk dibahas** · 23 Nov 2026 · menggantikan wizard "Add New" di Spesifikasi Teknis v1.3 §12.7 bila disetujui.

## 1. Tujuan

Proyek baru di v2 lahir dari **pemicu LenO**, bukan dibuat manual dari template. Data proyek diambil dari **LPMS-1/2** sehingga tidak diketik ulang. Sesudah pemicu masuk, pekerjaan berikutnya (registrasi, persetujuan, penetapan Pimpro, Kick-Off) muncul sebagai tugas di **Tugas & Notifikasi** (`/lpms3/tugas`).

Di luar lingkup: mengubah v1 (:5000) atau LPMS-2. v2 hanya **membaca** LPMS-2.

## 2. Acuan dari v1 (:5000)

Disimpulkan dari konfigurasi dan *assembly* v1 (source tidak tersedia di server).

| Aspek | v1 | Keputusan v2 |
|---|---|---|
| Masuk | `POST /api/project-trigger`, header `X-Lpms-External-Key`, batas 60/menit | Sama polanya, endpoint sendiri (§4) |
| Pencatatan | Tabel `ProjectTriggerRequests`, unik per kode proyek, status `Received → PendingApproval → Registered → Completed / ImportFailed` | Sama, ditambah log kejadian (§5) |
| Kiriman ulang | Baris `Received` lebih dari 10 menit boleh diklaim ulang | Sama |
| Data LPMS-2 | `DirectSql` memakai **koneksi DB LPMS-3 yang sama** ke database LPMS-2 | **Akun read-only terpisah** (`lpms3_ro`), sesuai §12.7 |
| Gagal baca LPMS-2 | Lanjut dengan draf kosong | Sama, tetapi ditandai jelas dan bisa dicoba ulang |
| Tugas | Admin Pelaksanaan registrasi → Eselon 1 Pelaksanaan setuju (pengusul tidak boleh memutus, #678) → Admin Pengawasan tetapkan Project Analyst | Sama (§6) |

## 3. Arsitektur

```
LenO ──POST /lpms3/api/pemicu-proyek──► Caddy ──► web (plugin LPMS3)
                                                   │ simpan lpms3_project_triggers (status: diterima)
                                                   ▼
                                       PostgreSQL ◄── lpms3-data (Python, loop yang sudah ada)
                                                   │   baca LPMS-2 (PyMySQL, akun read-only)
                                                   │   tulis snapshot JSON → status: data_siap / data_gagal
                                                   ▼
                              Tugas & Notifikasi: registrasi → persetujuan → proyek dibuat → Kick-Off
```

Alasan pembaca LPMS-2 ditaruh di `lpms3-data`, bukan di Rails:
- `lpms3-data` sudah punya PyMySQL dan loop polling PostgreSQL (pola `sync_outbox`).
- Driver MySQL dan kredensial LPMS-2 tidak masuk image OpenProject.
- Firewall ke DB LPMS-2 cukup dibuka untuk satu container.
- Kalau LPMS-2 lambat atau mati, request LenO tetap cepat dijawab (202), tidak menunggu kueri.

## 4. Kontrak API untuk LenO

### 4.1 Kirim pemicu

`POST /lpms3/api/pemicu-proyek`

Header: `X-Lpms3-Key: <kunci>`, `Content-Type: application/json`.

```json
{
  "id_kiriman": "uuid dari LenO (idempotensi)",
  "kode_proyek": "kode proyek LPMS-1/2",
  "lpms2_proyek_id": 123,
  "nota": { "nomor": "...", "tanggal": "2026-11-23" },
  "dikirim_pada": "2026-11-23T08:00:00+07:00"
}
```

Wajib: `id_kiriman`, `kode_proyek`. Lainnya opsional. Ukuran body paling besar 16 KB. Berkas Nota **tidak** dikirim dan tidak diunduh dari URL (cegah SSRF); bila perlu, diunggah Admin saat registrasi.

Jawaban:

| Kode | Arti |
|---|---|
| 202 | Diterima baru, atau kiriman ulang yang sedang diproses. Body: `{ "id", "kode_proyek", "status" }` |
| 200 | Kode proyek ini sudah pernah selesai diproses. Body sama, status akhirnya |
| 400 | JSON tidak sah atau field wajib kosong |
| 401 | Kunci tidak ada atau salah |
| 409 | `kode_proyek` sama tetapi `lpms2_proyek_id` berbeda dari yang tercatat |
| 413 | Body terlalu besar |
| 429 | Lebih dari 60 permintaan per menit per alamat |

### 4.2 Cek status

`GET /lpms3/api/pemicu-proyek/:kode_proyek` (kunci yang sama) → `{ "status", "diperbarui_pada", "proyek_url" (setelah proyek dibuat) }`.

### 4.3 Keamanan endpoint

- Kunci di `deploy/.env` (`LPMS3_LENO_KEYS`, boleh dua nilai dipisah koma agar rotasi tanpa putus). Dibandingkan *constant-time*. Kosong = semua permintaan 401.
- Controller tanpa sesi login, tanpa CSRF, hanya dua aksi di atas (`ActionController::API`). Tidak ada `User.current`; kejadian dari LenO dicatat dengan sumber `leno` tanpa akun pengguna (tidak ada akun layanan yang bisa disalahgunakan).
- Caddy: tidak perlu aturan baru (path diteruskan ke web). OpenProject hanya menerima host resmi (`OPENPROJECT_HOST__NAME`), jadi LenO memanggil alamat itu. Opsional daftar IP LenO di Caddy.
- Log mencatat waktu, alamat, kode proyek, status; **tidak** mencatat kunci atau body mentah.

## 5. Data

Migrasi plugin baru.

`lpms3_project_triggers`

| Kolom | Isi |
|---|---|
| `kode_proyek` | unik |
| `lpms2_proyek_id` | dari LenO atau hasil pencarian LPMS-2 |
| `id_kiriman_terakhir`, `jumlah_kiriman`, `diterima_pada`, `diklaim_pada` | idempotensi dan klaim ulang |
| `status` | lihat §6.1 |
| `snapshot` (jsonb), `snapshot_pada`, `snapshot_galat` | hasil baca LPMS-2 |
| `template_identifier`, `pimpro_id`, `vp_id`, `diusulkan_oleh_id`, `diusulkan_pada` | usulan registrasi |
| `diputus_oleh_id`, `diputus_pada`, `catatan_keputusan` | persetujuan Eselon 1 |
| `project_id` | proyek yang dibuat |
| `lock_version` | cegah dua penulis menimpa |

`lpms3_project_trigger_events`: log *append-only* (siapa, kapan, dari status, ke status, catatan). Dipakai untuk audit dan tampilan riwayat.

Custom field proyek baru **`LPMS-2 Proyek ID`** (unik), menutup kolom `lpms2_project_id` yang masih NULL di mirror StarRocks (CHECKLIST-GOLIVE-D12).

## 6. Alur dan tugas

### 6.1 Status

```
diterima ─► data_siap ─┐
    └──► data_gagal ───┴─► diusulkan ─► disetujui ─► proyek_dibuat ─► selesai
                              ▲              │
                              └─ dikembalikan┘        (dibatalkan: dari mana saja sebelum proyek_dibuat)
```

- `data_gagal` tidak menghentikan alur. Admin bisa **coba baca ulang** atau lanjut dengan isian manual.
- Setiap perpindahan memakai `lock!` dan menulis satu baris event.

### 6.2 Tugas per peran

| Langkah | Siapa | Tugas di `/lpms3/tugas` | Aturan |
|---|---|---|---|
| 1. Registrasi | Admin Fungsi Pelaksanaan Proyek | "Registrasi proyek dari LenO: {kode}" | Pilih template (Prediktif / Hibrid / Purnajual), Pimpro, VP Fungsi Pelaksanaan Proyek. Pratinjau snapshot LPMS-2; field wajib yang kosong ditandai |
| 2. Persetujuan | Pejabat Eselon 1 Fungsi Pelaksanaan Proyek | "Setujui registrasi proyek {kode}" | Setujui atau kembalikan (catatan wajib). **Pengusul tidak boleh memutus** walaupun memegang dua peran. Tidak ada jalan pintas `admin?` |
| 3. Proyek dibuat | sistem | notifikasi ke Pimpro dan VP | `Projects::CopyService` dari template, isi Kode Proyek, LPMS-2 Proyek ID, atribut kontrak, anggota (Pimpro) |
| 4. Isi awal 9 Aspek PMP | sistem | — | Isi aspek dari snapshot bila ada sumbernya; aspek tanpa sumber diberi catatan "isi manual" (sama seperti v1). Status tetap Draft, lewat rantai persetujuan biasa (rilis 1.34) |
| 5. Kick-Off | sistem, lalu Admin Fungsi Pengawasan Proyek | "Tunjuk Project Analis" | **Diputuskan 23 Nov 2026:** Kick-Off dibuat setelah Dokumen Inisiasi disetujui Final, sama seperti sekarang (`Lpms3::Kickoff.ensure_for!`). Pemicu LenO tidak membuat Kick-Off dan tidak menetapkan Project Analis (berbeda dari v1) |

### 6.3 Peran global baru

Registrasi dan persetujuan terjadi **sebelum proyek ada**, jadi tidak bisa memakai peran proyek. Dibutuhkan dua `GlobalRole` (diseed, seperti "Keuangan"):
- **Admin Fungsi Pelaksanaan Proyek**: izin `lpms3_register_project_trigger`.
- **Pejabat Eselon 1 Fungsi Pelaksanaan Proyek**: izin `lpms3_approve_project_trigger`.

Pemegangnya ditetapkan di Administrasi. Sesuai hierarki per Fungsi (`user-hierarchy-by-fungsi.md`), keduanya tidak mendapat akses ke proyek lain dari peran ini.

## 7. Pembaca LPMS-2 (`lpms3-data`)

- Loop: ambil `lpms3_project_triggers` berstatus `diterima` (atau `data_gagal` yang diminta coba ulang), `FOR UPDATE SKIP LOCKED`, batas waktu kueri 30 detik.
- Koneksi: `LPMS2_DATABASE_URL` di `deploy/.env`, akun **`lpms3_ro`** (hanya `SELECT`), dibuka per batch lalu ditutup. Kode hanya menerima satu pernyataan `SELECT` (seperti `DirectSqlExecutor` v1).
- Sumber (sama dengan yang dibaca v1): `lpms_proyek` (dicari lewat `kodeproyek`, `recordstatus` aktif), `lpms_requestplanning`, `lpms_proyekruanglingkup`, `lpms_proyektermin`, `lpms_proyekjaminan`, `lpms_pis`, `lpms_datasph`, `lpms_kursproyek`. Lebih baik lagi bila DBA LPMS-2 menyediakan view `v_lpms3_project` dan kawan-kawan (§12.7) sebagai kontrak.
- Pemetaan kolom di `lpms3/templates/lpms2_mapping.yml`, bisa diubah tanpa ubah kode.
- Hasil: `snapshot` JSON per tabel + daftar tabel yang gagal dibaca. Tidak ada tulisan langsung ke tabel OpenProject; pembuatan proyek tetap di Rails.

## 8. Pengujian

Smoke `lpms3/smoke/pemicu_leno.rb` (data uji dihapus di akhir) dan uji Python untuk pembaca:
- 401 tanpa kunci / kunci salah; 202 pertama; kiriman ulang `id_kiriman` sama → 202, tidak ada baris ganda; `lpms2_proyek_id` beda → 409; body > 16 KB → 413; 61 permintaan/menit → 429.
- Baris `diterima` macet > 10 menit diklaim ulang oleh kiriman ulang.
- LPMS-2 tidak terjangkau → `data_gagal`, alur tetap bisa lanjut, coba ulang berhasil.
- Pengusul yang juga Eselon 1 tidak bisa menyetujui usulannya sendiri; admin OpenProject tanpa peran global juga tidak bisa.
- Proyek dibuat sekali walau tombol setujui ditekan dua kali; Kode Proyek dan LPMS-2 Proyek ID terisi; anggota Pimpro terpasang.
- Mirror StarRocks menerima `lpms2_project_id`.

## 9. Tahapan rilis

| Rilis | Isi | Bisa diuji tanpa LenO/LPMS-2? |
|---|---|---|
| 1.35 ✅ | Endpoint, tabel, status, log, kunci, batas laju; halaman daftar pemicu untuk admin (Administrasi → Pemicu LenO). Smoke `lpms3/smoke/pemicu_leno.sh` 22/22 | Ya (curl) |
| 1.36 | Pembaca LPMS-2 di `lpms3-data` + `lpms2_mapping.yml` | Butuh akses DB LPMS-2 dev |
| 1.37 ✅ | Peran global, tugas registrasi dan persetujuan, pembuatan proyek dari template (`/lpms3/pemicu/:id`). Smoke `pemicu_registrasi.rb` 33/33 | Ya |
| 1.38 | Isi awal 9 Aspek, sambungan ke Kick-Off, smoke penuh | Ya |
| Go-live | LenO menambahkan v2 sebagai tujuan kedua; jalan paralel dengan v1 | Butuh tim LenO |

## 10. Pertanyaan terbuka

1. **Pengiriman dari LenO:** apakah tim LenO bersedia mengirim pemicu ke v2 **di samping** v1 selama masa paralel? v1 tidak boleh diubah, jadi v1 tidak bisa meneruskan.
2. **Akses LPMS-2:** siapa yang membuat akun `lpms3_ro` dan membuka firewall dari server v2 ke DB LPMS-2? Bisakah DBA menyediakan view kontrak?
3. **Format Kode Proyek:** custom field v2 memaksa pola `XXX-XXXXXXXX`. Apakah `kodeproyek` LPMS-1/2 selalu cocok? Kalau tidak, pola harus dilonggarkan atau kode dipetakan.
4. ~~**Urutan Kick-Off**~~ — **diputuskan 23 Nov 2026:** Kick-Off setelah Dokumen Inisiasi disetujui Final (urutan v2 dipertahankan).
5. ~~**Pemilihan template**~~ — **diputuskan 23 Nov 2026:** dipilih Admin Fungsi Pelaksanaan Proyek saat registrasi.
6. **Proyek yang sudah ada di v2** dengan Kode Proyek sama: tautkan ke pemicu atau tolak?
