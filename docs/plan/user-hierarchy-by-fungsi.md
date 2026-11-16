# Hierarki Approval Akun per Fungsi

## 1. Dasar

- Hierarki approval mengikuti **Fungsi** (tabel `lpms3.fungsi_generik`, relasi `induk`), **bukan** struktur organisasi (`org_unit`).
- **Pejabat Eselon 1 berkedudukan di Fungsi Eselon 1.** Pejabat Eselon 2 berkedudukan di Fungsi Eselon 2, yang berinduk ke Fungsi Eselon 1.
- Hierarki ini berlaku untuk tabel, task list, job list, work order, halaman overview, dashboard, dan resume.

## 2. Susunan Fungsi

| Tingkat | Fungsi | Induk Fungsi | Peran akun |
| :-- | :-- | :-- | :-- |
| P1 | Fungsi Direksi Operasi | — (puncak) | P1P, P1A |
| P2 | Fungsi [Generik] Eselon 1 | Fungsi Direksi Operasi | P2P, P2A, P2S, P2F |
| P3 | Fungsi [Generik] Eselon 2 | Fungsi Eselon 1 | P3P, P3A, P3S, P3F |

Setiap Fungsi Eselon 1 memiliki satu set peran P2. Setiap Fungsi Eselon 2 memiliki satu set peran P3.

## 3. Peran per Tingkat

**P1 — Fungsi Direksi Operasi**
- **P1P, Pejabat Direksi:** menerima hasil submit dari Fungsi Eselon 1 (P2P). Dapat menyetujui, mengetahui, berkomentar, dan meminta revisi.
- **P1A, Admin Pejabat Direksi:** gerbang masuk ke akun P1P. Menerima hasil submit dari P2P, dapat berkomentar, dan dapat meminta revisi atas sepengetahuan P1P. Tidak dapat menyetujui.

**P2 — Fungsi [Generik] Eselon 1**
- **P2P, Pejabat Eselon 1:** menyetujui, mengetahui, berkomentar, dan meminta revisi ke Fungsi Eselon 2 di bawahnya. Submit final ke P1P.
- **P2A, Admin Pejabat Eselon 1:** mengetahui, berkomentar, dan meminta revisi ke Fungsi Eselon 2 di bawahnya atas sepengetahuan P2P. Tidak dapat menyetujui.
- **P2S, Spesialis Pejabat Eselon 1:** menerima tugas khusus dari P2P. Submit ke P2P. Menugaskan spesialis di Fungsi Eselon 2. Mengetahui hasil dari Eselon 2, berkomentar, dan meminta revisi ke spesialis Eselon 2 atas sepengetahuan P2P.
- **P2F, Staff Pejabat Eselon 1:** menerima tugas khusus dari P2P dan dari P2S. Submit ke P2P *dan/atau* P2S [perlu konfirmasi, lihat §5], dan berkomentar.

**P3 — Fungsi [Generik] Eselon 2**
- **P3P, Pejabat Eselon 2:** menyetujui, mengetahui, berkomentar, dan meminta revisi ke spesialis di Fungsi Eselon 2. Submit final ke **P2P** (Pejabat Eselon 1, di Fungsi induknya).
- **P3A, Admin Pejabat Eselon 2:** mengetahui, berkomentar, dan meminta revisi ke spesialis Eselon 2 atas sepengetahuan P3P. Tidak dapat menyetujui.
- **P3S, Spesialis Pejabat Eselon 2:** menerima tugas khusus dari P3P. Submit ke P3P. Menugaskan staff dan admin di Fungsi Eselon 2. Mengetahui hasil dari staff, berkomentar, dan meminta revisi ke staff atas sepengetahuan P3P.
- **P3F, Staff Pejabat Eselon 2:** menerima tugas khusus dari P3P dan dari P3S. Submit ke P3P dan P3S [perlu konfirmasi, lihat §5], dan berkomentar.

## 4. Definisi Aksi

Definisi ini diusulkan supaya bisa dipetakan ke status dan journal di OpenProject. Setiap aksi tetap dicatat di riwayat.

| Aksi | Mengubah status? | Siapa | Catatan |
| :-- | :-- | :-- | :-- |
| Submit | Ya, ke **Reviu** | Staff dan Spesialis | Diteruskan ke tingkat di atasnya. |
| Menyetujui | Ya, ke **Disahkan** | Hanya P…P | Pengesahan di tingkat tersebut. |
| Minta revisi | Ya, ke **Revisi** | P…P, P…S, P…A (atas sepengetahuan P…P) | Catatan wajib. Dikembalikan ke penanggung jawab di Fungsi bawahnya. |
| Mengetahui | Tidak | P…P, P…A, P…S | Hanya menandai bahwa dokumen sudah dilihat. |
| Komentar | Tidak | Semua peran | Catatan tanpa perubahan status. |

Aturan tambahan:
- **Admin (P…A) tidak dapat menyetujui**, dan tidak dapat submit ke tingkat atas. Admin hanya dapat berkomentar, mengetahui, dan meminta revisi.
- **Submit final berjenjang:** P3P → P2P → P1P. Setiap tingkat hanya meneruskan setelah tingkatnya sendiri menyetujui.

## 5. Pertanyaan Terbuka

1. **Submit ganda (P2F, P3F):** apakah staff submit ke dua tujuan sekaligus, atau ke satu tujuan dengan tembusan ke yang lain?
2. **Login Admin:** apakah Admin (P…A) login dengan akun sendiri (IDS per orang), atau menumpang akun pejabat? Keputusan ini memengaruhi gerbang Admin di IdsLogin, yang saat ini memakai `IDS_ADMIN_EMAILS` dan akun lokal hard-coded.
3. **Pemetaan ke peran LPMS3:** apakah P1–P3 dipetakan ke `ProjectRole` per project, atau ke grup global Fungsi?
4. **Penamaan:** "Admin Pejabat" di dokumen ini dan "Admin Teknis" di spesifikasi (U24, U25) apakah sama, atau berbeda perannya?
5. **Revisi lintas tingkat:** apakah revisi dari P…P kembali ke pengaju langsung, atau ke penanggung jawab di Fungsi bawahnya?
