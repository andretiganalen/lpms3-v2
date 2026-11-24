---
name: uix-leno-referensi
description: Referensi UIx LenO (Len Office) yang diukur langsung dari dev-app-intern.len.co.id — token warna, font, ukuran, sidebar (buka/ciut/hover/tingkat 3), header dan panel Notifikasi/Tasklist/Reminder, kartu dan panel kanan, tabel DevExpress, formulir, surat, preview PDF, unduh, LenDocs, mode gelap. Pakai saat membuat atau menyamakan tampilan aplikasi Len (mis. LPMS3 :5100) dengan LenO.
---

# UIx LenO — referensi terukur

Sumber: **https://dev-app-intern.len.co.id/** (judul halaman "LenO Development").

Cara pengukuran:
- Tanggal ukur 2026-11-24. Login IDS dev memakai akun persona uji.
- Ukurannya `getComputedStyle()` di Chrome 151 pada **viewport 1920×1031, zoom 100%**, ditambah isi berkas CSS yang dimuat aplikasi.
- Semua angka di dokumen ini adalah hasil ukur, bukan perkiraan.

Screenshot pendukung ada di `docs/image/template-uix-leno/dev-app-intern/`. Folder itu **jangan di-commit** karena memuat nama karyawan.

> **Penting — zoom.** Screenshot lama di `docs/image/template-uix-leno/*.png` diambil pada zoom browser ±80%. Di sana header tampak 40 px dan sidebar 184 px.
> Pada zoom 100%, ukuran sebenarnya **header 50 px** dan **sidebar 230 px**. Pakai angka di dokumen ini, bukan hasil ukur piksel dari screenshot lama.

---

## 0. Ringkasan cepat (cheat sheet)

| Elemen | Nilai |
|---|---|
| Warna utama | `#ae2524` (hover tombol `#9d2120`, active `#941f1f`, link hover `#6f1817`) |
| Merah aksen menu (teks terpilih/hover) | `#d42522` |
| Latar item menu terpilih | `#facbcf` + garis kanan 3 px `#ae2524` |
| Latar submenu terbuka | `#fafafa` |
| Latar halaman | `#ebeff4` |
| Teks isi | `#5a5c69` (body), `#212529` (kontrol/tabel), `rgba(0,0,0,.85)` (menu/judul AntD) |
| Teks bantu / muted | `#888888` |
| Garis kontrol/tabel | `#d2d2d2` |
| Header | tinggi **50 px**, `linear-gradient(270deg, #ae2524 0%, #781e1b 100%)` (gelap di kiri, terang di kanan) |
| Sidebar | lebar **230 px** (ciut **80 px**), putih, item 40 px, teks 12 px, ikon Font Awesome 6 Pro *light* 14 px |
| Font | **Poppins** (berkas `Poppins-Light.ttf`), body `0.775rem` = **12.4 px**, line-height 1.5 |
| Judul halaman | `p.h3.mb-0.text-gray-800`, **24.5 px / 500**, `#5a5c69` |
| Kartu | putih, border `1px rgba(34,34,34,.125)`, radius 4 px, bayangan `0 8px 16px rgba(0,0,0,.15)` |
| Kepala kartu | latar `rgba(34,34,34,.03)` (≈ `#f8f8f8`), 16 px / 500, padding 8px 20px |
| Kepala panel kanan | latar `#ae2524`, teks putih 16 px / 500 |
| Tabel (DevExpress Grid) | border `#d2d2d2` radius 3 px; kepala `#f2f2f2` 14 px / 600 `#212529`; sel padding 4px 6px |
| Tombol utama | `#ae2524`, teks putih, 14 px, tinggi 30 px, radius 4 px, padding 4px 12px |
| Input | tinggi 30 px, border `1px #d2d2d2`, radius 3 px, 14 px; fokus: border `#d79292` + cincin `0 0 0 2px rgba(174,37,36,.25)` |

---

## 1. Stack dan berkas sumber

Urutan stylesheet yang dimuat sama dengan urutan di bawah. Yang belakangan menang.

| Berkas | Isi |
|---|---|
| `_content/Len.Apps.UI.Base/css/fontawesome/css/all.css` | Font Awesome **6 Pro** (ikon `fal` = light 300, `fa-solid` 900) |
| `_content/AntDesign/css/ant-design-blazor.css` | Ant Design Blazor: menu sidebar, dropdown, tag, drawer, message |
| `_content/DevExpress.Blazor.Themes/blazing-berry.bs4.min.css` | Tema DevExpress Blazor 25.2 (dasar) |
| `_content/Len.Apps.UI.Base/css/leno-light.css` | **Bootstrap 4.6.2 + DevExpress hasil generate ulang dengan warna Len** (±1,8 MB). Berkas inilah yang menetapkan `--primary: #ae2524` dan `body{background:#ebeff4}` |
| `_content/Len.Apps.UI.Base/css/leno-dark.css` | Pengganti `leno-light.css` saat mode gelap |
| `_content/Len.Apps.UI.Base/css/leno.css` | Kustom LenO: Poppins, ukuran shell (topbar 50, sidebar 230/80), override AntD menu, `.leno-tag-*`, scrollbar |
| `_content/Len.Apps.UI.Base/css/lenappsui.css` | Utilitas Len lama: `.bg-len-primary`, avatar, dropzone, dsb. |
| `Len.Apps.UI.styles.css` + `Len.Apps.UI.Base.bundle.scp.css` | CSS ter-scope per komponen Blazor (ManRisk, NavMenu) |

Teknologi: Blazor Server (`blazor.server.js`), jQuery, `bootstrap.bundle`, pdf.js (`len-pdf-viewer.js`, `lendocs-pdf-viewer.js`), cropper, leaflet, dan BlazorColorPicker. `<html>` diberi kelas `dxChrome dxWindowsPlatform …` oleh DevExpress.

---

## 2. Token warna (mode terang)

### 2.1 Variabel Bootstrap (`:root` di `leno-light.css`)

```css
--primary:#ae2524;  --blue:#ae2524;  --purple:#ae2524;      /* biru Bootstrap diganti merah Len */
--secondary:#888;   --gray:#888;     --gray-dark:#343a40;
--success:#31bd3d;  --green:#31bd3d;
--info:#1381f3;     --cyan:#1381f3;
--warning:#fc781b;  --yellow:#fc781b; --orange:#fd7e14;
--danger:#dc3545;   --red:#dc3545;    --pink:#e83e8c;
--light:#ececec;    --dark:#343a40;   --white:#fff;
```

### 2.2 Palet terpakai (hasil ukur)

