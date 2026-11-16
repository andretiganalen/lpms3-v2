# Hierarki Approval Akun per Fungsi

Dokumen ini mendefinisikan siapa mengerjakan, menyetujui, dan melihat apa di LPMS3, berdasarkan **Fungsi**. Lingkup aplikasi bersifat **global**: satu akun pejabat dapat menangani banyak project.

## 1. Ruang Lingkup dan Istilah

| Istilah | Arti di LPMS3 |
| :-- | :-- |
| Tabel isian | Tabel data yang diisi dan disubmit, mis. Penetapan 9 Aspek PMP. |
| Task list | Daftar tugas (paket-penugasan) yang ditugaskan ke sebuah akun. |
| Job list | Daftar pekerjaan lintas project yang menjadi tanggung jawab sebuah Fungsi. |
| Work order | Penugasan tertulis dari atasan ke bawahannya: satu tugas, satu penanggung jawab, satu tenggat. |
| Overview | Ringkasan status satu project. |
| Dashboard | Ringkasan status lintas project untuk satu Fungsi atau level. |
| Resume | Ringkasan tahapan per Fungsi untuk satu periode. |

Hierarki ini berlaku untuk seluruh objek di atas: tabel isian, task list, job list, work order, overview, dashboard, dan resume.

## 2. Struktur Fungsi dan Peran

| Tingkat | Fungsi | Induk | Pejabat (global) | Tim |
| :-- | :-- | :-- | :-- | :-- |
| P1 | Fungsi Direksi Operasi | — (puncak) | P1P | P1A (Admin Pejabat) |
| P2 | Fungsi [Generik] Eselon 1 | Fungsi Direksi Operasi | P2P | P2A, P2S, P2F |
| P3 | Fungsi [Generik] Eselon 2 | Fungsi Eselon 1 | P3P | P3A, P3S, P3F |

- **Pejabat Eselon 1 (P2P) berkedudukan di Fungsi Eselon 1.** Satu akun P2P dapat menangani banyak project.
- **Pejabat Eselon 2 (P3P) berkedudukan di Fungsi Eselon 2**, yang berinduk ke Fungsi Eselon 1. Lingkupnya adalah project yang ditugaskan kepada Fungsi Eselon 2-nya.
- **"Bawahnya" berarti dari P2x ke P3x.** Tidak ada level lain di antaranya.
- **Tim Eselon 2 (P3A, P3S, P3F) hanya mengerjakan tugas yang diberikan** kepada mereka, berupa work order.
- **Tim Eselon 1 (P2A, P2S, P2F) tidak dibatasi pada tugas yang diberikan.** Eselon 1 berada di atas Eselon 2, sehingga pembatasan tugas hanya berlaku dari Eselon 2 ke bawah. Tim Eselon 1 bekerja dalam lingkup Fungsi Eselon 1 dan lintas project.
- **Admin Pejabat (P…A)** adalah asisten pejabatnya. Admin tidak menyetujui dan tidak mengirim ke tingkat atas. Admin hanya bertindak atas nama pejabatnya (lihat §4).

## 3. Alur Approval

Setiap item bergerak dari tim ke pejabat, lalu ke tingkat di atasnya. Setiap langkah punya tujuan yang jelas:

**Fungsi Eselon 2 (P3):**
1. **Staff P3F → submit ke Spesialis P3S** yang memberi tugas (satu tujuan).
2. **Spesialis P3S → submit ke Pejabat P3P.**
3. **Pejabat P3P menyetujui** (status Disahkan di tingkat P3) lalu **submit final ke P2P** (Pejabat Eselon 1).

**Fungsi Eselon 1 (P2):**
4. **Staff P2F → submit ke Spesialis P2S** yang memberi tugas.
5. **Spesialis P2S → submit ke P2P.**
6. **Pejabat P2P menyetujui** lalu **submit final ke P1P** (Direksi). Hasil P3P yang diteruskan ke P2P diproses di sini.

**Direksi (P1):**
7. **P1P menyetujui** (Disahkan) atau **meminta revisi ke P2P**.

Tidak ada tujuan ganda. Setiap submit punya satu penerima.

## 4. Aksi dan Dampaknya

