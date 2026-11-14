# Daftar Pra-Go-Live D12 (status per 2026-11-14)

Acuan: Buku Teknis §7.4 dan Master Plan §11. Legenda: ✅ selesai · 🟡 sebagian · ⛔ belum · 👤 butuh keputusan/tindakan pihak lain.

## A. Checklist resmi §7.4
| # | Butir | Status | Keterangan / tindakan |
|---|---|---|---|
| 1 | BA Gate Sidebar (G-SB) ditandatangani; image produksi = image teruji | ⛔ 👤 | Sidebar/plugin belum selesai; tema UIx belum pernah dicek visual. Catat tag + digest image yang diuji |
| 2 | UAT ≥ 95% lulus, 0 defect kritikal, BA UAT | ⛔ 👤 | Smoke D10: 22 PASS, 0 FAIL, 5 N/A. UAT penuh U01–U31 belum (lihat bagian C) |
| 3 | Password admin bawaan diganti/dinonaktifkan, 2FA admin aktif | ⛔ | Ada 3 akun admin aktif. Periksa akun `admin` bawaan dan aktifkan 2FA |
| 4 | Backup harian ≥ 7 hari berturut-turut + 1 restore drill | 🟡 | Drill sukses (9–19 dtk). Backup baru berjalan sejak 12 Nov (~3 hari); cron 02:00 aktif — tunggu sampai ≥ 7 hari |
| 5 | `OP_TAG` & `LPMS3_IMAGE_TAG` dipin dan dicatat di CHANGELOG | ✅ | 2026-11-14: rilis `17.9.7-lpms3.1.0`; base OP, postgres 17.11, memcached 1.6.45 dipin per digest (lihat CHANGELOG). Ganti tag hanya lewat prosedur upgrade |
| 6 | Monitoring & alert aktif (§8.2) | ⛔ | Belum ada. Minimal: alert untuk `ALARM` outbox di log `lpms3-data`, health check, disk, backup gagal |
| 7 | Data pilot bersih | ⛔ | Lihat bagian B |
| 8 | Komunikasi go-live dikirim | ⛔ 👤 | URL `http://192.168.125.14:5100` + kontak dukungan |
| 9 | Berita acara go-live oleh System Owner | ⛔ 👤 | Fungsi PMO (business owner), TI (technical owner) |

## B. Pembersihan data sebelum go-live
- [ ] Hapus user `pimpro.demo`, proyek `demo-nvg-monocular-100`, dan `lpms3/seed/demo_project.rb`.
- [ ] Hapus proyek bawaan OpenProject "Demo project" dan "Scrum project".
- [ ] Batasi visibilitas proyek template (`lpms3-tpl-*`) hanya untuk PMO/Admin. Saat ini terlihat oleh user yang mewarisi keanggotaan grup.
- [ ] Pastikan tidak ada sisa data uji (smoke D10 menghapus datanya sendiri; periksa `smoke-d10%`).
- [ ] Hapus file `.env` di root repo (berisi kredensial root StarRocks produksi; sudah git-ignored). Pertimbangkan rotasi password root.
- [ ] Pastikan `STARROCKS_ROOT_PASSWORD` kosong di `deploy/.env` (D6).
- [ ] Setelah hapus data demo: jalankan `select lpms3.sync_backfill();` bila perlu, lalu rekonsiliasi mirror StarRocks.

## C. Kekurangan fungsional yang diketahui
**Skenario UAT belum terlayani (N/A di smoke):** U02 due date +14 hari; U03 validasi kriteria gate; U11/U12 validasi NCR kritikal dan lampiran BA; U16 sub-project purnajual otomatis.
**Belum diuji:** U04, U05 (risalah CFR-022 + Baseline 0), U07 (adendum), U13 (FFR-708 + kurva-S), U17 (Terminasi), U19 (email), U20 penuh (jalankan OpenProject di atas DB hasil restore), U21–U31 (sidebar, Add New LPMS 2, Procurement Pipeline, LKP, WBS Template, FLP-01, BOG-003, FFR-710, FOP-705).
**Belum dibuat:** meeting template, S/C sebagai field user, penataan form tipe, tema/sidebar plugin (D11 Spesifikasi §12.8).

## D. Data & integrasi
- [ ] **Data HC:** posisi dan user belum dimuat (D8). Jenjang diasumsikan Direktorat=DIREKSI, Divisi=ES1, Bagian=ES2 — konfirmasi dengan SKEP 001/2026.
- [ ] **SMTP (D2):** belum dikonfigurasi (`ECONNREFUSED localhost:25`). Perlu untuk notifikasi U19.
- [ ] **Kolom mirror StarRocks yang masih NULL:** `jenis_kode`, `kelas_kontrak`, `lini_bisnis`, `current_phase`, `lpms2_project_id`, `nik`, `sr_login` — tentukan sumbernya. Field user (Pimpro/Sponsor) dan `tgl_mulai` terisi hanya bila custom field diisi.
- [ ] **Snapshot harian StarRocks:** tidak ada repository BACKUP (`SHOW REPOSITORIES` kosong). Minta admin StarRocks; sementara mirror dapat dibangun ulang dari PG.
- [ ] **Koneksi LPMS 2 (read-only)** untuk "Add New" (Spesifikasi §12.7): belum ada.
- [ ] Konfirmasi nama database StarRocks `medallion_lpms` dan perbarui dokumen yang masih menyebut `lpms3` / host `192.168.125.29`.

## E. Keamanan & operasional
- [ ] Akses hanya LAN/VPN Len (UFW/subnet); bila publik → TLS + WAF.
- [ ] Password admin: ganti, simpan di pengelola rahasia; `SECRET_KEY_BASE` tidak boleh diganti setelah go-live.
- [x] Pin `TAG` Postgres/OP (jangan floating `17-slim`); catat di CHANGELOG. (2026-11-14)
- [ ] Alarm: entri outbox `attempts ≥ 10` (log `lpms3-data`), rekonsiliasi harian berselisih, backup gagal.
- [ ] Uji ulang idempotensi seed di produksi bersih (`lpms3/seed/run.sh`) dan jalankan `lpms3/smoke/run.sh`.
- [ ] Pelatihan (Spesifikasi §7.3) dan Wiki "LPMS3 Help Center" (Bahasa Indonesia).
- [ ] Rencana hypercare 2 minggu (§7.5) dan jalur eskalasi.

## F. Urutan eksekusi yang disarankan
1. Selesaikan data HC + SMTP + sumber kolom mirror (bagian D).
2. Bangun fitur plugin yang dibutuhkan UAT (bagian C), lalu UAT U01–U31.
3. Admin StarRocks memasang repository snapshot; tunggu backup ≥ 7 hari.
4. Bersihkan data (bagian B), pin tag image, aktifkan monitoring dan 2FA.
5. Restore drill ulang + smoke test pada produksi bersih → BA UAT dan BA G-SB.
6. Komunikasi go-live → BA go-live → hypercare.
