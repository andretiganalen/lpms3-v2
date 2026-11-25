# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# See COPYRIGHT and LICENSE files for more details.
#++

# LPMS3 MOD-03: metadata 35 fitur in-house (30 utama + 5 kompatibilitas) dari Bagian 3
# docs/plan/openproject_custom_plan.md. Klaster F hanya punya deskripsi di plan; tujuan dan output
# klaster F ditulis oleh tim LPMS3. Ini data tampilan saja; BUKAN gerbang lisensi LPMS.
class InhouseFeatureCatalog
  Feature = Struct.new(:key, :cluster, :title, :menu_location, :description, :objective, :expected_output,
                       keyword_init: true) do
    def implemented? = OpenProject::Lpms3::Features.implemented?(key)
    def enabled? = OpenProject::Lpms3::Features.enabled?(key)
  end

  CLUSTER_TITLES = {
    "A" => "Klaster A: Sentralisasi Identitas, SSO IDS & Kapasitas Pengguna",
    "B" => "Klaster B: Perencanaan Eksekutif, Visualisasi & Tata Kelola Portofolio",
    "C" => "Klaster C: Otomasi Alur Kerja, Kustomisasi Atribut & Kalkulasi Data",
    "D" => "Klaster D: Kolaborasi Terkontrol, Integrasi Penyimpanan & AI/MCP",
    "E" => "Klaster E: Keamanan Siber, Audit Operasional & White-Labeling",
    "F" => "Klaster F: Kunci Kompatibilitas & Ekstensi Tambahan"
  }.freeze

  DATA = [
    {
      key: "sso_auth_providers",
      cluster: "A",
      title: "SSO Auth Providers",
      menu_location: "Administrasi → Otentikasi → Penyedia OpenID / SAML",
      description: "Integrasi autentikasi tunggal (Single Sign-On) berbasis OpenID Connect (OIDC) dan SAML 2.0 yang terhubung ke server identitas organisasi (IDS).",
      objective: "Memusatkan kontrol akses, kebijakan kata sandi, dan MFA seluruh pengguna di server IDS internal tanpa manajemen kredensial ganda.",
      expected_output: "Halaman konfigurasi Provider OIDC/SAML aktif penuh; alur redirect login ke IDS berjalan mulus; pemetaan atribut (uid, email, name) otomatis membuat/memperbarui sesi pengguna.",
    },
    {
      key: "ldap_groups",
      cluster: "A",
      title: "LDAP Groups",
      menu_location: "Administrasi → Otentikasi → Koneksi LDAP / Grup",
      description: "Sinkronisasi dinamis keanggotaan grup pengguna sistem berdasarkan atribut grup/unit organisasi pada direktori LDAP / IDS internal.",
      objective: "Mengotomatiskan pemberian hak akses (Role & Permission) proyek berdasarkan jabatan atau struktur departemen di IDS.",
      expected_output: "Background job sinkronisasi LDAP berjalan terjadwal; perubahan anggota di direktori IDS otomatis menambah/mencabut anggota pada Group di aplikasi.",
    },
    {
      key: "scim_api",
      cluster: "A",
      title: "SCIM API",
      menu_location: "Administrasi → Otentikasi → Klien SCIM & /api/v3/scim_v2/",
      description: "Penyediaan endpoint REST API berstandar SCIM 2.0 untuk provisioning dan de-provisioning akun serta grup secara real-time dari IDS.",
      objective: "Memastikan saat personel baru didaftarkan atau dinonaktifkan di IDS, akses mereka di sistem proyek langsung terbuat atau terkunci detik itu juga.",
      expected_output: "Endpoint /api/v3/scim_v2/Users dan /Groups merespons status 200/201; manajemen Bearer Token klien SCIM tersedia di panel Admin.",
    },
    {
      key: "nextcloud_sso",
      cluster: "A",
      title: "Nextcloud SSO",
      menu_location: "Administrasi → Penyimpanan berkas → SSO penyimpanan",
      description: "Pertukaran token OAuth2/OIDC otomatis (Token Exchange RFC 8693) antara sesi login IDS pengguna dengan server penyimpanan dokumen internal.",
      objective: "Menghilangkan keharusan otorisasi manual per pengguna saat melampirkan atau membuka berkas rekayasa dari repositori penyimpanan internal.",
      expected_output: "Pengguna yang login via IDS langsung terhubung ke folder proyek di penyimpanan berkas tanpa jendela pop-up login tambahan.",
    },
    {
      key: "placeholder_users",
      cluster: "A",
      title: "Placeholder Users",
      menu_location: "Administrasi → Pengguna dan izin → Pengguna placeholder",
      description: "Pembuatan entitas pengguna simulasi/kerangka (misal: \"Lead Radar Engineer #2\", \"QA Inspector\") sebelum personel definitif ditugaskan.",
      objective: "Memungkinkan Manajer Proyek menyusun jadwal, alokasi beban kerja, dan struktur WBS pada tahap perencanaan awal kontrak.",
      expected_output: "Entitas Placeholder User dapat dipilih sebagai Assignee pada Work Package dan Team Planner, serta dapat dikonversi/diganti ke pengguna riil nantinya.",
    },
    {
      key: "team_planner_view",
      cluster: "B",
      title: "Team Planner View",
      menu_location: "Sidebar project → Team planner",
      description: "Kalender visual interaktif berbasis drag-and-drop yang menampilkan jadwal tugas per anggota tim dalam rentang mingguan/dua mingguan.",
      objective: "Memantau distribusi beban kerja harian/mingguan tiap personel dan mencegah over-allocation antar paket pekerjaan.",
      expected_output: "Tampilan Team Planner terbuka penuh; pengguna dapat menarik kartu Work Package antar baris personel dan mengubah durasi tanggal secara visual.",
    },
    {
      key: "board_view",
      cluster: "B",
      title: "Board View",
      menu_location: "Sidebar project → Board (Board aksi)",
      description: "Papan Kanban tingkat lanjut dengan kolom otomatis berbasis Status, Assignee, Version, Subproject, dan Parent-Child.",
      objective: "Mengotomatiskan pembaruan atribut Work Package (misal perubahan status dari In Progress ke Testing) hanya dengan menggeser kartu antar kolom.",
      expected_output: "Seluruh 5 tipe Action Board (bukan hanya Basic Free Board) dapat dibuat tanpa batas; pemindahan kartu otomatis memicu perubahan status/penanggung jawab di database.",
    },
    {
      key: "gantt_pdf_export",
      cluster: "B",
      title: "Gantt PDF Export",
      menu_location: "Sidebar project → Bagan Gantt → Ekspor PDF",
      description: "Mesin pengekspor bagan Gantt beresolusi tinggi ke dalam dokumen PDF siap cetak (mendukung ukuran kertas A4 hingga A0, skala waktu, dan garis dependensi).",
      objective: "Menyediakan dokumen jadwal proyek resmi untuk lampiran laporan kemajuan eksekutif, rapat tinjauan proyek, atau serah terima klien.",
      expected_output: "Tombol Export PDF pada tampilan Gantt menghasilkan berkas .pdf vektor yang rapi lengkap dengan hierarki WBS dan batang timeline.",
    },
    {
      key: "baseline_comparison",
      cluster: "B",
      title: "Baseline Comparison",
      menu_location: "Paket-penugasan / bilah Gantt → Baseline",
      description: "Fitur perekaman titik acuan jadwal (Schedule Baseline) dan pembanding perubahan (Delta Comparison) terhadap tanggal kemarin, minggu lalu, bulan lalu, atau tanggal spesifik.",
      objective: "Melacak pergeseran jadwal (schedule slippage), penambahan tugas baru, atau perubahan tenggat waktu dibanding rencana awal proyek.",
      expected_output: "Indikator visual ikon kilat/bayangan baseline muncul pada tabel Work Package dan bagan Gantt yang memperlihatkan selisih tanggal rencana vs. aktual.",
    },
    {
      key: "portfolio_management",
      cluster: "B",
      title: "Portfolio Management",
      menu_location: "Menu global → Portofolio / Project",
      description: "Manajemen hierarki tingkat atas yang mengelompokkan berbagai proyek dan sub-proyek ke dalam Portfolio dan Program strategis.",
      objective: "Memberikan visibilitas tingkat korporat/divisi kepada pimpinan untuk memantau kesehatan, anggaran, dan milestone lintas proyek secara agregat.",
      expected_output: "Modul Portfolios aktif di navigasi global; pimpinan dapat memantau agregasi status puluhan proyek dalam satu dasbor terpadu.",
    },
    {
      key: "customize_life_cycle",
      cluster: "B",
      title: "Customize Life Cycle",
      menu_location: "Administrasi → Project → Siklus hidup project",
      description: "Kustomisasi tahapan siklus hidup proyek (Project Stages & Phase Gates, misal: Inisiasi, Desain R&D, Prototipe, Uji Fungsi, Produksi, BAST).",
      objective: "Menyelaraskan tahapan manajemen proyek di dalam sistem dengan standar tata kelola proyek internal perusahaan (PMBOK / SOP EPC / R&D).",
      expected_output: "Admin dapat menambah, mengubah warna, mengurutkan, dan menghapus Stage maupun Gate siklus proyek yang tampil pada halaman ikhtisar proyek.",
    },
    {
      key: "custom_actions",
      cluster: "C",
      title: "Custom Actions",
      menu_location: "Administrasi → Paket-Penugasan → Aksi kustom",
      description: "Tombol aksi makro satu-klik pada Work Package yang mengeksekusi beberapa perubahan atribut sekaligus berdasarkan kondisi Role, Status, dan Type.",
      objective: "Mempercepat dan menstandardisasi alur approval berjenjang (misal tombol \"Approve & Assign to QA\" langsung mengubah status, progres 100%, dan penanggung jawab).",
      expected_output: "Tombol Custom Action muncul di bagian atas detail Work Package sesuai kondisi yang ditentukan dan mengeksekusi seluruh aksi secara atomik.",
    },
    {
      key: "custom_field_hierarchies",
      cluster: "C",
      title: "Custom Field Hierarchies",
      menu_location: "Administrasi → Isian kustom → Tipe Hierarki",
      description: "Kolom atribut kustom berbentuk pohon hierarki bertingkat (misal: Lokasi → Provinsi → Site → Shelter/Ruangan atau Sistem → Subsistem → Komponen).",
      objective: "Menjaga konsistensi taksonomi data teknis dan lokasi proyek tanpa duplikasi input teks bebas.",
      expected_output: "Admin dapat membangun pohon item bertingkat beserta kode singkatnya; pengguna dapat memilih node hierarki dengan pencari dropdown berjenjang.",
    },
    {
      key: "calculated_values",
      cluster: "C",
      title: "Calculated Values",
      menu_location: "Administrasi → Isian kustom → Tipe Nilai terhitung",
      description: "Kolom kustom berbasis rumus matematika yang menghitung nilai secara otomatis dari kolom angka/bobot lain pada Work Package.",
      objective: "Mengotomatiskan perhitungan skor risiko (Probabilitas times Dampak), indeks biaya, atau bobot kemajuan teknis langsung di dalam formulir tugas.",
      expected_output: "Kolom Calculated Value mengevaluasi ekspresi matematika secara otomatis setiap kali nilai variabel penyusunnya diperbarui.",
    },
    {
      key: "edit_attribute_groups",
      cluster: "C",
      title: "Edit Attribute Groups",
      menu_location: "Administrasi → Paket-Penugasan → Tipe → Konfigurasi formulir",
      description: "Pengaturan tata letak formulir Work Package dengan kemampuan membuat grup atribut baru, mengubah nama grup, dan menyusun ulang posisi kolom.",
      objective: "Merapikan tampilan formulir kerja agar sesuai dengan dokumen spesifikasi teknis, kartu kendali mutu, atau formulir pengadaan internal.",
      expected_output: "Editor konfigurasi form (drag-and-drop grup atribut dan panel query relasi) berfungsi penuh tanpa batasan gembok untuk setiap tipe Work Package.",
    },
    {
      key: "weighted_item_lists",
      cluster: "C",
      title: "Weighted Item Lists",
      menu_location: "Administrasi → Isian kustom → Tipe Daftar item berbobot",
      description: "Daftar pilihan atribut di mana setiap opsi memiliki nilai bobot numerik tersembunyi/terukur untuk keperluan skoring.",
      objective: "Mendukung matriks penilaian objektif (seperti tingkat kritikalitas aset, tingkat kematangan teknologi/TRL, atau prioritas backlog).",
      expected_output: "Setiap item dalam daftar pilihan menyimpan bobot angka yang dapat diumpankan ke dalam Calculated Values maupun laporan analitik.",
    },
    {
      key: "work_package_subject_generation",
      cluster: "C",
      title: "Work Package Subject Generation",
      menu_location: "Administrasi → Paket-Penugasan → Tipe → Konfigurasi subjek",
      description: "Generator penamaan subjek/judul Work Package otomatis menggunakan pola template dinamis (misal: [Kode Proyek]-[Tipe]-[Lokasi]-[ID]).",
      objective: "Menjamin penomoran dokumen, tiket rekayasa, dan paket kerja mengikuti standar penamaan baku tata kelola data perusahaan.",
      expected_output: "Saat pengguna membuat Work Package baru pada tipe terkait, kolom Subject otomatis terisi sesuai pola atribut yang ditetapkan.",
    },
    {
      key: "work_package_query_relation_columns",
      cluster: "C",
      title: "Work Package Query Relation Columns",
      menu_location: "Tabel paket-penugasan → Atur tampilan → Kolom",
      description: "Penambahan kolom relasi lintas paket kerja (seperti Child relations, Predecessors, Related to, atau Follows) langsung sebagai kolom tabel Work Package.",
      objective: "Memudahkan audit ketergantungan antar tugas dan pelacakan struktur induk-anak dalam satu tampilan tabel tanpa membuka rincian satu per satu.",
      expected_output: "Tabel Work Package menampilkan jumlah dan daftar tautan relasi langsung di dalam sel kolom tabel serta dapat diekspor ke XLS/CSV.",
    },
    {
      key: "work_package_sharing",
      cluster: "D",
      title: "Work Package Sharing",
      menu_location: "Detail paket-penugasan → Tombol Bagikan",
      description: "Pembagian akses spesifik pada satu Work Package tertentu (hak View, Comment, atau Edit) kepada pengguna internal/tamu tanpa harus memasukkan mereka sebagai anggota seluruh proyek.",
      objective: "Menjaga kerahasiaan proyek strategis: konsultan, auditor, atau divisi pendukung cukup diberi akses ke tiket terkait saja tanpa melihat keseluruhan proyek.",
      expected_output: "Jendela modal Share Work Package aktif; pengguna yang dibagikan dapat mengakses tiket spesifik tersebut sesuai izin yang diberikan.",
    },
    {
      key: "project_list_sharing",
      cluster: "D",
      title: "Project List Sharing",
      menu_location: "Daftar project global → Bagikan tampilan",
      description: "Fitur berbagi tampilan daftar proyek terfilter (Saved Project Lists) kepada pengguna tertentu, grup, atau seluruh anggota organisasi.",
      objective: "Menyediakan tampilan laporan portofolio standar yang seragam bagi seluruh pemangku kepentingan di dalam organisasi.",
      expected_output: "Daftar proyek yang disimpan dengan filter kolom kustom dapat dibagikan ke grup/peran tertentu melalui menu Project Lists.",
    },
    {
      key: "one_drive_sharepoint_file_storage",
      cluster: "D",
      title: "OneDrive/SharePoint File Storage",
      menu_location: "Administrasi → Penyimpanan berkas",
      description: "Konektor integrasi penyimpanan berkas korporat berbasis protokol Microsoft Graph / Drive selain Nextcloud internal.",
      objective: "Memberikan fleksibilitas apabila terdapat divisi yang menggunakan repositori dokumen berbasis SharePoint/OneDrive korporat.",
      expected_output: "Opsi pembuatan File Storage tipe OneDrive/SharePoint terbuka di menu Admin untuk diaktifkan bila diperlukan.",
    },
    {
      key: "mcp_server",
      cluster: "D",
      title: "MCP Server",
      menu_location: "Administrasi → Pengaturan sistem / Endpoint MCP internal",
      description: "Layanan Model Context Protocol (MCP) Server internal yang memungkinkan agen AI in-house membaca dan mengelola konteks proyek secara terotorisasi.",
      objective: "Menghubungkan asisten AI/LLM lokal perusahaan ke data proyek, WBS, dan progres tugas dengan kontrol izin berbasis pengguna.",
      expected_output: "Konfigurasi dan endpoint MCP internal dapat diakses oleh client AI internal organisasi menggunakan autentikasi token internal.",
    },
    {
      key: "project_creation_wizard",
      cluster: "D",
      title: "Project Creation Wizard",
      menu_location: "Pengaturan project → Wizard inisiasi project",
      description: "Panduan langkah demi langkah (multi-step wizard) saat menginisiasi proyek baru untuk mengisi Project Charter, ruang lingkup, pemangku kepentingan, dan dokumen wajib.",
      objective: "Menegakkan kepatuhan prosedur administrasi inisiasi proyek sebelum proyek disetujui dan dijalankan.",
      expected_output: "Saat proyek baru dibuat, pengguna dipandu melalui antarmuka formulir bertahap dan menghasilkan ringkasan inisiasi proyek yang terstruktur.",
    },
    {
      key: "virus_scanning",
      cluster: "E",
      title: "Virus Scanning",
      menu_location: "Administrasi → Pengaturan sistem → Lampiran",
      description: "Pemindaian antivirus otomatis berbasis ClamAV (daemon lokal/socket) terhadap setiap berkas lampiran yang diunggah pengguna sebelum disimpan ke ruang penyimpanan.",
      objective: "Mencegah penyebaran malware atau berkas berbahaya di dalam jaringan internal organisasi melalui lampiran proyek.",
      expected_output: "Pengaturan Virus scanning aktif di panel Admin; berkas yang terdeteksi mengandung signature berbahaya otomatis dikarantina/ditolak.",
    },
    {
      key: "capture_external_links",
      cluster: "E",
      title: "Capture External Links",
      menu_location: "Administrasi → Pengaturan sistem → Tautan eksternal",
      description: "Gerbang intersepsi keamanan yang menahan setiap klik pada tautan eksternal di dalam deskripsi/komentar dan menampilkan halaman peringatan sebelum keluar dari domain internal.",
      objective: "Melindungi personel dari serangan phishing dan memastikan pengguna sadar saat akan meninggalkan jaringan intranet organisasi.",
      expected_output: "Setiap tautan luar dialihkan terlebih dahulu ke /external_redirect dengan pesan peringatan keamanan organisasi.",
    },
    {
      key: "internal_comments",
      cluster: "E",
      title: "Internal Comments",
      menu_location: "Tab aktivitas paket-penugasan → Checkbox Komentar internal",
      description: "Fitur komentar rahasia/internal pada Work Package yang hanya dapat dilihat oleh peran (Role) yang memiliki izin khusus View internal comments.",
      objective: "Memungkinkan manajer proyek, tim keuangan, atau tim pengawas mendiskusikan isu sensitif langsung di dalam tiket tanpa terlihat oleh pelaksana umum/vendor.",
      expected_output: "Kotak centang Internal comment muncul saat menulis komentar; komentar ditandai dengan warna latar khusus dan tersembunyi dari peran biasa.",
    },
    {
      key: "readonly_work_packages",
      cluster: "E",
      title: "Readonly Work Packages",
      menu_location: "Administrasi → Paket-Penugasan → Status → Baca-saja",
      description: "Penguncian mutlak seluruh atribut Work Package ketika tiket memasuki status tertentu (misal: Closed, Audited, atau Approved Baseline).",
      objective: "Menjamin integritas jejak audit (audit trail) sehingga data tugas yang sudah diserahterimakan tidak dapat diubah secara sepihak.",
      expected_output: "Ketika status bertanda Read-only dipilih, seluruh kolom Work Package terkunci dari perubahan kecuali statusnya dibuka kembali oleh Admin/PM berwenang.",
    },
    {
      key: "date_alerts",
      cluster: "E",
      title: "Date Alerts",
      menu_location: "Pengaturan notifikasi & Pusat notifikasi",
      description: "Mesin pengingat otomatis yang mengirimkan notifikasi sebelum Start Date, sebelum Finish Date, dan saat Work Package melewati tenggat waktu (Overdue).",
      objective: "Mencegah keterlambatan penyelesaian tugas kritis dengan memberikan peringatan dini kepada Assignee dan Accountable.",
      expected_output: "Pengaturan Date Alerts aktif pada profil notifikasi pengguna dan pengaturan sistem; pekerja latar mengirimkan pengingat tepat waktu.",
    },
    {
      key: "meeting_templates",
      cluster: "E",
      title: "Meeting Templates",
      menu_location: "Sidebar project → Rapat → Template",
      description: "Pembuatan cetak biru agenda rapat dinamis (Dynamic Meeting Templates) yang dapat digunakan berulang kali untuk rapat mingguan, tinjauan teknis, atau MoM.",
      objective: "Menstandardisasi struktur agenda dan risalah rapat (Minutes of Meeting) di seluruh proyek organisasi.",
      expected_output: "Pengguna dapat membuat Template rapat dan memakainya saat menjadwalkan rapat tunggal maupun rapat berulang (Recurring Meetings).",
    },
    {
      key: "define_custom_style",
      cluster: "E",
      title: "Define Custom Style",
      menu_location: "Administrasi → Rancangan",
      description: "Antarmuka kustomisasi visual penuh untuk mengunggah logo organisasi, favicon, touch icon, serta mengatur palet warna primer, header, dan tombol.",
      objective: "Melakukan white-labeling menyeluruh sehingga aplikasi tampil 100% sebagai sistem internal resmi milik organisasi.",
      expected_output: "Halaman Administration -> Design terbuka penuh; perubahan logo dan warna langsung mengkompilasi ulang variabel CSS aplikasi.",
    },
    {
      key: "conditional_highlighting",
      cluster: "F",
      title: "Conditional Highlighting",
      menu_location: "—",
      description: "Pewarnaan baris/atribut tabel Work Package berdasarkan kondisi prioritas, status, atau keterlambatan.",
      objective: "Membuat prioritas, status, dan keterlambatan terlihat sekilas pada tabel Work Package.",
      expected_output: "Baris/atribut tabel Work Package diwarnai otomatis menurut aturan kondisi.",
    },
    {
      key: "multiple_active_sprints",
      cluster: "F",
      title: "Multiple Active Sprints",
      menu_location: "—",
      description: "Kemampuan menjalankan lebih dari satu sprint atau iterasi aktif secara paralel dalam satu proyek.",
      objective: "Mendukung tim yang menjalankan beberapa iterasi paralel dalam satu proyek.",
      expected_output: "Lebih dari satu sprint dapat berstatus aktif bersamaan dalam satu proyek.",
    },
    {
      key: "resource_management",
      cluster: "F",
      title: "Resource Management",
      menu_location: "—",
      description: "Pengelolaan kapasitas dan utilisasi sumber daya personel lintas proyek.",
      objective: "Melihat kapasitas dan utilisasi personel lintas proyek untuk mencegah beban berlebih.",
      expected_output: "Ringkasan kapasitas dan utilisasi per personel lintas proyek.",
    },
    {
      key: "time_entry_time_restrictions",
      cluster: "F",
      title: "Time Entry Time Restrictions",
      menu_location: "—",
      description: "Pembatasan dan penguncian jendela waktu pencatatan jam kerja (timesheet).",
      objective: "Menjaga integritas timesheet dengan membatasi jendela waktu pencatatan jam kerja.",
      expected_output: "Pencatatan jam di luar jendela waktu yang ditetapkan ditolak atau terkunci.",
    },
    {
      key: "xwiki_integration",
      cluster: "F",
      title: "XWiki Integration",
      menu_location: "—",
      description: "Dukungan konektor basis pengetahuan eksternal/internal tambahan.",
      objective: "Menautkan basis pengetahuan XWiki ke proyek tanpa pindah aplikasi.",
      expected_output: "Halaman XWiki dapat ditautkan dan ditampilkan dari dalam proyek.",
    },
  ].freeze

  class << self
    def all
      @all ||= DATA.map { |h| Feature.new(**h) }.freeze
    end

    def find(key) = all.find { |f| f.key == key.to_s }

    def keys = all.map(&:key)

    def grouped_by_cluster
      all.group_by(&:cluster).sort.map { |cl, list| [cl, CLUSTER_TITLES.fetch(cl), list] }
    end
  end
end