| Aksi | Status | Dilakukan oleh | Tujuan (jika ada) |
| :-- | :-- | :-- | :-- |
| **Submit** | Draft/Revisi → **Reviu** | Staff, Spesialis, Pejabat (submit final) | Penerima sesuai §3. Tidak ada tujuan lain. |
| **Menyetujui** | Reviu → **Disahkan** | Hanya Pejabat (P…P) | Dicatat sebagai pengesahan di tingkatnya. Pejabat lalu submit final ke tingkat atas. |
| **Minta revisi** | Reviu → **Revisi** | Pejabat (P…P), atau Admin atas sepengetahuan pejabatnya | Catatan wajib. Lihat tujuan revisi di bawah. |
| **Mengetahui** | Tidak berubah | Pejabat (P…P) dan Admin (P…A) | Menandai bahwa item sudah dilihat. Tidak memblokir alur. |
| **Komentar** | Tidak berubah | Semua peran yang dapat melihat item | Catatan tanpa perubahan status. |

**Tujuan revisi (selalu satu, selalu ke bawah satu tingkat):**
- **P1P → P2P.**
- **P2P → P3P** (pejabat Eselon 2 di Fungsi bawahnya), bukan ke tim.
- **P3P → P3S** (Spesialis yang submit), lalu P3S → P3F.
- **P2P → P2S** (Spesialis yang submit), lalu P2S → P2F.

Setelah revisi, item kembali ke **Draft** di tangan penerima revisi. Penerima wajib submit ulang. Tidak ada status yang menggantung tanpa penerima.

**Admin (P…A):**
- Dapat mengetahui, berkomentar, dan meminta revisi **atas sepengetahuan pejabatnya**, untuk item di Fungsinya.
- Tidak dapat menyetujui atau submit ke tingkat atas.
- Setiap aksi Admin dicatat atas nama Admin dan atas sepengetahuan pejabat.

## 5. Akses Lihat

| Yang dilihat | Siapa | Aturan |
| :-- | :-- | :-- |
| **Tahap** (status dan sudah sampai level mana) | Semua peran dalam rantai Fungsi | Setiap level melihat posisi item, termasuk level bawah. |
| **Isi** (laporan, dokumen, isian tabel) | Level pemilik isi, timnya, dan peer | Level bawah dan tim melihat isi yang mereka kerjakan. |
| **Isi di level atas** | Pejabat tingkat atas | Hanya setelah isi **disubmit** oleh level bawahnya (status Reviu atau lebih). Sebelum itu, hanya tahap yang terlihat. |
| **Peer** | Peran setara dalam satu group (mis. P3P dengan P3P, P3S dengan P3S) | Saling melihat isi. |
| **Tugas tim Eselon 2** | P3A, P3S, P3F | Hanya tugas (work order) yang diberikan kepada mereka. |
| **Lingkup tim Eselon 1** | P2A, P2S, P2F | Lintas project dalam Fungsi Eselon 1. Tidak dibatasi pada tugas yang diberikan. |
| **Lingkup pejabat** | P1P, P2P, P3P | Semua project yang menjadi lingkup Fungsinya, lintas project. |

Tahap selalu terlihat, sedangkan isi tidak naik ke atas sebelum disubmit. Dengan begitu level atas tidak melihat draft yang belum selesai.

## 6. Keterkaitan dengan Aplikasi

- **Status:** memakai status Dokumen Rencana yang sudah ada: **Draft, Reviu, Revisi, Disahkan**. Tidak ada status baru.
- **Fungsi:** dipetakan ke `lpms3.fungsi_generik` (induk untuk tingkat), bukan ke `org_unit`.
- **Peran akses:** Pejabat P…P dan P…A menjadi peran global (lintas project) di OpenProject. Tim Eselon 2 (P3A, P3S, P3F) menjadi peran di tingkat project dan dibatasi pada WP yang diberikan. Pejabat (P1P, P2P, P3P) dan tim Eselon 1 (P2A, P2S, P2F) menjadi peran global lintas project.
- **Akun Admin:** setiap Admin punya akun sendiri (IDS per orang, bukan akun pejabat). Tindakannya dicatat atas nama dirinya dan atas sepengetahuan pejabatnya di journal.
- **Istilah:** "Admin Pejabat" (P…A) di dokumen ini adalah peran yang sama dengan "Admin Teknis" pada spesifikasi U24–U25. Spesifikasi akan diselaraskan dengan istilah ini pada revisi berikutnya.