| Peran | Nilai | Tempat |
|---|---|---|
| Primary | `#ae2524` | tombol utama, tautan, tab aktif, logo, garis kanan menu aktif, tanggal "hari ini" di kalender, kepala panel kanan |
| Primary hover | `#9d2120` | `--dxbl-btn-hover-bg` |
| Primary active | `#941f1f` | `--dxbl-btn-active-bg` |
| Primary disabled | `#ce7c7c` | `--dxbl-btn-disabled-bg` |
| Link hover | `#6f1817` | `a:hover` |
| Aksen menu | `#d42522` | teks/ikon menu terpilih, submenu terbuka, hover menu, angka badge |
| Latar menu terpilih | `#facbcf` | `.ant-menu-item-selected` |
| Latar submenu | `#fafafa` | `.ant-menu-sub` |
| Header gradien | `#781e1b` → `#ae2524` | `.bg-gradient-primary` (270deg) |
| Latar halaman | `#ebeff4` | `body` |
| Teks body | `#5a5c69` | `body`, judul halaman, kepala kartu |
| Teks kontrol | `#212529` | input, tabel, tombol sekunder |
| Teks label form | `rgba(33,37,41,.75)` | `.dxbl-fl-cpt` |
| Teks AntD | `rgba(0,0,0,.85)` | menu, dropdown, judul `h1` |
| Muted | `#888888` | teks bantu italic, ikon refresh panel, link "Tandai sudah dibaca" |
| Teks notifikasi | `#495057` | item panel header |
| Garis | `#d2d2d2` | input, grid, pager, dialog dropdown, kalender |
| Garis kartu | `rgba(34,34,34,.125)` | `.card`, `.card-header` |
| Garis menu | `#f0f0f0` | border kanan `.ant-menu` |
| Kepala tabel | `#f2f2f2` | baris `thead` grid |
| Baris belum dibaca | `#ececec` (`.bg-light`) + teks merah tebal | daftar surat |
| Kepala kartu | `rgba(34,34,34,.03)` (≈ `#f8f8f8`) | `.card-header` |
| Fokus input | border `#d79292`, cincin `rgba(174,37,36,.25)` 2 px | semua editor DevExpress |
| Bayangan fokus tombol | `rgba(174,37,36,.5)` spread 0.125rem | `--dxbl-btn-focus-shadow-color` |
| Akhir pekan kalender | `#dc3545` | `.dxbl-calendar-weekend` |
| Tombol "Today" kalender | `#dedede` | `dxbl-btn-secondary` |

### 2.3 Palet LenDocs

Modul LenDocs memakai gaya yang lebih baru, bernuansa Tailwind.

| Peran | Nilai |
|---|---|
| Merah tua | `#8b1a1a` (tab aktif, pil aktif, ikon, badge garis) |
| Gradien hero dan tombol Unduh | `linear-gradient(135deg, #7a1616 0%, #a82020 60%, #c0392b 100%)` (tombol: `#7a1616 → #a82020`) |
| Teks utama | `#111827` |
| Teks sekunder | `#6b7280` |
| Teks tersier / label | `#9ca3af` |
| Garis | `#e5e7eb` (kartu), `#9ca3af` (pil, select) |
| Hover kartu | border `#d1a0a0`, bayangan `0 6px 20px rgba(139,26,26,.10)` |
| Pil di-hover | latar `#f3f4f6`, teks `#111827` |
| Badge amber | latar `#fef3c7`, teks `#92400e` |
| Link indigo | `#6366f1` ("Lihat Semua") |

### 2.4 Status / tag

`.leno-tag-*` disalin dari AntD Tag (radius 2 px, tinggi 22 px, font 12 px):

| Varian | Teks | Latar | Garis |
|---|---|---|---|
| `error` / `danger` / `red` | `#f5222d` | `#fff1f0` | `#ffa39e` |
| AntD `ant-tag-error` (terukur, mis. "Segera") | `#ff4d4f` | `#fff2f0` | `#ffccc7` |
| `success` / `green` | `#52c41a` | `#f6ffed` | `#b7eb8f` |
| `warning` / `orange` | `#fa8c16` | `#fff7e6` | `#ffd591` |
| `processing` / `blue` | `#1890ff` | `#e6f7ff` | `#91d5ff` |
| `primary` | `#185089` | `#e4f1ff` | `#3279c1` |
| default | `rgba(0,0,0,.85)` | `#fafafa` | `#d9d9d9` |

Tag netral di detail surat, misalnya "Karyawan PT. Len Industri" dan "Terdistribusi", memakai gaya default ini.

---

## 3. Tipografi

- **Font:** `Poppins, "Roboto-Light", "Segoe UI", Arial, "Noto Sans", "Liberation Sans", sans-serif`.
  - LenO hanya memuat satu berkas, **`Poppins-Light.ttf`**, sebagai keluarga `Poppins` tanpa `font-weight`. Akibatnya semua bobot tampil dari glyph Light, dan 500/600 adalah hasil *synthetic bold* browser. Inilah yang memberi kesan tipis khas LenO.
  - Untuk meniru tampilannya, pakai Poppins 300 sebagai bobot normal.
- **Ikon:** Font Awesome 6 Pro, varian `fal` (light 300) hampir di semua tempat, `fa-solid` di LenDocs.
- **Angka di kartu statistik:** font sistem (`-apple-system, …`) 30 px.

| Tingkat | Ukuran / bobot / warna | Contoh |
|---|---|---|
| Body | 12.4 px / 400 / `#5a5c69`, lh 18.6 px | teks bebas |
| Menu sidebar | 12 px / 400 / `rgba(0,0,0,.85)`, lh 40 px | Home, SDM |
| Judul halaman | 24.5 px / 500 / `#5a5c69` (`p.h3.mb-0.text-gray-800`) | Daftar Surat Masuk |
| Sapaan beranda | 21 px / 500 / `#5a5c69` | Selamat Malam, … |
| Subjudul halaman | 10.85 px / 400 / `#888` | teks di bawah judul LenDocs |
| Kepala kartu / panel | 16 px / 500 / `#5a5c69` (panel kanan: putih) | Presensi s.d. … |
| Kepala grup formulir | 16 px / 400 / `#212529` | Definisi Surat |
| Label formulir | 14 px / 400 / `rgba(33,37,41,.75)` | Jenis Surat |
| Nilai formulir / tabel / input | 14 px / 400 / `#212529` | |
| Kepala tabel | 14 px / 600 / `#212529` | Definisi Surat, Pengirim |
| Teks bantu formulir | 12.25 px / italic / `#888` | *Diisi dengan Nomor Surat asli…* |
| Judul panel header (Notifikasi) | 17.5 px / 700 / `#ae2524` | Notifikasi |
| Item panel header | 14 px / 400 / `#495057`; tanggal 12.25 px italic | |
| Banner footer `h1` | 35 px / 500 / `rgba(0,0,0,.85)`; `.lead` 17.5 px / 300; `small` italic 12.25 px `#888` | LenO (Len Office) |
| LenDocs judul kartu | 14 px / 600 / `#111827` | |
| LenDocs label meta | 11 px / 600 / UPPERCASE / letter-spacing .6px / `#9ca3af` | NOMOR DOKUMEN |

---

## 4. Tata letak shell

```
┌────────────┬─────────────────────────────────────────────────────────────┐
│ logo 230×50│ ≡  (header 50px, gradien merah)        ☾  ⓘ  🔔99+ ☑1  Nama  (●)│
├────────────┼─────────────────────────────────────────────────────────────┤
│ sidebar    │ main: margin 65px 16px 16px (di bawah header fixed)         │
│ 230px      │  Judul halaman 24.5px                                       │
│ putih      │  ┌ kartu/panel putih ───────────────────┐  ┌ panel kanan ┐   │
│ (fixed)    │  │                                       │  │ kepala merah │  │
│            │  └───────────────────────────────────────┘  └──────────────┘ │
│ logo Len + │                                                              │
│ DEFEND ID  │                                                              │
│ (fixed,50) │                                                              │
└────────────┴─────────────────────────────────────────────────────────────┘
```

