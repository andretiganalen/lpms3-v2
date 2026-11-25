# Hierarki Approval Akun per Fungsi

Dokumen ini mendefinisikan siapa mengerjakan, menyetujui, dan melihat apa di LPMS3, berdasarkan **Fungsi**. Lingkup aplikasi bersifat **global**: satu akun pejabat dapat menangani banyak project.

## 1. Ruang Lingkup dan Istilah

| Istilah | Arti di LPMS3 |
| :-- | :-- |
| Tabel isian | Tabel data yang diisi dan disubmit, mis. Penetapan 9 Aspek PMP. |
| Task list | Daftar tugas (paket-penugasan) yang ditugaskan ke sebuah akun. |
| Job list | Daftar pekerjaan lintas project yang menjadi tanggung jawab sebuah Fungsi. |
| Work order | Penugasan dari atasan ke bawahannya: satu tugas, satu penanggung jawab, satu tenggat. |
| Overview | Ringkasan status satu project. |
| Dashboard | Ringkasan status lintas project untuk satu Fungsi atau tingkat. |
| Resume | Ringkasan tahapan per Fungsi untuk satu periode. |

Hierarki ini berlaku untuk seluruh objek di atas.

## 2. Struktur Fungsi dan Peran

| Tingkat | Fungsi | Induk | Pejabat | Asisten pejabat | Tim |
| :-- | :-- | :-- | :-- | :-- | :-- |
| P1 | Fungsi Direksi Operasi | — (puncak) | P1P | P1A | — |
| P2 | Fungsi [Generik] Eselon 1 | Fungsi Direksi Operasi | P2P | P2A | P2S, P2F |
| P3 | Fungsi [Generik] Eselon 2 | Fungsi Eselon 1 | P3P | P3A | P3S, P3F |

- **Eselon 1 berada di atas Eselon 2.** Fungsi Eselon 2 berinduk ke Fungsi Eselon 1, dan Fungsi Eselon 1 berinduk ke Fungsi Direksi Operasi.
- **Pejabat (P…P)** berkedudukan di Fungsi tingkatnya dan bersifat global. Lingkupnya adalah project yang ditugaskan kepada Fungsinya.
- **Asisten pejabat (P…A)** bekerja atas nama pejabatnya, dengan inbox yang sama dengan pejabat (lihat §4). Asisten tidak menyetujui dan tidak mengirim ke tingkat atas.
- **Tim Eselon 1 (P2S, P2F)** bekerja dalam lingkup Fungsi Eselon 1 dan lintas project. Mereka tidak dibatasi pada tugas yang diberikan.
- **Tim Eselon 2 (P3S, P3F)** hanya mengerjakan **tugas yang diberikan** kepada mereka, berupa work order. Pembatasan ini mengatur pengerjaan (mengisi, submit, dan revisi), bukan melihat. Mereka tetap dapat melihat peer sesuai §5.
- **Plt/Plh:** jika pejabat berhalangan, Plt/Plh yang ditunjuk bertindak sebagai pejabat (lihat §7).

## 3. Definisi Kunci

- **Tingkat aktif** adalah posisi item sekarang: P1, P2, atau P3. Setiap item hanya punya satu tingkat aktif.
- **Status** berlaku di tingkat aktif. Status yang dipakai: **Draft, Reviu, Revisi, Disahkan** (status Dokumen Rencana yang sudah ada).
- **Pengirim terakhir** adalah peran yang terakhir mengirim item ke tingkat aktif. Pengirim terakhir selalu ada, sehingga revisi selalu punya tujuan.
- **Group** adalah Fungsi. Peran setara dalam satu Fungsi berada dalam satu group.
- **Pindah tingkat:** setiap kali item dikirim ke tingkat atas, tingkat aktif berpindah ke atas dan status kembali ke **Reviu**. Setiap kali revisi dikirim, status menjadi **Revisi** di tangan penerima. Jika penerima berada di tingkat yang lebih bawah, tingkat aktif ikut turun. Jika penerima berada di tingkat yang sama (Spesialis ke Staff), tingkat aktif tetap. Riwayat setiap perpindahan tercatat di journal.

## 4. Alur Approval

