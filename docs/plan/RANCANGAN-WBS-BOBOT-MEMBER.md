# Rancangan: Member Proyek Berjenjang, WBS Bobot Cascading, Baseline Otomatis (v2 :5100)

Status: disepakati pemilik 23 Nov 2026. Lingkup hanya v2 (:5100).

## 1. Keputusan pemilik

| Topik | Keputusan |
| :-- | :-- |
| Format WBS | Mengikuti `docs/wbs/WBS_Template_LPMS.xlsx`: bobot cascading, setiap task berbobot 100 % terhadap induknya (`Weight = Weight induk × Weigh Factor`). |
| Weight Factor default | Kurva normal (bell curve) atas urutan anak: anak tengah terbesar, anak tepi terkecil. Dapat diubah; simpan ditolak bila jumlah Weigh Factor saudara ≠ 100 %. |
| PIC | Wajib anggota proyek. Bila tidak ada, wajib memilih Fungsi induk (unit Eselon 1); Pejabat/Admin Eselon 1 tersebut lalu menugaskan timnya ke proyek. |
| Penanggalan PIC | Penugasan mengikuti tanggal rencana WBS (Date Plan Start/Finish). |
| Tim default proyek | Direktur Operasi + Admin Direktur Operasi (unit DIR-3) dan Pejabat Eselon 1 + Admin Pejabat Eselon 1 Fungsi Pelaksanaan Proyek (F-MPR → unit ES1 induknya, DIR-3.1). |
| Pimpro ditetapkan | Pejabat Eselon 2 atasan Pimpro (kepala unit ES2 tempat Pimpro berposisi) otomatis menjadi member. |
| Sumber atasan | `lpms3.position` + `lpms3.user_position` diisi (admin UI + impor CSV), bukan tebakan dari grup. |
| Baseline | Setiap perubahan atribut baseline WBS otomatis membuat versi baseline baru berstatus **draft**; menjadi aktif setelah CR (BFR-001) disetujui rantai persetujuan. |
| Pekerjaan selesai | Saat task mencapai 100 % / Done, rekamnya dibekukan (snapshot) dan tidak ikut berubah oleh baseline berikutnya. |
| Ringkasan ikut berubah | Portfolio, Gantt, Ikhtisar Fase, Kalender. |

## 2. Fase implementasi

| Rilis | Isi |
| :-- | :-- |
| 1.39 | Jabatan pengguna (`position`/`user_position`: admin UI + impor CSV), resolver hierarki, member default berjenjang, Eselon 2 otomatis saat Pimpro ditetapkan. |
| 1.40 | Editor WBS (tabel inline) di atas `lpms3.wbs_node` ↔ work package LPMS; bobot cascading + bell curve; validasi 100 %; aturan PIC. |
| 1.41 | Baseline draft otomatis + aktivasi lewat CR, snapshot pekerjaan Done, sinkron ringkasan Portfolio/Gantt/Fase/Kalender. |

## 3. Hierarki (1.39)

- Posisi dibuat otomatis per `org_unit`: **Kepala** (`is_head`, grade sesuai unit) dan **Admin** (`ADMIN_TEKNIS`).
- `user_position` menyimpan penugasan DEFINITIF/PLT/PLH/DELEGASI dengan `valid_from`/`valid_to`; yang berlaku = hari ini di dalam rentang.
- Resolver:
  - `kepala(unit)`, `admin(unit)`: pemegang posisi aktif.
  - `unit_eselon2_of(user)`: unit posisi aktif user; naik ke induk sampai grade ES2.
  - `unit_eselon1_of_fungsi(kode)`: unit primer `fungsi_unit_map` → naik sampai ES1.
- Peran project yang dipakai: `Direksi` (Direktur Operasi), `Admin Direksi`, `Pejabat Eselon 1`, `Admin Pejabat Eselon 1` (admin: izin Tim Proyek, tidak memutus persetujuan), `Pejabat Eselon 2`, `Pimpro`.
- Pemicu: pembuatan proyek dari pemicu LenO dan perubahan atribut proyek **Pimpro** menambah member; tidak pernah menghapus member yang ditambahkan manual.

## 4. Bobot bell curve (1.40)

Untuk *n* anak, `x_i = -2 + 4·(i + 0,5)/n`, `g_i = exp(-x_i²/2)`, `wf_i = g_i / Σg`, dibulatkan 4 desimal dengan sisa pembulatan ke anak tengah sehingga Σ = 1 tepat. *n* = 1 → 100 %.

## 5. Editor WBS (1.40, terpasang)

- Halaman `/projects/:id/lpms3/wbs` (menu Perencanaan → WBS & Bobot). Satu sel = satu permintaan; server menghitung ulang seluruh pohon (kunci advisory per proyek) dan mengembalikan `<tbody>`.
- Level: 0–3 selalu ringkasan; mulai Level 4 baris tanpa anak = "Level n Activity". Kedalaman maks. Level 7.
- Tanggal dan % Complete hanya di aktivitas; induk = min/maks anak, % Progress = Σ anak.
- % Complete > 0 wajib bukti (lampiran WP). Aktivitas berprogres tidak boleh dipecah/dihapus.
- PIC Fungsi: Kepala/Admin unit ES1 menugaskan pemegang jabatan di unit itu atau di bawahnya; orang tersebut menjadi member "Tim Proyek".
- Work package diubah sebagai Sistem (Project Analis tidak punya `manage_subtasks`), journal mencatat nama editor.

## 6. Baseline otomatis (1.41, terpasang)

- Atribut baseline = struktur/nomor WBS, Tasks, Level, Weight, Date Plan Start/Finish, harga. Progres tidak membuat draft.
- Satu DRAFT dan satu ACTIVE per proyek (`lpms3.baseline.status`). Draft pertama = Baseline 0 (Kick-Off), ditetapkan Pimpro/Project Analis tanpa CR.
- Versi > 0: work package Change Request "BFR-001 Baseline n" dibuat otomatis (Draft, assignee Pimpro). Workflow CR yang ada (Pimpro → Fungsi Pengawasan → Approver CCM) memutuskan: Disetujui → aktif; Ditolak → REJECTED + tombol "Kembalikan ke baseline aktif".
- CR selain Draft mengunci perubahan rencana; WBS yang kembali sama dengan baseline aktif membuang draft + CR Draft.
- Aktivitas 100 % dibekukan (`lpms3.wbs_done_snapshot`); baseline berikutnya memakai nilai rekamnya.
- Aktivasi mengisi Kurva-S bulanan linear (`lpms3.scurve_plan`); Portfolio dan Ikhtisar fase membaca baseline aktif.