| Bagian | Ukuran / aturan |
|---|---|
| `#sidebarMenu.sidebar` | `position:fixed; top:0; left:0; width:230px; height:calc(100vh - 48px); z-index:99` |
| Blok logo (`a.topbar` di sidebar) | 230×50, padding-left 24 px, logo `img` 80×26 (ciut: ikon 30×30) |
| `.ant-menu.menu-side` | mulai y=50, `height:calc(100vh - 6rem)`, scroll vertikal, `border-right:1px solid #f0f0f0`, bayangan `0 8px 16px rgba(0,0,0,.15)` |
| Logo bawah `.custom-menu-logo` | fixed bawah-kiri, 230×50 putih, padding-top 15 px, logo Len 41×20 + DEFEND ID. Saat ciut: `.custom-menu-logo-collapsed` 80×50 berisi logo Len + teks nama lingkungan (mis. "ITDev"). |
| `.main-wrapper` | `padding-left:230px` (ciut: `.main-wrapper-collapse` 80 px) |
| Header `nav.navbar.bg-gradient-primary.topbar` | `position:fixed; height:50px; margin-left:230px` (ciut 80 px), padding `0 16px 8px`, `z-index:99` |
| `main` | margin `65px 16px 16px`; baris judul `.d-sm-flex.align-items-center.justify-content-between.mb-4` (mb 24 px) |
| Kolom beranda | kiri ≈ 9/12 (kartu statistik 3 kolom, Presensi, Survey, Learning), kanan ≈ 3/12 (**rightbar**: Karyawan Berulang Tahun, Kalender Len, Mobile Applications) |
| Breakpoint | `@media (max-width:786px)`: sidebar disembunyikan, `.navbar-toggler` muncul; Bootstrap sm/md/lg/xl = 576/768/992/1200 |
| Scrollbar | 10 px, thumb `rgba(145,143,143,.30)` radius 20 px, track transparan (`scrollbar-width:thin` di Firefox) |
| Scroll-to-top | fixed kanan-bawah 1rem, 2.75rem persegi, latar `rgba(90,92,105,.5)` |

---

## 5. Sidebar (Ant Design Menu, mode `inline`)

Struktur:

`ul.menu-side.shadow.ant-menu.ant-menu-root.ant-menu-light.ant-menu-inline`
- `li.ant-menu-item` → `span.ant-menu-title-content > a > span > i.fa.fa-fw.fal.fa-<ikon>.mr-2.menu-icon + teks`
- `li.ant-menu-submenu.ant-menu-submenu-inline`
  - `div.ant-menu-submenu-title` (ikon + teks + `i.ant-menu-submenu-arrow`)
  - `ul.ant-menu-sub.ant-menu-inline`
    - `li.submenu-menuitem.ant-menu-item` (tingkat 2)
    - `li.ant-menu-submenu` (tingkat 2 yang punya anak) → `ul.ant-menu-sub` → `li.ant-menu-item` (tingkat 3)

### 5.1 Ukuran per tingkat

| Tingkat | Tinggi | Padding kiri | Margin | Ikon | Teks |
|---|---|---|---|---|---|
| 1 (root) | 40 px, lh 40 | 24 px (judul submenu: kanan 34 px untuk panah) | item `4px 0 8px`, judul submenu `4px 0` | FA light 14 px (`.menu-icon` 17 px di CSS, terukur 14 px), lebar `fa-fw` + `mr-2`/`mr-3`; teks mulai x≈61 | 12 px |
| 2 | 40 px | 28 px (`.submenu-item .ant-menu-submenu-title{padding-left:28px!important}`) | sama | **`fa fal fa-circle` 12 px** + `mr-3` (16 px); teks mulai x≈59 | 12 px |
| 3 | 40 px | **60 px** (`.submenu-menuitem{padding-left:60px!important}`) | sama | tanpa ikon | 12 px |

### 5.2 Keadaan

| Keadaan | Gaya |
|---|---|
| Normal | teks `rgba(0,0,0,.85)`, latar putih |
| Hover (item / judul submenu) | teks **`#d42522`** (tanpa perubahan latar) |
| Terpilih (`.ant-menu-item-selected`) | latar **`#facbcf`**, teks dan ikon **`#d42522`**, `::after` garis kanan **3 px `#ae2524`** (scaleY 0→1, 0.15s `cubic-bezier(.645,.045,.355,1)`) |
| Induk dari item terpilih (`.ant-menu-submenu-selected`) | teks **`#d42522`** (`!important`), latar tetap |
| Submenu terbuka | judul berwarna `#d42522`; panel `ul.ant-menu-sub` berlatar **`#fafafa`**; ikon lingkaran anak ikut merah bila terpilih |
| Panah (`.ant-menu-submenu-arrow`) | 10 px, di x=204, dibentuk dua garis `::before`/`::after` 6×1.5 px `rgba(0,0,0,.85)` radius 2 px diputar ±45° (chevron bawah); terbuka = berputar jadi chevron atas, `transition: transform .3s cubic-bezier(.645,.045,.355,1)` |
| Transisi item | `border-color .3s, background .3s, padding .1s cubic-bezier(.215,.61,.355,1)` |

### 5.3 Ciut (collapsed)

Pemicunya tombol ≡ di header: `button.dxbl-btn.dxbl-btn-link.dxbl-btn-icon-only.nav-link.navbar-icon.text-white.p-2`.

- Sidebar menjadi **80 px** (`.sidebar-collapse{width:80px!important}`). Logo atas berganti ikon Len 30×30. Header dan isi bergeser ke `margin/padding-left:80px`.
- Item hanya menampilkan ikon, dengan padding `0 calc(50% - 14px)`. Teks disembunyikan oleh AntD `ant-menu-inline-collapsed`.
- **Hover pada item yang punya anak** membuka **popup** `.ant-menu-submenu-popup` di sebelah kanan (x=83):
  - Lebar ±193 px, radius 2 px, bayangan AntD.
  - Item 40 px dengan padding kiri 28 px dan ikon lingkaran.
  - Anak tingkat berikutnya ditandai chevron kanan `›` dan dibuka sebagai popup bertingkat.
- Width menu dianimasikan: `transition: width .3s cubic-bezier(.2,0,0,1)`.

### 5.4 Pohon menu lengkap (dev, akun Staf)

Setiap butir menu tingkat atas diikuti nama ikon Font Awesome-nya dalam tanda kurung. Ikon tingkat 2 selalu `fa-circle`; tingkat 3 tanpa ikon.

- **Home** (`fa-home`)
- **SDM** (`fa-users`)
  - Karyawan
  - Delegasi Jabatan
  - Presensi
    - Jadwal Kerja
    - Riwayat Presensi
    - Daftar Perbaikan
    - Lembur
  - Cuti / Izin
    - Buat Pengajuan
    - Pengajuan Saya
    - Perbaikan
    - Penangguhan
    - Kuota Cuti
    - Izin Keluar Kantor
  - Perjalanan Dinas
    - Buat Pengajuan
    - Daftar Pengajuan
    - Export Data SPPD
    - Pengajuan Saya
    - Pengajuan Telat
    - Master Data SAP
    - Monitoring Pembayaran
  - Remunerasi
    - Remunerasi Saya
  - Offboarding
    - Daftar Pengajuan
- **Tata Surat** (`fa-envelope`)
  - Pembuatan Surat
    - Upload Surat Masuk
    - Upload Surat Keluar
    - Konsep Surat Keluar
    - Reservasi Nomor Surat
  - Surat Masuk
  - Surat Keluar
  - Draft Surat Keluar
  - Disposisi Masuk
  - Disposisi Keluar
  - Tembusan Surat
  - Laporan Daftar Surat
- **Len Sign** (`fa-file-signature`)
  - Daftar Dokumen
  - Daftar Dokumen Saya
  - Dokumen Monitoring