**Fungsi Eselon 2 (P3):**
1. **Staff P3F → submit ke Spesialis P3S** yang memberi tugas. Tingkat aktif tetap P3, status Reviu.
2. **Spesialis P3S → submit ke Pejabat P3P.** Tingkat aktif tetap P3, status Reviu.
3. **Pejabat P3P menyetujui.** Status menjadi Disahkan di P3. Lalu **P3P submit final ke P2P.** Tingkat aktif pindah ke P2, status Reviu.

**Fungsi Eselon 1 (P2):**
4. **Staff P2F → submit ke Spesialis P2S** yang memberi tugas.
5. **Spesialis P2S → submit ke Pejabat P2P.**
6. **Pejabat P2P menyetujui.** Status Disahkan di P2. Lalu **P2P submit final ke P1P.** Tingkat aktif pindah ke P1, status Reviu. Item final dari P3P diproses di sini sebagai item dari bawah.

**Direksi (P1):**
7. **P1P menyetujui.** Status Disahkan di P1, dan ini adalah pengesahan **final**. Tidak ada tingkat di atasnya.

Setiap submit punya satu penerima. Setiap tingkat dan setiap peran dalam alur ini punya tujuan yang jelas.

## 5. Aksi dan Dampaknya

| Aksi | Status | Dilakukan oleh | Tujuan |
| :-- | :-- | :-- | :-- |
| **Submit** | Draft atau Revisi → **Reviu** | Staff (P…F), Spesialis (P…S), Pejabat P2P dan P3P (submit final) | Satu penerima sesuai §4. P1P tidak submit, karena tingkat puncak. |
| **Menyetujui** | Reviu → **Disahkan** | Hanya Pejabat (P…P) | Pengesahan di tingkat aktif. Pejabat lalu submit final, atau menjadi final bila P1P. |
| **Minta revisi** | Reviu → **Revisi** | Pejabat (P…P), Asisten (P…A) atas nama pejabat, Spesialis (P…S) ke pengirimnya | Catatan wajib. Tujuan sesuai tabel di bawah. |
| **Mengetahui** | Tidak berubah | Pejabat (P…P), Asisten (P…A), Spesialis (P…S) untuk item di Fungsinya | Menandai bahwa item sudah dilihat. Tidak memblokir alur. |
| **Komentar** | Tidak berubah | Semua peran yang dapat melihat item | Catatan tanpa perubahan status. |

**Tujuan revisi:** selalu **pengirim terakhir** item di tingkat aktif. Dengan aturan ini setiap revisi punya tujuan, dan tidak ada tabrakan tujuan.

| Pemberi revisi | Tingkat aktif | Pengirim terakhir (tujuan revisi) |
| :-- | :-- | :-- |
| P1P | P1 | P2P |
| P2P | P2 | P3P (jika item final dari Eselon 2) atau P2S (jika item dari tim Eselon 1) |
| P2S | P2 | P2F |
| P3P | P3 | P3S |
| P3S | P3 | P3F |

Contoh: P2P meninjau item yang disubmit P3P. Revisinya dikirim ke P3P. Jika P2P meninjau item yang disubmit P2S, revisinya dikirim ke P2S.

Setelah revisi diterima, item berstatus **Revisi** di tingkat penerima. Penerima mengerjakan ulang lalu submit, dan status kembali ke Reviu di tingkat yang sama.

**Asisten (P…A):**
- Bertindak atas nama pejabatnya, dengan inbox yang sama dengan pejabat untuk item di tingkat pejabatnya.
- Dapat mengetahui, berkomentar, dan meminta revisi. Revisi dicatat sebagai dikirim **atas nama pejabat** dan tujuannya sama dengan tujuan pejabat (§5 tabel revisi).
- Tidak dapat menyetujui, tidak dapat submit ke tingkat atas, dan tidak dibatasi pada tugas yang diberikan kepadanya.
- Setiap aksi dicatat atas nama asisten dan atas nama pejabatnya.

## 6. Akses Lihat

