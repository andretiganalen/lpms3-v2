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
| 1.40 | Editor WBS (tabel inline) di atas `lpms3.wbs_node` ↔ work package OpenProject; bobot cascading + bell curve; validasi 100 %; aturan PIC. |
| 1.41 | Baseline draft otomatis + aktivasi lewat CR, snapshot pekerjaan Done, sinkron ringkasan Portfolio/Gantt/Fase/Kalender. |

## 3. Hierarki (1.39)

- Posisi dibuat otomatis per `org_unit`: **Kepala** (`is_head`, grade sesuai unit) dan **Admin** (`ADMIN_TEKNIS`).
- `user_position` menyimpan penugasan DEFINITIF/PLT/PLH/DELEGASI dengan `valid_from`/`valid_to`; yang berlaku = hari ini di dalam rentang.
- Resolver:
  - `kepala(unit)`, `admin(unit)`: pemegang posisi aktif.
  - `unit_eselon2_of(user)`: unit posisi aktif user; naik ke induk sampai grade ES2.
  - `unit_eselon1_of_fungsi(kode)`: unit primer `fungsi_unit_map` → naik sampai ES1.
- Peran project yang dipakai: `Direksi` (Direktur Operasi), `Fungsi Pengawasan Proyek` (para admin, sama dengan akun uji), `Pejabat Eselon 1`, `Pejabat Eselon 2`, `Pimpro`.
- Pemicu: pembuatan proyek dari pemicu LenO dan perubahan atribut proyek **Pimpro** menambah member; tidak pernah menghapus member yang ditambahkan manual.

## 4. Bobot bell curve (1.40)

Untuk *n* anak, `x_i = -2 + 4·(i + 0,5)/n`, `g_i = exp(-x_i²/2)`, `wf_i = g_i / Σg`, dibulatkan 4 desimal dengan sisa pembulatan ke anak tengah sehingga Σ = 1 tepat. *n* = 1 → 100 %.