- **Helpdesk** (`fa-user-headset`)
  - Pengajuan Tiket Personal
  - Pengajuan Tiket
  - Tiket Masuk
  - Tiket Keluar
  - Knowledge Base
- **KMS** (`fa-book-open`)
  - Knowledge Map
  - SME
  - COP
  - Ask the Expert
- **SKI Management** (`fa-chart-user`)
  - Perencanaan
  - Pelaporan
  - Tugas Tambahan
- **Learning** (`fa-chalkboard-user`)
  - Kelas Saya
  - Kelas Aktif
- **LenDocs** (`fa-books`)
  - Daftar Dokumen
  - Administrator
    - Tambah Dokumen
    - Daftar Unggah Dokumen
    - Report
- **Reservasi** (`fa-book-font`)
  - Ruang Rapat
    - Buat Reservasi
    - Daftar Reservasi
    - Cek Ruangan
  - Komunitas
    - Buat Pengajuan Komunitas
    - Daftar Reservasi
    - Cek Jadwal
  - Tamu
    - Buat Reservasi
    - Daftar Reservasi
  - Meeting
- **e-SPI** (`fa-clipboard-check`)
- **Survey** (`fa-clipboard-list-check`)
  - Survey Saya
  - Survey Aktif
- **Facebox** (`fa-face-viewfinder`)
- **Bantuan** (`fa-question-circle`)

Pola URL: `/sdm/...`, `/tatasurat/...`, `/lensign/...`, `/helpdesk/...`, `/kms/...`, `/ski/...`, `/lms/...`, `/lendocs/...`, `/reservasi/...`.

---

## 6. Header (topbar)

- `nav.navbar.navbar-dark.bg-gradient-primary.topbar.fixed`
  - 50 px, gradien `linear-gradient(270deg, #ae2524 0%, #781e1b 100%)`.
- Kiri: tombol ≡ (ikon putih).
- Kanan (`.navbar-expand.d-flex.align-items-center.ml-auto`), dari kiri ke kanan. Semua ikon `a.nav-link.navbar-icon.text-white` memakai FA light **17.36 px** (`.navbar-icon{font-size:1.4em}`), padding 8 px, dan area klik ±33×33:
  1. `fa-moon` — alih mode gelap (tooltip "Theme"; di mode gelap ikon berganti roda gigi).
  2. `fa-circle-exclamation` — **Reminder**.
  3. `fa-bell` — **Notifikasi**, dengan badge.
  4. `fa-tasks` — **Tasklist**, dengan badge.
  5. Blok nama: nama tebal putih ±13 px + jabatan ±11 px putih, rata kanan.
  6. Avatar bulat 34×34 (`.image-cropper`, radius 50%). Tanpa foto: ikon FA `fa-user-circle` 32 px putih.
- **Badge** (`.ant-badge-count`): tinggi 15 px, radius 8 px, latar **putih**, teks **`#d42522`** 11 px, cincin `box-shadow: 0 0 0 2px #d42522`, posisi di kanan atas ikon (margin-top −15 px). Nilai di atas 99 ditulis `99+`.

### 6.1 Panel dropdown header (DevExpress `dxbl-dropdown`)

Tiga panel memakai pola yang sama: Reminder, Notifikasi, Tasklist.

- **Wadah:** `dxbl-dropdown-dialog.notifications`
  - Lebar `max(25vw, 250px)` (= 480 px di 1920), tinggi maks 400 px dan bisa digulir.
  - Latar putih, border `1px #d2d2d2`, radius 3 px, bayangan `0 4px 8px rgba(0,0,0,.15)`.
  - Muncul tepat di bawah header (y = 49).
- **Kepala `.dropdown-header.mt-1`:** padding `8px 16px`, berisi:
  - Judul **17.5 px / 700 / `#ae2524`** ("Notifikasi", "Tasklist", "Reminder").
  - Ikon refresh `fal fa-rotate` 17.5 px `#888`.
  - Di kanan, tautan bergaris bawah 14 px `#888` (tombol `dxbl-btn-link`): "Tandai sudah dibaca" dan "Hapus Semua" untuk Notifikasi, "Lihat dalam grid" untuk Tasklist.
- **Item `.bg-notification-item`:**
  - Padding `9.5px 20px`, garis bawah `1px rgba(0,0,0,.125)`.
  - Item **belum dibaca** berlatar **`#4f4f4f1c`** (abu transparan). Item sudah dibaca berlatar putih.
  - Isinya:
    - Baris 1: nama pengirim 14 px `#495057`, dengan aksi di kanan: `fa-check-circle` "tandai dibaca" dan `fa-times`, keduanya 13 px `#888`.
    - Baris 2: isi pesan 14 px.
    - Baris 3: tanggal *italic* 12.25 px (format `dd/MM/yyyy`, atau relatif "kemarin, 10:57").
- **Kosong (Reminder):** teks tengah "**Kosong!**" dan "Tidak ada reminder untuk anda", padding `4px 20px`.

### 6.2 Menu profil (Bootstrap dropdown)

- Wadah: `.dropdown-menu.dropdown-menu-right.shadow.animated--grow-in`
  - Lebar ±188 px, padding `8px 0`, latar putih, border `1px rgba(0,0,0,.15)`, radius 4 px, bayangan `0 8px 16px rgba(0,0,0,.15)`.
- Item `.dropdown-item`: 14 px `#212529`, padding `4px 16px`, tinggi 29 px. Ikon `fa-fw mr-2 text-gray-400`.
- Isi: **Profil** (`far fa-id-badge`), **Ganti Password** (`fal fa-key`), **Ganti Personal PIN** (`fal fa-key`), pemisah, **Logout**.

---

## 7. Halaman, kartu, rightbar, footer

### 7.1 Judul halaman

- Elemen: `p.h3.mb-0.text-gray-800`, **24.5 px / 500 / `#5a5c69`**, di baris flex dengan `mb-4`.
- Tombol **Kembali** di halaman detail ditempel di kanan judul:
  - `btn.btn-sm.btn-secondary` putih dengan teks `#212529` 13 px dan ikon `←`.
  - Tinggi 28 px, radius 2.4 px, bayangan `0 1px 4px rgba(0,0,0,.2)`.
- LenDocs menambah subjudul 10.85 px `#888` di bawah judul.

### 7.2 Kartu (`.card.shadow`)

- Latar putih, border `1px rgba(34,34,34,.125)`, **radius 4 px**, bayangan **`0 8px 16px rgba(0,0,0,.15)`**, margin bawah `mb-3` 16 px.
- `.card-header`:
  - Padding `8px 20px`, tinggi 41–46 px, latar `rgba(34,34,34,.03)`, border bawah `rgba(34,34,34,.125)`.
  - Radius `3px 3px 0 0`, judul **16 px / 500 / `#5a5c69`**.
- `.card-body`: padding `12px 20px`.

### 7.3 Kartu statistik beranda

Contoh: Surat Masuk, Disposisi Masuk, Tembusan Masuk.

- Kartu berupa `a.card.py-2` yang bisa diklik. Seluruh kartu berteks `#ae2524`, dengan `transition: color .3s`.
- Label 14 px `rgba(0,0,0,.85)` tipis.
- Ikon FA light ±30 px diikuti angka **30 px** font sistem.

### 7.4 Kotak ringkasan

Contoh: "Izin Pribadi" dan "Terlambat" di kartu Presensi.

- Kotak bergaris `#d2d2d2` dengan kepala `#f8f8f8` berisi judul tengah 16 px.
- Nilai di tengah 18 px. Nilai bermasalah memakai merah `#dc3545`, misalnya "7 jam 21 menit (8 kali)".