| Yang dilihat | Siapa | Aturan |
| :-- | :-- | :-- |
| **Tahap** (status dan tingkat aktif) | Semua peran dalam rantai Fungsi, di atas dan di bawah | Setiap peran melihat posisi item. |
| **Isi** (laporan, dokumen, isian tabel) | Pemilik isi, timnya, dan peer | Pemilik dan tim melihat isi yang mereka kerjakan. |
| **Isi naik ke tingkat atas** | Pejabat tingkat atas | Hanya setelah isi **disubmit** dan tingkat aktif sudah berpindah ke atas. Sebelum itu hanya tahap yang terlihat. |
| **Peer** | Peran setara dalam satu Fungsi (group) | Saling melihat isi. |
| **Tugas tim Eselon 2** | P3S, P3F | Hanya mengerjakan tugas (work order) yang diberikan. Mereka tetap dapat melihat peer. |
| **Lingkup tim Eselon 1** | P2S, P2F | Lintas project dalam Fungsi Eselon 1. |
| **Lingkup pejabat** | P1P, P2P, P3P | Semua project yang ditugaskan kepada Fungsinya, lintas project. P2P juga melihat tahap item di Fungsi Eselon 2 di bawahnya. |

Tahap selalu terlihat. Isi tidak naik ke atas sebelum disubmit, sehingga pejabat atas tidak melihat draft yang belum selesai.

## 7. Pencegahan Jalur Buntu

- **Setiap status punya penerima atau tindakan lanjut:**
  - Reviu: menunggu pejabat di tingkat aktif, yang menyetujui atau meminta revisi.
  - Revisi: menunggu penerima revisi, yang mengerjakan lalu submit.
  - Disahkan di P1: final, tidak perlu tindakan lanjut.
  - Disahkan di P2 atau P3: menunggu submit final oleh pejabat yang bersangkutan.
- **Pejabat tidak tersedia:** Plt/Plh yang ditunjuk menjalankan semua tindakan pejabat, termasuk menyetujui dan submit final. Penunjukan dicatat dengan periode berlakunya. Tanpa Plt/Plh, item tetap di tahap Reviu dan terlihat oleh tingkat atasnya.
- **Pengirim tidak tersedia:** revisi tetap dikirim ke pengirim terakhir, dan Plt/Plh pengirim menerimanya. Item tidak pernah dikirim ke peran yang tidak pernah memegangnya.

## 8. Keterkaitan dengan Aplikasi

- **Status:** Draft, Reviu, Revisi, Disahkan, dari Dokumen Rencana yang sudah ada. Tidak ada status baru.
- **Fungsi:** dipetakan ke `lpms3.fungsi_generik`. Induk fungsi dipakai untuk menentukan tingkat. Fungsi Direksi Operasi tidak punya induk.
- **Peran akses di LPMS:**
  - P1P, P2P, P3P, dan asisten P…A: peran global dengan lingkup project yang ditugaskan kepada Fungsinya.
  - P2S dan P2F: peran global lintas project dalam Fungsi Eselon 1.
  - P3S dan P3F: peran per project, dibatasi pada WP yang diberikan.
- **Akun:** setiap pejabat, asisten, spesialis, dan staf punya akun sendiri (IDS per orang). Tindakan dicatat atas nama pelakunya di journal.
- **Istilah:** "Asisten Pejabat (P…A)" di dokumen ini adalah peran yang sama dengan "Admin Teknis" pada spesifikasi U24–U25. Spesifikasi akan diselaraskan dengan istilah ini pada revisi berikutnya.

## 9. Koreksi terhadap Draf Awal

- Revisi P2P ke bawah ditetapkan sebagai "pengirim terakhir", sehingga tidak lagi bertabrakan antara P3P dan P2S.
- Status setelah revisi adalah **Revisi**, bukan Draft.
- Spesialis (P…S) ditambahkan ke aksi Mengetahui dan Minta revisi, sesuai draf awal.
- Asisten (P…A) bekerja atas nama pejabat dengan inbox yang sama. Pembatasan "hanya tugas yang diberikan" hanya berlaku untuk Tim Eselon 2 (P3S, P3F).
- Ditambahkan definisi tingkat aktif, pengirim terakhir, dan group, serta aturan pindah tingkat dan status.
- Ditambahkan §7 untuk mencegah jalur buntu, termasuk Plt/Plh.