### 7.5 Rightbar (kolom kanan beranda)

- **Panel dengan kepala merah** (Karyawan Berulang Tahun, Kalender Len):
  - Kepala `#ae2524`, teks putih **16 px / 500**, tinggi 41 px, padding `8px 20px`.
  - Badan putih.
- **Daftar orang:**
  - Avatar 32 px bulat.
  - Nama **merah** `#ae2524` ±11 px.
  - Unit di bawahnya ±9 px `#ae2524` tipis.
  - Pemisah `1px` abu.
- **Kalender:**
  - Kalender DevExpress berlatar putih, border `#d2d2d2`, kepala navigasi `« ‹ November 2026 › »`.
  - Kolom nomor minggu (opasitas .6, 12 px). Minggu/Sabtu merah `#dc3545`. Hari ini berbingkai 1 px `#ae2524`.
  - Tombol **Today** abu `#dedede` radius 3 px.
- **Mobile Applications:** kepala putih dengan ikon `fa-mobile`, berisi 2 kode QR (iOS/Android).

### 7.6 Footer (akhir beranda)

- Kartu abu tanpa garis atas berisi maskot LenO (dua karakter merah) di kiri.
- `h1` "LenO (Len Office)" **35 px / 500**.
- `.lead` "Aplikasi Sistem Informasi PT. Len Industri (Persero)" 17.5 px / 300.
- `small.font-italic.text-muted` "Information System ©2026" 12.25 px `#888`.
- Di lingkungan Development muncul kartu lipat "› Access Token to API (Hanya muncul ketika Environment di Set Development)".
- Footer aplikasi di sidebar: logo Len + DEFEND ID (lihat §4).

### 7.7 Kartu Learning

- Kartu putih ±240 px dengan gambar 150×150 di tengah.
- Tag biru bergaris "Sharing Knowledge" (`leno-tag-processing`).
- Judul 16 px terpotong `…`, deskripsi 13 px, "Berakhir: dd/MM/yyyy" italic 12 px.
- Tombol merah `fal fa-person-chalkboard` "**Gabung Kelas**" / "Lihat kelas".

---

## 8. Tabel (DevExpress Blazor Grid)

**Pola halaman daftar** (Surat Masuk, Disposisi, Helpdesk, LenSign, Karyawan):

1. **Kartu filter** `.card.shadow.mb-3 > .card-body`, tinggi 96 px. Isinya:
   - **Baris 1:** combo kolom (mis. "Nama Pengirim", ±242 px), combo operator ("Like"), input nilai lebar, tombol `+` (`dxbl-btn-outline-secondary`, tambah kondisi), dan tombol cari merah 22×22 `fa-search`.
   - **Baris 2:** **pager** `« ‹ [1] of 16 › »` dan ukuran halaman `10/20/30/50/100/All` (combo `10 ▾`), lalu jumlah total `/ 56`.
   - Semua kontrol berukuran `dxbl-sm`: tinggi **26 px**, 12 px, border `#d2d2d2`, radius 3 px.
2. **Kartu grid** `dxbl-grid`: latar putih, border `1px #d2d2d2`, radius 3 px. Isinya:
   - Di atas tabel: **tab pemilik** (nama pengguna dalam kotak bergaris, merah, dengan badge jumlah) lalu **tab status** bergaya grup tombol: "Belum Dibaca | Dibaca | Sudah Disposisi | Semua Surat".
     - Grup tombol: tinggi 26 px, garis `#d2d2d2`.
     - Tombol aktif berlatar **biru `#1890ff`** dengan teks putih. Ini gaya tombol grup DevExpress yang tidak di-recolor.
     - Tombol tidak aktif putih dengan teks gelap.

### 8.1 Gaya sel

| Bagian | Nilai |
|---|---|
| Baris kepala | latar **`#f2f2f2`**, sel 14 px / 600 / `#212529`, padding `4px 6px`, tinggi 29 px, garis bawah `1px #d2d2d2`, kepala bisa diurutkan (`dxbl-grid-header-sortable`) |
| Sel isi | 14 px, padding `4px 6px`, `border-left-0 border-right-0`, garis atas antar-baris `1px #d2d2d2`, rata kiri |
| Baris belum dibaca | `tr.font-weight-bold.shadow.text-primary.bg-light` → latar **`#ececec`**, teks **merah `#ae2524` tebal** |
| Baris sudah dibaca | latar putih, teks normal |
| Hover / pilihan | `--dxbl-grid-hover-bg: inherit` (tidak berubah), bingkai fokus `#ae2524` |
| Kolom aksi | kolom pertama 50 px, tombol `btn fal fa-ellipsis-v` (⋮) membuka **AntD dropdown**: menu putih radius 2 px, item 32 px, 14 px, ikon `fal fa-search` "Detail" |
| Sel bertumpuk | `<address>`: `strong` judul merah, baris kedua kategori (INTERNAL), `small` tanggal; pengirim `p.font-weight-bold.text-primary.text-truncate` + `p.font-italic` jabatan |
| Klasifikasi | `a.text-primary > i.fal.fa-file-pdf.text-danger` + kode, di bawahnya tag merah "Segera" (`ant-tag-error`, ikon jam) |
| Kosong | ikon `fa-magnifying-glass-xmark` besar abu + "No data to display", padding `48px 24px` |
| Pager (`--dxbl-pager-*`) | tombol putih border `#d2d2d2`, **halaman aktif `#ae2524` teks putih**, radius 3 px |
| Grup | baris grup dengan tombol expand `›` (Cek Ruangan) |

### 8.2 Tabel sederhana

Contohnya "Status History" di detail surat: Bootstrap `table.table-bordered`.

- Kepala `#f2f2f2` 14 px / 600.
- Sel 14 px dengan garis `#d2d2d2` di semua sisi.
- Kolom nama tebal.

---

## 9. Tab

| Jenis | Gaya |
|---|---|
| DevExpress Tabs (User Helper: User Manual / Kebijakan Aplikasi / FAQ) | tab 40 px, padding `4px 16px`, 14 px; **aktif: teks `#ae2524` + garis bawah 2 px `#ae2524`**; tidak aktif `#212529`; garis pemisah bawah `1px #d2d2d2` |
| FormLayout tab group | variabel sama (`--dxbl-tabs-tab-selected-color:#ae2524`) |
| Grup tombol status (daftar surat) | lihat §8: aktif biru `#1890ff` |
| LenDocs segmented | lihat §13 |
| Tab detail tiket (Data / Riwayat Status) | teks aktif `#ae2524` + garis bawah merah |

---

## 10. Tombol

| Varian | Kelas | Gaya terukur |
|---|---|---|
| Utama | `dxbl-btn dxbl-btn-primary dxbl-btn-standalone` | latar `#ae2524`, teks putih, border `#ae2524`, **14 px, tinggi 30 px, padding 4px 12px, radius 4 px**; hover `#9d2120`; active `#941f1f`; disabled `#ce7c7c` / opasitas 40%; fokus cincin `rgba(174,37,36,.5)` 2 px. Ikon di depan teks, mis. `fal fa-floppy-disk` "Simpan" |
| Outline utama | `dxbl-btn-outline-primary` | transparan, teks dan border `#ae2524`, radius 4 px, 30 px ("Simpan sebagai Draft") |
| Tautan batal | `btn btn-link` | transparan, teks `#ae2524` 14 px, tinggi 36 px ("Batal") |
| Sekunder kecil | `btn btn-sm btn-secondary` | putih, teks `#212529` 13 px, tinggi 28 px, radius 2.4 px, bayangan `0 1px 4px rgba(0,0,0,.2)` ("← Kembali") |
| Tombol editor | `dxbl-btn-outline-secondary text-primary dxbl-text-edit-btn` | putih, teks `#ae2524`, menempel di kanan input, radius `0 3px 3px 0`, 28 px ("Generate") |
| Ikon kecil toolbar | `dxbl-btn-primary dxbl-sm` | 22×22, padding `3px 4px`, radius 3 px, 12 px (cari, tambah) |
| Teks toolbar | `dxbl-btn-text-secondary` | transparan, 30 px, ikon gelap (toolbar PDF) |
| Kalender "Today" | `dxbl-btn-secondary dxbl-sm` | `#dedede`, 26 px, radius 3 px, 12 px |
| Gabung Kelas | Bootstrap `btn-primary btn-sm` | merah, ikon di depan |
| LenDocs | lihat §13 | |
| Unduh (LenDocs) | `dd-btn-primary` | gradien `135deg #7a1616→#a82020`, putih, 13.5 px / 600, tinggi 40 px, radius 10 px, lebar penuh, ikon `fal fa-download` |

Aturan susunan tombol formulir: **[Utama] [Outline] [Batal (link)]** rata kiri di kaki kartu, dengan jarak `mr-2`/`ml-2`.

---

## 11. Formulir (DevExpress FormLayout)

**Struktur:** `.card.shadow > .card-body` (padding `12px 20px`) → `.dxbl-fl` → `.dxbl-group`.

**Grup (`.dxbl-group`)**, misalnya Definisi Surat, Pengirim, Penerima, Klasifikasi Dokumen:
- Kotak putih, border `1px #d2d2d2`, **radius 6 px**, margin `12px 0`.
- Kepala `.dxbl-group-header`: tinggi 41 px, padding `5px 12px`, **16 px / 400 / `#212529`**, latar abu muda, garis bawah `#d2d2d2`, radius `5px 5px 0 0`.
- Sub-grup bersarang (mis. "Tembusan") memakai kepala abu 16 px tebal.

**Item form:** label di atas kontrol.
- Label `.dxbl-fl-cpt` **14 px / 400 / `rgba(33,37,41,.75)`**, tinggi 30 px.
- Kontrol `.dxbl-fl-ctrl` di bawahnya.

**Kontrol:**

| Kontrol | Tag | Gaya |
|---|---|---|
| Teks | `dxbl-text-edit` | tinggi **30 px**, putih, border `1px #d2d2d2`, radius 3 px, input padding `4px 6px`, 14 px `#212529` |
| Combo | `dxbl-combo-box` | sama, plus tombol ▾ (`dxbl-edit-btn-dropdown`, border kiri `#d2d2d2`); daftar: dialog putih border `#d2d2d2` radius 3 px, item 30 px padding `4px 6px` 14 px |
| Tanggal | `dxbl-date-edit` | sama, ikon kalender; format **`dd/MM/yyyy`**; popup kalender 294×293 (lihat §7.5) |
| Memo | `textarea`/`dxbl-memo` | min-tinggi 28 px (tampil ±48 px), bisa diubah ukurannya, border `#d2d2d2` |
| Tag box | `dxbl-tag-box` | penuh lebar, chip pilihan di dalamnya |
| Unggah | `dxbl-upload` | tombol pilih berkas dengan area 36 px |
| Radio / Checkbox | DevExpress / AntD | warna terpilih `#ae2524`, cincin fokus `rgba(174,37,36,.5)` |
| Teks bantu | `small.font-italic` | **12.25 px italic `#888`**, mis. *"Diisi dengan Nomor Surat asli. Apabila tidak ada nomor surat, bisa diisi dengan tanda '-'"*; peringatan merah `#dc3545` italic (*"Pemilihan tanggal harus berurutan."*) |
| **Fokus** | semua editor | border **`#d79292`**, `box-shadow: 0 0 0 2px rgba(174,37,36,.25)`, tanpa outline |

**Contoh tata letak:**
- **Tambah Surat Masuk** (`/tatasurat/suratmasuk/tambah`):
  - Grup Definisi Surat: Jenis Surat (combo), Tanggal Surat (date), Nomor Surat (teks + teks bantu).
  - Grup Pengirim: Instansi, Nama, Jabatan (3 kolom), Alamat (memo).
  - Grup Penerima: Tanggal Terima, Catatan, Struktural, Karyawan, Group (tag box), dan sub-grup Tembusan.
  - Grup Klasifikasi Dokumen, unggah berkas.
  - Kaki: **Kirim Surat** / Simpan sebagai Draft / Batal.
- **Pengajuan Cuti/Izin** (`/sdm/izin/buatpengajuan`):
  - Kartu Kuota Cuti berisi kotak ringkasan "Sisa Cuti Tahunan" dan "Periode Cuti Besar".
  - Jenis dan Perihal (combo), Alamat (memo).
  - Grup "Jadwal Pengambilan Cuti/Izin": kalender inline untuk multi-pilih dengan **Ctrl+Klik**, ringkasan "Selama N hari kerja", dan daftar Hari Libur.
  - Kaki: **Simpan** / Batal.

---

## 12. Surat: detail, preview PDF, unduh

**Detail Surat** (`/tatasurat/surat/detail/{id}`):

- Judul "Detail Surat" diikuti tombol **← Kembali**.
- **Kartu "Definisi Surat":**
  - Kepala 14 px / 500 dengan tag merah "Segera".
  - FormLayout baca-saja dalam 4 kolom:
    - Baris pertama: Kelompok, Jenis Surat, Klasifikasi Dokumen, Tanggal Surat.
    - Berikutnya: Nomor Surat, Pengirim, Pemeriksa, Penerima (tag), Tembusan (kotak bergaris berisi nama, ikon ✓ biru, dan "Terima : dd/MM/yyyy HH.mm.ss").
    - Ringkasan Surat: judul tebal, lalu isi HTML.
    - Lampiran Surat: chip merah bergaris `fal fa-file-pdf` + nama berkas.
    - Status Dokumen (tag), Status History (tabel bergaris, lihat §8.2).
  - Label 14 px `rgba(33,37,41,.75)`; nilai 14 px `#212529`.
- **Grup "File Surat":**
  - Chip nama berkas `.pdf` di atas viewer.
  - **Viewer PDF DevExpress**, lebar penuh, latar abu `#f2f2f2`, border `#d2d2d2`, tinggi ±800 px.
  - Toolbar mengambang di tengah atas: dua kartu putih berbayangan.
    1. Navigasi `|‹  ‹  [halaman ▾]  ›  ›|`.
    2. Zoom `−  [100% ▾]  +`.
  - Tombol toolbar `dxbl-btn-text-secondary` 30 px.
  - Saat kosong tampil "The document does not contain any pages.".
- **Unduh / gagal:**
  - Berkas diambil saat halaman dibuka.
  - Bila gagal, tampil **toast AntD message** di tengah atas: kotak putih padding `10px 16px`, radius 2 px, bayangan AntD, ikon ⓘ kuning, teks "Proses download dokumen gagal.".
  - Lampiran dibuka dengan mengklik chip berkas.
- **Menu aksi baris** di daftar surat: ⋮ → **Detail** (`fal fa-search`).
- Membuka surat dari tab "Belum Dibaca" mengubah statusnya menjadi **Dibaca**. Baris itu kehilangan latar `#ececec` dan teks merah tebalnya.

---

## 13. LenDocs (Pencarian Dokumen) — gaya modul baru

- **Judul:** "Pencarian Dokumen" + subjudul 10.85 px `#888`.
- **Segmented kanan atas:**
  - Kotak putih berisi **Dokumen Internal** (aktif: `#8b1a1a` teks putih, radius 8 px, tinggi 34 px, 14 px / 500) dan **Dokumen Eksternal** (tidak aktif: transparan, teks `#6b7280`).
- **Kartu pencarian:**
  - Input besar 39 px dengan ikon 🔍 di dalam dan placeholder "Cari nama dokumen, nomor dokumen, atau kata kunci…".
  - Tombol **Filter Lanjutan**: outline `#8b1a1a`, radius 6 px, ikon `fa-filter`.
  - **Pil kategori** (`btn-pill`): tinggi 31 px, radius 999 px, 12.8 px / 500, padding `4.8px 13.6px`.
    - Aktif `#8b1a1a` dengan teks putih.
    - Tidak aktif: border `#9ca3af`, teks `#6b7280`, jumlah tebal kecil di kanan. Hover: latar `#f3f4f6`, teks `#111827`.
- **"Terakhir Dipublikasikan":**
  - Kartu putih border `#e5e7eb` radius 12 px, padding `14px 20px`, label `fa-clock` 13.6 px / 600 `#6b7280`.
  - Chip dokumen (`rv-chip`): border `#e5e7eb` radius 8 px, tinggi 50 px. Isinya ikon berkas merah, nama 12.48 px / 500 `#111827`, badge garis merah 9.6 px / 700, nomor 9.6 px `#6b7280`.
  - Tombol bulat ⌄ di bawahnya "N dokumen lainnya".
- **Bar hasil:** "Menampilkan **20** dari **1122** dokumen" + select urutan (border `#9ca3af`, radius 6 px, 12.8 px) + tombol tampilan daftar/kartu (aktif `#8b1a1a`, radius 5 px).
- **Kartu dokumen (`doc-grid-card`):** grid 4 kolom ±406×147.
  - Latar putih, border `#e5e7eb`, **radius 10 px**, padding `14px 16px`.
  - Hover: border `#d1a0a0`, bayangan `0 6px 20px rgba(139,26,26,.10)`.
  - Isi:
    - Ikon tipe `fa-solid fa-file-pdf/-excel/-word` 16 px `#8b1a1a` di kotak lembut.
    - Badge kategori kanan atas: garis `#8b1a1a`, radius 999 px, 10.88 px / 600.
    - Judul 14 px / 600 `#111827`, garis pemisah tipis.
    - Nomor 11.52 px `#6b7280`, tanggal dengan `fa-clock` `#9ca3af`.
- **Klik kartu:** membuka **drawer kanan** (AntD Drawer) 480 px di atas mask `rgba(0,0,0,.45)`.
  - **Hero** gradien `135deg #7a1616 → #a82020 → #c0392b`, padding `28px 24px 48px`, dengan dekorasi lingkaran samar. Isinya:
    - Tombol tutup bulat 30 px: latar `rgba(255,255,255,.18)`, border 2 px `rgba(255,255,255,.25)`.
    - Judul putih ±20 px.
    - Badge amber "Kelompok Tertentu" (`#fef3c7` / `#92400e`, radius 999 px).
  - **Kartu "INFORMASI DOKUMEN"** (radius ±12 px, menumpuk ke hero):
    - Baris meta dengan ikon kotak abu 32 px.
    - Label UPPERCASE 11 px / 600 `#9ca3af` letter-spacing .6px.
    - Nilai 13.5 px / 600 `#111827`.
    - Baris: Nomor Dokumen, Tanggal Pengesahan, Kategori, Jenis, Revisi.
  - **Seksi** "DOKUMEN TERKAIT", "DISTRIBUSI", "RIWAYAT STATUS DISTRIBUSI":
    - Label seksi uppercase abu dan tautan indigo `#6366f1` "↗ Lihat Semua".
    - Keadaan kosong: kotak bergaris dengan ikon abu dan teks "Belum ada …".
  - **Kaki lengket:** tombol **Unduh** (lihat §10).

---

## 14. Overlay lain

| Elemen | Gaya |
|---|---|
| Dropdown AntD (menu aksi) | putih, radius 2 px, padding `4px 0`, bayangan `0 3px 6px -4px rgba(0,0,0,.12), 0 6px 16px rgba(0,0,0,.08), 0 9px 28px 8px rgba(0,0,0,.05)`; item 32 px, padding `5px 12px`, 14 px |
| Toast (AntD message) | tengah atas y=32, putih, padding `10px 16px`, radius 2 px, bayangan sama dengan dropdown AntD, ikon status berwarna |
| Tooltip | hitam, teks putih 14 px (mis. "Theme" pada ikon bulan) |
| Modal DevExpress | `max-width:70%`, `min-width:500px`, margin 1.75rem; `.dxbs-popup-fixed-width{max-width:900px}`; `.tiketModal` 900–1300 px |
| Drawer AntD | lihat §13 |
| Preloader | lingkaran 80 px border 3 px merah `#ff0200` berputar 1.3s, latar `#f7f7f74f`, logo 55 px di tengah |
| Reconnect Blazor | latar `#76828F`, judul `#EDF6FF` |

---

## 15. Kalender jadwal (Jadwal Kerja Personil)

- Tampilan bulan: toolbar `Today ‹ › November 2026 ▾`, kolom Senin–Minggu.
- Nama hari 14 px; Sabtu/Minggu merah.
- Sel tanggal: angka kiri atas 14 px abu, garis `#d2d2d2`. Hari ini ditandai garis atas 3 px `#ae2524`.
- Event:
  - Blok penuh lebar sel, radius 2 px.
  - **Hijau `#198754`** untuk shift kerja ("NS3 - Normal Shift 3"), **merah `#dc3545`** untuk libur ("SOFF - Shift Off").
  - Teks putih 13 px, dengan jam dalam kotak putih kecil bergaris di bawahnya.

---

## 16. Mode gelap (`leno-dark.css`)

Dipicu ikon ☾ di header: `leno-light.css` ditukar dengan `leno-dark.css` dan preferensi disimpan.

| Elemen | Nilai gelap |
|---|---|
| Body | `#161d31`, teks putih |
| Sidebar | `#001529` (AntD dark), teks `rgba(255,255,255,.65)`; item terpilih latar **`#184a81`** teks `#e5e5e5` |
| Header | `linear-gradient(270deg, #184a81 0%, #0d2441 100%)` (biru navy) |
| Kartu | `#283046`, border `rgba(255,255,255,.15)`, radius 3.2 px; kepala `rgba(0,0,0,.03)` teks putih |
| Tombol utama | biru `#184a81` (mis. "Gabung Kelas") |
| Ikon tema | bulan → roda gigi |

---

## 17. Ikon

- Font Awesome 6 Pro **light** (`fal`), lebar tetap `fa-fw`.
- Menu 14 px, header 17.36 px, formulir 12–14 px, toolbar 16–17.5 px.
- Ikon yang sering dipakai:
  - Navigasi: `fa-home`, `fa-users`, `fa-envelope`, `fa-file-signature`, `fa-user-headset`, `fa-book-open`, `fa-chart-user`, `fa-chalkboard-user`, `fa-books`, `fa-book-font`, `fa-clipboard-check`, `fa-clipboard-list-check`, `fa-face-viewfinder`, `fa-question-circle`.
  - Lingkaran submenu: `fa-circle`.
  - Header: `fa-moon`, `fa-circle-exclamation`, `fa-bell`, `fa-tasks`.
  - Daftar dan aksi: `fa-ellipsis-v`, `fa-search`, `fa-file-pdf`, `fa-download`, `fa-rotate`, `fa-check-circle`, `fa-times`, `fa-floppy-disk`, `fa-arrow-left`, `fa-filter`, `fa-clock`.

---

## 18. Token siap pakai (CSS)

Salin blok ini untuk aplikasi Len lain. Nilainya identik dengan hasil ukur di atas.

```css
:root {
  /* warna */
  --leno-primary: #ae2524;  --leno-primary-hover: #9d2120;  --leno-primary-active: #941f1f;
  --leno-primary-disabled: #ce7c7c;  --leno-link-hover: #6f1817;
  --leno-accent: #d42522;            /* teks/ikon menu terpilih & hover */
  --leno-menu-selected-bg: #facbcf;  --leno-submenu-bg: #fafafa;  --leno-menu-border: #f0f0f0;
  --leno-header-from: #781e1b;  --leno-header-to: #ae2524;   /* gelap di kiri, terang di kanan (lihat catatan gradien) */
  --leno-page: #ebeff4;  --leno-surface: #ffffff;
  --leno-text: #5a5c69;  --leno-text-control: #212529;  --leno-text-label: rgba(33,37,41,.75);
  --leno-text-antd: rgba(0,0,0,.85);  --leno-muted: #888888;  --leno-notif-text: #495057;
  --leno-line: #d2d2d2;  --leno-card-line: rgba(34,34,34,.125);  --leno-card-head: rgba(34,34,34,.03);
  --leno-table-head: #f2f2f2;  --leno-row-unread: #ececec;  --leno-notif-unread: #4f4f4f1c;
  --leno-focus-border: #d79292;  --leno-focus-ring: rgba(174,37,36,.25);
  --leno-success: #31bd3d;  --leno-info: #1381f3;  --leno-warning: #fc781b;  --leno-danger: #dc3545;
  --leno-shift-green: #198754;
  /* bentuk & ukuran */
  --leno-header-h: 50px;  --leno-sidebar-w: 230px;  --leno-sidebar-w-collapsed: 80px;
  --leno-menu-item-h: 40px;  --leno-menu-pad-l1: 24px;  --leno-menu-pad-l2: 28px;  --leno-menu-pad-l3: 60px;
  --leno-radius-card: 4px;  --leno-radius-control: 3px;  --leno-radius-btn: 4px;  --leno-radius-group: 6px;
  --leno-control-h: 30px;  --leno-control-h-sm: 26px;
  --leno-shadow-card: 0 8px 16px rgba(0,0,0,.15);
  --leno-shadow-dropdown: 0 4px 8px rgba(0,0,0,.15);
  --leno-shadow-antd: 0 3px 6px -4px rgba(0,0,0,.12), 0 6px 16px rgba(0,0,0,.08), 0 9px 28px 8px rgba(0,0,0,.05);
  /* tipografi */
  --leno-font: "Poppins", "Roboto-Light", "Segoe UI", Arial, "Noto Sans", "Liberation Sans", sans-serif;
  --leno-fs-body: 12.4px;  --leno-fs-menu: 12px;  --leno-fs-control: 14px;  --leno-fs-card-title: 16px;
  --leno-fs-page-title: 24.5px;  --leno-fs-panel-title: 17.5px;  --leno-fs-help: 12.25px;
}
.leno-header { height: var(--leno-header-h); background-image: linear-gradient(270deg, var(--leno-header-to) 0%, var(--leno-header-from) 100%); }
```

Catatan gradien: CSS asli LenO adalah `linear-gradient(270deg, #ae2524 0%, #781e1b 100%)`. Sudut 270deg berarti arah ke kiri, sehingga titik 0% (`#ae2524`, terang) jatuh di **kanan** dan 100% (`#781e1b`, gelap) di **kiri**.

---

## 19. Daftar periksa kesetaraan (untuk aplikasi lain, mis. LPMS3 :5100)

- [ ] Header 50 px dengan gradien 270deg `#ae2524 → #781e1b`; ikon putih 17.36 px; badge putih bercincin `#d42522`
- [ ] Blok logo putih 230×50 di atas sidebar; logo bawah Len + DEFEND ID 50 px
- [ ] Sidebar 230 px (ciut 80 px dengan popup submenu); item 40 px, teks 12 px; padding 24/28/60 px per tingkat; lingkaran di tingkat 2; tingkat 3 tanpa ikon
- [ ] Terpilih: `#facbcf` + teks `#d42522` + garis kanan 3 px `#ae2524`; induk merah; submenu terbuka berlatar `#fafafa`; hover hanya mengubah teks menjadi `#d42522`
- [ ] Latar halaman `#ebeff4`; judul 24.5 px / 500 `#5a5c69`
- [ ] Kartu radius 4 px, bayangan `0 8px 16px rgba(0,0,0,.15)`; kepala `rgba(34,34,34,.03)` 16 px / 500
- [ ] Tabel: kepala `#f2f2f2` 14 px / 600, sel 14 px padding 4×6, garis `#d2d2d2`, baris belum dibaca `#ececec` tebal merah; pager aktif merah
- [ ] Tab: aktif merah bergaris bawah 2 px
- [ ] Tombol utama `#ae2524` 30 px radius 4 px; Batal sebagai tautan merah
- [ ] Input 30 px border `#d2d2d2` radius 3 px; fokus `#d79292` + cincin 2 px `rgba(174,37,36,.25)`; label di atas 14 px `rgba(33,37,41,.75)`
- [ ] Panel header Notifikasi / Tasklist / Reminder 480 px dengan judul merah 17.5 px / 700 dan item belum dibaca `#4f4f4f1c`
- [ ] Font Poppins tipis (Light sebagai normal), body 12.4 px

---

## 20. Catatan pengukuran

- Semua angka diukur di lingkungan **Development**. Produksi `leno.len.co.id` memakai berkas CSS yang sama dari paket `Len.Apps.UI.Base`, tetapi bisa tertinggal atau lebih baru satu versi.
- Penjelajahan bersifat **baca-saja**: formulir tidak dikirim dan tombol Unduh tidak diklik.
  - Mode gelap dinyalakan lalu dikembalikan ke terang (terverifikasi: `leno-light.css` aktif lagi).
  - Satu efek samping yang tidak bisa dihindari: membuka satu surat dari tab "Belum Dibaca" (Surat Edaran 013/SE/UC/XI/2026) mengubah statusnya menjadi "Dibaca" untuk akun persona uji #02.
- Screenshot: `docs/image/template-uix-leno/dev-app-intern/*.png`.
  - Shell: `home`, `sdm-presensi-open`, `sidebar-hover`, `sidebar-collapsed`, `sidebar-collapsed-hover`.
  - Header: `hdr-reminder`, `hdr-notifikasi`, `hdr-tasklist`, `hdr-profil`.
  - Tata Surat: `surat-masuk`, `row-action-menu`, `surat-detail`, `surat-detail-bottom`.
  - Formulir: `form-upload-surat`, `form-cuti`, `form-tiket`, `form-konsep-surat` beserta `*-focus`, `combo-open`, `date-open`.
  - LenDocs: `lendocs`, `lendocs-detail`.
  - Modul lain: `pg-*` (Helpdesk, LenSign, Learning, Karyawan, Reservasi, KMS, Bantuan).
  - Lain-lain: `home-footer`, `dark-home`.
