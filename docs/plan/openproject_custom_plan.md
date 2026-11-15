# OpenProject Custom Plan: In-House Enterprise Architecture, IDS SSO & Dynamic Feature Toggle

> **Lokasi File Wajib:** `docs/plan/openproject_custom_plan.md`
> **Target Eksekutor:** Claude Sonnet 5.5 (Low Effort Mode — Deterministic Atomic Execution)
> **Basis Kode Minimum:** OpenProject Community Source $\ge$ v17.1.0 / v17.6.0+ (PostgreSQL)
> **Status Kepatuhan:** 100% GNU GPLv3 Compliant, Zero Outbound Telemetry, White-Labeled Internal Portal, Centralized IDS SSO, Dynamic Admin Feature Switcher

---

## 0. KALIBRASI EKSEKUSI "SONNET 5.5 LOW EFFORT" & CIRCUIT BREAKER

Karena Anda beroperasi pada mode **Claude Sonnet 5.5 Low Effort**, Anda dilarang melakukan perubahan masif sekaligus, dilarang menyingkat kode dengan komentar `// ... existing code`, dan dilarang menebak isi file tanpa membacanya terlebih dahulu.

### A. Empat Disiplin Eksekusi Mikro
1. **Satu Modul per Sesi (1-Ticket Scope Lock):** Hanya kerjakan **SATU** kode modul (`MOD-XX`) pada setiap perintah pengguna. Jangan menyentuh `MOD-02` sebelum `MOD-01` selesai diverifikasi, di-commit, di-push, dan di-deploy.
2. **Read-Full-Before-Write:** Baca seluruh isi file target dari baris pertama hingga baris terakhir sebelum melakukan perubahan.
3. **Pertahankan Header Lisensi Asli:** Setiap kali memodifikasi file `.rb`, `.ts`, `.html`, atau `.erb`, **WAJIB** mempertahankan blok komentar `#-- copyright` di bagian atas file sesuai ketentuan Pasal 4 & 5 GNU GPLv3.
4. **Atomic CI/CD Ritual:** Setiap modul yang selesai dikerjakan wajib langsung melewati siklus **Verify $\rightarrow$ Commit $\rightarrow$ Push $\rightarrow$ Live Deploy** tanpa menunggu akhir proyek.

### B. Protokol "Berhenti & Tanya Manusia" (`HALT & ASK`)
Anda **WAJIB BERHENTI (`HALT`)** seketika dan membatalkan perubahan sementara (`git checkout -- <file>`) apabila:
1. File, kelas, atau rute yang disebutkan dalam modul ini berbeda atau tidak ditemukan pada versi *source code* yang terpasang.
2. Parameter koneksi **IDS (Identity Server)** (seperti `issuer_url`, `client_id`, `client_secret`, atau `ldap_host`) dibutuhkan tetapi belum dicantumkan oleh IT Development.
3. Kompilasi aset atau migrasi database gagal **2 kali berturut-turut**.

**Format Pelaporan Saat `HALT`:**
> **[BUTUH KLARIFIKASI / SOP DARI IT DEVELOPMENT]**
> - **Referensi Dokumen:** `docs/plan/openproject_custom_plan.md`
> - **Modul Aktif:** `[MOD-XX: Nama Modul]`
> - **Titik Hambatan:** `[Sebutkan path file, baris kode, atau pesan error spesifik]`
> - **Kebutuhan Keputusan / Parameter:** `[Tuliskan 1-3 pertanyaan singkat dan jelas untuk dijawab oleh User]`

---

## 1. LANDASAN KEPATUHAN HUKUM (GPLv3) & ISOLASI ENAM LAPIS

Berdasarkan audit lisensi dan arsitektur kode sumber `opf/openproject`:
1. **Hak Modifikasi In-House (GNU GPLv3):** Seluruh kode sumber di repositori utama—termasuk mekanisme pengecekan fitur `EnterpriseToken` dan modul di dalam direktori `modules/`—berada di bawah lisensi **GNU GPLv3**. Organisasi memiliki hak penuh untuk memodifikasi kode sumber dan mengaktifkan fungsionalitas internal tanpa biaya lisensi bulanan dan tanpa kewajiban mempublikasikan kode hasil modifikasi selama aplikasi digunakan secara internal (*in-house*) dan tidak didistribusikan ke pihak eksternal.
2. **Kewajiban Hak Cipta vs. Merek Dagang (Trademark):**
   - **Hak Cipta Kode (Wajib Dipertahankan):** File `LICENSE`, `COPYRIGHT`, serta header `#-- copyright` (OpenProject GmbH, ChiliProject Team, Jean-Philippe Lang, dan komponen MIT) di dalam kode sumber **tidak boleh dihapus**.
   - **Merek Dagang UI (Wajib Di-White-Label):** Nama dan logo `"OpenProject"` pada antarmuka pengguna, tab peramban, halaman login, dan *footer* email **wajib diganti** dengan identitas resmi organisasi agar tidak melanggar merek dagang OpenProject GmbH.
   - **Atribusi Ikon (CC BY 3.0):** Catat atribusi *OpenProject Icon Font* di dalam dokumentasi lisensi internal repositori (`docs/plan/LEGAL_NOTICES.md`) sehingga antarmuka pengguna tetap bebas dari tautan keluar ke `www.openproject.org`.
3. **Isolasi Jaringan Enam Lapis (Zero Outbound Traffic):**
   - **Lapis 1:** Matikan *Security Upgrade Badge* & *Release API* (`releases.openproject.com`) yang mengirimkan `installation_uuid` dan metadata server.
   - **Lapis 2:** Matikan widget *Community*, *Enterprise Upsell*, dan *New Features Teaser* pada *Homescreen*.
   - **Lapis 3:** Arahkan tombol bantuan (`?`) ke portal panduan internal organisasi dan hapus menu *Product/Docs Feedback* ke vendor.
   - **Lapis 4:** Hapus rute `enterprise_trial` yang menghubungi `augur.openproject.com` dan netralisasi seluruh URL di `config/static_links.yml`.
   - **Lapis 5:** Matikan pemanggilan avatar eksternal ke `secure.gravatar.com` pada modul `avatars` dan paksa penggunaan avatar lokal.
   - **Lapis 6:** Kunci pengiriman email ke SMTP internal, bersihkan *footer* email di `UserMailer`, dan perketat *Content Security Policy (CSP)*.

---

## 2. ARSITEKTUR SENTRALISASI SSO KE IN-HOUSE IDS (IDENTITY SERVER)

Seluruh mekanisme autentikasi, manajemen sesi, dan sinkronisasi grup pengguna dialihkan secara terpusat ke **IDS (Identity Server)** internal organisasi (mendukung protokol OpenID Connect / OAuth2, SAML 2.0, LDAP/Active Directory, dan SCIM 2.0):

1. **Integrasi OIDC / OAuth2 ke IDS (`sso_auth_providers`):**
   - Menggunakan kapabilitas OmniAuth bawaan yang dikonfigurasi langsung melalui variabel lingkungan atau tabel `oidc_providers` menuju endpoint internal IDS:
     - **Authorization Endpoint:** `https://<ids-domain-internal>/protocol/openid-connect/auth`
     - **Token Endpoint:** `https://<ids-domain-internal>/protocol/openid-connect/token`
     - **UserInfo Endpoint:** `https://<ids-domain-internal>/protocol/openid-connect/userinfo`
     - **JWKS / End Session Endpoint:** `https://<ids-domain-internal>/protocol/openid-connect/logout`
   - Mendukung opsi `OPENPROJECT_OMNIAUTH__DIRECT__LOGIN__PROVIDER="ids_sso"` agar pengguna yang mengakses aplikasi langsung diarahkan ke halaman login tunggal IDS.
2. **Sinkronisasi Otomatis Struktur Organisasi & Grup (`ldap_groups` & `scim_api`):**
   - Struktur jabatan, divisi, dan tim proyek di IDS disinkronkan secara otomatis ke dalam grup sistem melalui protokol **SCIM 2.0** (`/api/v3/scim_v2/Users` dan `/api/v3/scim_v2/Groups`) atau sinkronisasi filter grup LDAP internal.
3. **Pertukaran Token Penyimpanan Berkas Internal (`nextcloud_sso`):**
   - Menggunakan token OIDC dari IDS untuk autentikasi tunggal (*Single Sign-On*) antara manajemen proyek dan penyimpanan dokumen internal tanpa login ulang.

---

## 3. KATALOG LENGKAP 30 TAKSONOMI FITUR ENTERPRISE (`ee.features`) & OUTPUT IN-HOUSE

Berikut adalah spesifikasi lengkap **30 Fitur Enterprise resmi (`ee.features`)** beserta **5 Fitur Kompatibilitas Ekstensi** yang diaktifkan secara *in-house* dan dikendalikan melalui **Admin Feature Toggle Manager**.

### Klaster A: Sentralisasi Identitas, SSO IDS & Manajemen Kapasitas Pengguna (5 Fitur)

| No | Kunci Fitur (`ee.features`) | Menu / Lokasi Sistem | Deskripsi Fungsional | Tujuan Implementasi In-House | Output yang Diharapkan (Deliverable Sistem) |
| :-: | :--- | :--- | :--- | :--- | :--- |
| **1** | `sso_auth_providers` | `Administration` $\rightarrow$ `Authentication` $\rightarrow$ `OpenID providers` / `SAML` | Integrasi autentikasi tunggal (*Single Sign-On*) berbasis OpenID Connect (OIDC) dan SAML 2.0 yang terhubung ke server identitas organisasi (**IDS**). | Memusatkan kontrol akses, kebijakan kata sandi, dan MFA seluruh pengguna di server IDS internal tanpa manajemen kredensial ganda. | Halaman konfigurasi Provider OIDC/SAML aktif penuh; alur *redirect login* ke IDS berjalan mulus; pemetaan atribut (`uid`, `email`, `name`) otomatis membuat/memperbarui sesi pengguna. |
| **2** | `ldap_groups` | `Administration` $\rightarrow$ `Authentication` $\rightarrow$ `LDAP connections` / `Groups` | Sinkronisasi dinamis keanggotaan grup pengguna sistem berdasarkan atribut grup/unit organisasi pada direktori LDAP / IDS internal. | Mengotomatiskan pemberian hak akses (*Role & Permission*) proyek berdasarkan jabatan atau struktur departemen di IDS. | *Background job* sinkronisasi LDAP berjalan terjadwal; perubahan anggota di direktori IDS otomatis menambah/mencabut anggota pada *Group* di aplikasi. |
| **3** | `scim_api` | `Administration` $\rightarrow$ `Authentication` $\rightarrow$ `SCIM clients` & `/api/v3/scim_v2/` | Penyediaan endpoint REST API berstandar **SCIM 2.0** untuk *provisioning* dan *de-provisioning* akun serta grup secara *real-time* dari IDS. | Memastikan saat personel baru didaftarkan atau dinonaktifkan di IDS, akses mereka di sistem proyek langsung terbuat atau terkunci detik itu juga. | Endpoint `/api/v3/scim_v2/Users` dan `/Groups` merespons status `200/201`; manajemen *Bearer Token* klien SCIM tersedia di panel Admin. |
| **4** | `nextcloud_sso` | `Administration` $\rightarrow$ `File storages` $\rightarrow$ `Storage SSO` | Pertukaran token OAuth2/OIDC otomatis (*Token Exchange* RFC 8693) antara sesi login IDS pengguna dengan server penyimpanan dokumen internal. | Menghilangkan keharusan otorisasi manual per pengguna saat melampirkan atau membuka berkas rekayasa dari repositori penyimpanan internal. | Pengguna yang login via IDS langsung terhubung ke folder proyek di penyimpanan berkas tanpa jendela *pop-up* login tambahan. |
| **5** | `placeholder_users` | `Administration` $\rightarrow$ `Users and permissions` $\rightarrow$ `Placeholder users` | Pembuatan entitas pengguna simulasi/kerangka (misal: *"Lead Radar Engineer #2"*, *"QA Inspector"*) sebelum personel definitif ditugaskan. | Memungkinkan Manajer Proyek menyusun jadwal, alokasi beban kerja, dan struktur WBS pada tahap perencanaan awal kontrak. | Entitas *Placeholder User* dapat dipilih sebagai *Assignee* pada *Work Package* dan *Team Planner*, serta dapat dikonversi/diganti ke pengguna riil nantinya. |

### Klaster B: Perencanaan Eksekutif, Visualisasi & Tata Kelola Portofolio (6 Fitur)

| No | Kunci Fitur (`ee.features`) | Menu / Lokasi Sistem | Deskripsi Fungsional | Tujuan Implementasi In-House | Output yang Diharapkan (Deliverable Sistem) |
| :-: | :--- | :--- | :--- | :--- | :--- |
| **6** | `team_planner_view` | `Project Sidebar` $\rightarrow$ `Team planners` | Kalender visual interaktif berbasis *drag-and-drop* yang menampilkan jadwal tugas per anggota tim dalam rentang mingguan/dua mingguan. | Memantau distribusi beban kerja harian/mingguan tiap personel dan mencegah *over-allocation* antar paket pekerjaan. | Tampilan *Team Planner* terbuka penuh; pengguna dapat menarik kartu *Work Package* antar baris personel dan mengubah durasi tanggal secara visual. |
| **7** | `board_view` | `Project Sidebar` $\rightarrow$ `Boards` (Action Boards) | Papan Kanban tingkat lanjut dengan kolom otomatis berbasis **Status**, **Assignee**, **Version**, **Subproject**, dan **Parent-Child**. | Mengotomatiskan pembaruan atribut *Work Package* (misal perubahan status dari *In Progress* ke *Testing*) hanya dengan menggeser kartu antar kolom. | Seluruh 5 tipe *Action Board* (bukan hanya *Basic Free Board*) dapat dibuat tanpa batas; pemindahan kartu otomatis memicu perubahan status/penanggung jawab di database. |
| **8** | `gantt_pdf_export` | `Project Sidebar` $\rightarrow$ `Gantt charts` $\rightarrow$ `Export PDF` | Mesin pengekspor bagan Gantt beresolusi tinggi ke dalam dokumen PDF siap cetak (mendukung ukuran kertas A4 hingga A0, skala waktu, dan garis dependensi). | Menyediakan dokumen jadwal proyek resmi untuk lampiran laporan kemajuan eksekutif, rapat tinjauan proyek, atau serah terima klien. | Tombol *Export PDF* pada tampilan Gantt menghasilkan berkas `.pdf` vektor yang rapi lengkap dengan hierarki WBS dan batang *timeline*. |
| **9** | `baseline_comparison` | `Work Packages / Gantt Toolbar` $\rightarrow$ `Baseline` | Fitur perekaman titik acuan jadwal (*Schedule Baseline*) dan pembanding perubahan (*Delta Comparison*) terhadap tanggal kemarin, minggu lalu, bulan lalu, atau tanggal spesifik. | Melacak pergeseran jadwal (*schedule slippage*), penambahan tugas baru, atau perubahan tenggat waktu dibanding rencana awal proyek. | Indikator visual ikon kilat/bayangan *baseline* muncul pada tabel *Work Package* dan bagan Gantt yang memperlihatkan selisih tanggal rencana vs. aktual. |
| **10** | `portfolio_management` | `Global Menu` $\rightarrow$ `Portfolios` / `Projects` | Manajemen hierarki tingkat atas yang mengelompokkan berbagai proyek dan sub-proyek ke dalam *Portfolio* dan *Program* strategis. | Memberikan visibilitas tingkat korporat/divisi kepada pimpinan untuk memantau kesehatan, anggaran, dan *milestone* lintas proyek secara agregat. | Modul *Portfolios* aktif di navigasi global; pimpinan dapat memantau agregasi status puluhan proyek dalam satu dasbor terpadu. |
| **11** | `customize_life_cycle` | `Administration` $\rightarrow$ `Projects` $\rightarrow$ `Project life cycle` | Kustomisasi tahapan siklus hidup proyek (*Project Stages* & *Phase Gates*, misal: *Inisiasi, Desain R&D, Prototipe, Uji Fungsi, Produksi, BAST*). | Menyelaraskan tahapan manajemen proyek di dalam sistem dengan standar tata kelola proyek internal perusahaan (PMBOK / SOP EPC / R&D). | Admin dapat menambah, mengubah warna, mengurutkan, dan menghapus *Stage* maupun *Gate* siklus proyek yang tampil pada halaman ikhtisar proyek. |

### Klaster C: Otomasi Alur Kerja, Kustomisasi Atribut & Kalkulasi Data (7 Fitur)

| No | Kunci Fitur (`ee.features`) | Menu / Lokasi Sistem | Deskripsi Fungsional | Tujuan Implementasi In-House | Output yang Diharapkan (Deliverable Sistem) |
| :-: | :--- | :--- | :--- | :--- | :--- |
| **12** | `custom_actions` | `Administration` $\rightarrow$ `Work packages` $\rightarrow$ `Custom actions` | Tombol aksi makro satu-klik pada *Work Package* yang mengeksekusi beberapa perubahan atribut sekaligus berdasarkan kondisi *Role*, *Status*, dan *Type*. | Mempercepat dan menstandardisasi alur *approval* berjenjang (misal tombol *"Approve & Assign to QA"* langsung mengubah status, progres $100\%$, dan penanggung jawab). | Tombol *Custom Action* muncul di bagian atas detail *Work Package* sesuai kondisi yang ditentukan dan mengeksekusi seluruh aksi secara atomik. |
| **13** | `custom_field_hierarchies` | `Administration` $\rightarrow$ `Custom fields` $\rightarrow$ Tipe `Hierarchy` | Kolom atribut kustom berbentuk pohon hierarki bertingkat (misal: *Lokasi $\rightarrow$ Provinsi $\rightarrow$ Site $\rightarrow$ Shelter/Ruangan* atau *Sistem $\rightarrow$ Subsistem $\rightarrow$ Komponen*). | Menjaga konsistensi taksonomi data teknis dan lokasi proyek tanpa duplikasi input teks bebas. | Admin dapat membangun pohon item bertingkat beserta kode singkatnya; pengguna dapat memilih node hierarki dengan pencari *dropdown* berjenjang. |
| **14** | `calculated_values` | `Administration` $\rightarrow$ `Custom fields` $\rightarrow$ Tipe `Calculated value` | Kolom kustom berbasis rumus matematika yang menghitung nilai secara otomatis dari kolom angka/bobot lain pada *Work Package*. | Mengotomatiskan perhitungan skor risiko ($Probabilitas \times Dampak$), indeks biaya, atau bobot kemajuan teknis langsung di dalam formulir tugas. | Kolom *Calculated Value* mengevaluasi ekspresi matematika secara otomatis setiap kali nilai variabel penyusunnya diperbarui. |
| **15** | `edit_attribute_groups` | `Administration` $\rightarrow$ `Work packages` $\rightarrow$ `Types` $\rightarrow$ `Form configuration` | Pengaturan tata letak formulir *Work Package* dengan kemampuan membuat grup atribut baru, mengubah nama grup, dan menyusun ulang posisi kolom. | Merapikan tampilan formulir kerja agar sesuai dengan dokumen spesifikasi teknis, kartu kendali mutu, atau formulir pengadaan internal. | Editor konfigurasi form (*drag-and-drop* grup atribut dan panel *query* relasi) berfungsi penuh tanpa batasan gembok untuk setiap tipe *Work Package*. |
| **16** | `weighted_item_lists` | `Administration` $\rightarrow$ `Custom fields` $\rightarrow$ Tipe `Weighted item list` | Daftar pilihan atribut di mana setiap opsi memiliki nilai bobot numerik tersembunyi/terukur untuk keperluan skoring. | Mendukung matriks penilaian objektif (seperti tingkat kritikalitas aset, tingkat kematangan teknologi/TRL, atau prioritas *backlog*). | Setiap item dalam daftar pilihan menyimpan bobot angka yang dapat diumpankan ke dalam *Calculated Values* maupun laporan analitik. |
| **17** | `work_package_subject_generation` | `Administration` $\rightarrow$ `Work packages` $\rightarrow$ `Types` $\rightarrow$ `Subject configuration` | Generator penamaan subjek/judul *Work Package* otomatis menggunakan pola *template* dinamis (misal: `[Kode Proyek]-[Tipe]-[Lokasi]-[ID]`). | Menjamin penomoran dokumen, tiket rekayasa, dan paket kerja mengikuti standar penamaan baku tata kelola data perusahaan. | Saat pengguna membuat *Work Package* baru pada tipe terkait, kolom *Subject* otomatis terisi sesuai pola atribut yang ditetapkan. |
| **18** | `work_package_query_relation_columns` | `Work Packages Table` $\rightarrow$ `Configure view` $\rightarrow$ `Columns` | Penambahan kolom relasi lintas paket kerja (seperti *Child relations*, *Predecessors*, *Related to*, atau *Follows*) langsung sebagai kolom tabel *Work Package*. | Memudahkan audit ketergantungan antar tugas dan pelacakan struktur induk-anak dalam satu tampilan tabel tanpa membuka rincian satu per satu. | Tabel *Work Package* menampilkan jumlah dan daftar tautan relasi langsung di dalam sel kolom tabel serta dapat diekspor ke XLS/CSV. |

### Klaster D: Kolaborasi Terkontrol, Integrasi Penyimpanan & AI/MCP (5 Fitur)

| No | Kunci Fitur (`ee.features`) | Menu / Lokasi Sistem | Deskripsi Fungsional | Tujuan Implementasi In-House | Output yang Diharapkan (Deliverable Sistem) |
| :-: | :--- | :--- | :--- | :--- | :--- |
| **19** | `work_package_sharing` | `Work Package Detail` $\rightarrow$ Tombol `Share` | Pembagian akses spesifik pada **satu** *Work Package* tertentu (hak *View*, *Comment*, atau *Edit*) kepada pengguna internal/tamu tanpa harus memasukkan mereka sebagai anggota seluruh proyek. | Menjaga kerahasiaan proyek strategis: konsultan, auditor, atau divisi pendukung cukup diberi akses ke tiket terkait saja tanpa melihat keseluruhan proyek. | Jendela modal *Share Work Package* aktif; pengguna yang dibagikan dapat mengakses tiket spesifik tersebut sesuai izin yang diberikan. |
| **20** | `project_list_sharing` | `Global Projects List` $\rightarrow$ `Share view` | Fitur berbagi tampilan daftar proyek terfilter (*Saved Project Lists*) kepada pengguna tertentu, grup, atau seluruh anggota organisasi. | Menyediakan tampilan laporan portofolio standar yang seragam bagi seluruh pemangku kepentingan di dalam organisasi. | Daftar proyek yang disimpan dengan filter kolom kustom dapat dibagikan ke grup/peran tertentu melalui menu *Project Lists*. |
| **21** | `one_drive_sharepoint_file_storage` | `Administration` $\rightarrow$ `File storages` | Konektor integrasi penyimpanan berkas korporat berbasis protokol Microsoft Graph / Drive selain Nextcloud internal. | Memberikan fleksibilitas apabila terdapat divisi yang menggunakan repositori dokumen berbasis SharePoint/OneDrive korporat. | Opsi pembuatan *File Storage* tipe OneDrive/SharePoint terbuka di menu Admin untuk diaktifkan bila diperlukan. |
| **22** | `mcp_server` | `Administration` $\rightarrow$ `System settings` / Endpoint MCP Internal | Layanan *Model Context Protocol (MCP) Server* internal yang memungkinkan agen AI *in-house* membaca dan mengelola konteks proyek secara terotorisasi. | Menghubungkan asisten AI/LLM lokal perusahaan ke data proyek, WBS, dan progres tugas dengan kontrol izin berbasis pengguna. | Konfigurasi dan *endpoint* MCP internal dapat diakses oleh *client* AI internal organisasi menggunakan autentikasi token internal. |
| **23** | `project_creation_wizard` | `Project Settings` $\rightarrow$ `Project initiation wizard` | Panduan langkah demi langkah (*multi-step wizard*) saat menginisiasi proyek baru untuk mengisi *Project Charter*, ruang lingkup, pemangku kepentingan, dan dokumen wajib. | Menegakkan kepatuhan prosedur administrasi inisiasi proyek sebelum proyek disetujui dan dijalankan. | Saat proyek baru dibuat, pengguna dipandu melalui antarmuka formulir bertahap dan menghasilkan ringkasan inisiasi proyek yang terstruktur. |

### Klaster E: Keamanan Siber, Audit Operasional & White-Labeling (7 Fitur)

| No | Kunci Fitur (`ee.features`) | Menu / Lokasi Sistem | Deskripsi Fungsional | Tujuan Implementasi In-House | Output yang Diharapkan (Deliverable Sistem) |
| :-: | :--- | :--- | :--- | :--- | :--- |
| **24** | `virus_scanning` | `Administration` $\rightarrow$ `System settings` $\rightarrow$ `Attachments` | Pemindaian antivirus otomatis berbasis **ClamAV** (daemon lokal/socket) terhadap setiap berkas lampiran yang diunggah pengguna sebelum disimpan ke ruang penyimpanan. | Mencegah penyebaran *malware* atau berkas berbahaya di dalam jaringan internal organisasi melalui lampiran proyek. | Pengaturan *Virus scanning* aktif di panel Admin; berkas yang terdeteksi mengandung *signature* berbahaya otomatis dikarantina/ditolak. |
| **25** | `capture_external_links` | `Administration` $\rightarrow$ `System settings` $\rightarrow$ `External links` | Gerbang intersepsi keamanan yang menahan setiap klik pada tautan eksternal di dalam deskripsi/komentar dan menampilkan halaman peringatan sebelum keluar dari domain internal. | Melindungi personel dari serangan *phishing* dan memastikan pengguna sadar saat akan meninggalkan jaringan intranet organisasi. | Setiap tautan luar dialihkan terlebih dahulu ke `/external_redirect` dengan pesan peringatan keamanan organisasi. |
| **26** | `internal_comments` | `Work Package Activity Tab` $\rightarrow$ Checkbox `Internal comment` | Fitur komentar rahasia/internal pada *Work Package* yang hanya dapat dilihat oleh peran (*Role*) yang memiliki izin khusus `View internal comments`. | Memungkinkan manajer proyek, tim keuangan, atau tim pengawas mendiskusikan isu sensitif langsung di dalam tiket tanpa terlihat oleh pelaksana umum/vendor. | Kotak centang *Internal comment* muncul saat menulis komentar; komentar ditandai dengan warna latar khusus dan tersembunyi dari peran biasa. |
| **27** | `readonly_work_packages` | `Administration` $\rightarrow$ `Work packages` $\rightarrow$ `Statuses` $\rightarrow$ `Read-only` | Penguncian mutlak seluruh atribut *Work Package* ketika tiket memasuki status tertentu (misal: *Closed*, *Audited*, atau *Approved Baseline*). | Menjamin integritas jejak audit (*audit trail*) sehingga data tugas yang sudah diserahterimakan tidak dapat diubah secara sepihak. | Ketika status bertanda *Read-only* dipilih, seluruh kolom *Work Package* terkunci dari perubahan kecuali statusnya dibuka kembali oleh Admin/PM berwenang. |
| **28** | `date_alerts` | `Notification Settings` & `Notification Center` | Mesin pengingat otomatis yang mengirimkan notifikasi sebelum *Start Date*, sebelum *Finish Date*, dan saat *Work Package* melewati tenggat waktu (*Overdue*). | Mencegah keterlambatan penyelesaian tugas kritis dengan memberikan peringatan dini kepada *Assignee* dan *Accountable*. | Pengaturan *Date Alerts* aktif pada profil notifikasi pengguna dan pengaturan sistem; pekerja latar mengirimkan pengingat tepat waktu. |
| **29** | `meeting_templates` | `Project Sidebar` $\rightarrow$ `Meetings` $\rightarrow$ `Templates` | Pembuatan cetak biru agenda rapat dinamis (*Dynamic Meeting Templates*) yang dapat digunakan berulang kali untuk rapat mingguan, tinjauan teknis, atau MoM. | Menstandardisasi struktur agenda dan risalah rapat (*Minutes of Meeting*) di seluruh proyek organisasi. | Pengguna dapat membuat *Template* rapat dan memakainya saat menjadwalkan rapat tunggal maupun rapat berulang (*Recurring Meetings*). |
| **30** | `define_custom_style` | `Administration` $\rightarrow$ `Design` | Antarmuka kustomisasi visual penuh untuk mengunggah logo organisasi, *favicon*, *touch icon*, serta mengatur palet warna primer, header, dan tombol. | Melakukan *white-labeling* menyeluruh sehingga aplikasi tampil $100\%$ sebagai sistem internal resmi milik organisasi. | Halaman `Administration -> Design` terbuka penuh; perubahan logo dan warna langsung mengkompilasi ulang variabel CSS aplikasi. |

### Klaster F: 5 Kunci Kompatibilitas & Ekstensi Tambahan

Selain 30 fitur utama di atas, sistem juga mendaftarkan 5 kunci kompatibilitas agar seluruh pemeriksaan di *frontend* maupun *backend* berjalan tanpa hambatan:
31. `conditional_highlighting` — Pewarnaan baris/atribut tabel *Work Package* berdasarkan kondisi prioritas, status, atau keterlambatan.
32. `multiple_active_sprints` — Kemampuan menjalankan lebih dari satu *sprint* atau iterasi aktif secara paralel dalam satu proyek.
33. `resource_management` — Pengelolaan kapasitas dan utilisasi sumber daya personel lintas proyek.
34. `time_entry_time_restrictions` — Pembatasan dan penguncian jendela waktu pencatatan jam kerja (*timesheet*).
35. `xwiki_integration` — Dukungan konektor basis pengetahuan eksternal/internal tambahan.

---

## 4. ARSITEKTUR "ADMIN FEATURE TOGGLE MANAGER" (SAKLAR ON/OFF DI MENU SETTINGS)

Agar Administrator memiliki kendali penuh untuk **menyalakan (ON)** atau **mematikan (OFF)** setiap fitur dari ke-35 fitur di atas kapan saja langsung dari antarmuka web tanpa perlu mengubah kode ulang:

1. **Penyimpanan Konfigurasi (`Setting.internal_enabled_features`):**
   - Didaftarkan melalui `Settings::Definition.add :internal_enabled_features` dengan nilai *default* berisi seluruh 35 kunci fitur aktif (`default: EnterpriseToken::ALL_INHOUSE_FEATURES.map(&:to_s)`), disimpan di tabel `settings` PostgreSQL.
2. **Evaluasi Dinamis pada `EnterpriseToken` (`app/models/enterprise_token.rb`):**
   - `EnterpriseToken.active_features` membaca daftar fitur yang dicentang di `Setting.internal_enabled_features` (dengan *fallback* aman ke `ALL_INHOUSE_FEATURES` apabila tabel `settings` belum termigrasi saat *booting*).
   - `EnterpriseToken.allows_to?(action)` mengembalikan `true` **hanya jika** fitur tersebut sedang dinyalakan (ON) pada menu Administrator Settings.
   - `EnterpriseToken.show_banners?` selalu mengembalikan `false` sehingga ketika suatu fitur dimatikan (OFF) oleh Administrator, fitur tersebut benar-benar nonaktif secara bersih **tanpa memunculkan banner promosi/upsell**.
3. **Halaman Pengaturan Administrator (`Administration` $\rightarrow$ `System settings` $\rightarrow$ `Modul Fitur Internal`):**
   - Menampilkan tabel interaktif yang dikelompokkan berdasarkan **Klaster A s.d. Klaster F**.
   - Setiap baris menampilkan: **Saklar Checkbox (ON/OFF)**, **Nama Fitur & Kunci Sistem**, **Lokasi Menu**, **Deskripsi & Tujuan**, serta **Output yang Diharapkan**.

---

## 5. MODUL EKSEKUSI BERTAHAP (MOD-00 s.d. MOD-08)

Kerjakan modul di bawah ini **satu per satu secara berurutan**. Setiap modul wajib diakhiri dengan ritual **Verify $\rightarrow$ Commit $\rightarrow$ Push $\rightarrow$ Live Deploy**.

---

### MOD-00: Kalibrasi Git, Dokumen Legal Internal & SOP Deploy
**Tujuan:** Mengunci *branch* kerja, membuat catatan lisensi internal, dan mendokumentasikan perintah *deploy* server.

1. Periksa status Git dan buat *branch* kerja:
   ```bash
   git status
   git checkout -b feat/inhouse-enterprise-hardening
   git push -u origin feat/inhouse-enterprise-hardening
   ```
2. Pastikan file `LICENSE` dan `COPYRIGHT` di direktori utama tetap utuh. Buat file `docs/plan/LEGAL_NOTICES.md` yang mencatat bahwa sistem ini dimodifikasi untuk penggunaan internal berdasarkan GNU GPLv3 serta mencantumkan atribusi *OpenProject Icon Font* (CC BY 3.0) di dalam dokumentasi internal.
3. Buat file `docs/plan/DEPLOY_SOP.md` berisi prosedur kompilasi aset dan *restart service* di server produksi. *(Jika Anda belum mengetahui cara restart service di server ini, jalankan **HALT & ASK** kepada User)*.
4. **Ritual Wajib:** Commit $\rightarrow$ Push $\rightarrow$ Verifikasi.

---

### MOD-01: Hardening Konfigurasi Lingkungan & Sentralisasi SSO IDS
**Tujuan:** Mematikan seluruh telemetri keluar via variabel lingkungan dan menyiapkan parameter SSO terpusat ke IDS.

1. Pada konfigurasi lingkungan aplikasi (`.env`, `/etc/openproject/conf.d/`, atau `config/configuration.yml`), terapkan pengaturan berikut:
   ```bash
   # 1. Isolasi Telemetri, Komunitas, Bantuan & Keamanan
   OPENPROJECT_SECURITY__BADGE__DISPLAYED="false"
   OPENPROJECT_SHOW__COMMUNITY__LINKS="false"
   OPENPROJECT_FORCE__HELP__LINK="/panduan-internal"
   OPENPROJECT_LOGIN__REQUIRED="true"
   OPENPROJECT_DROP__OLD__SESSIONS__ON__LOGIN="true"
   OPENPROJECT_DROP__OLD__SESSIONS__ON__LOGOUT="false"
   OPENPROJECT_ONBOARDING__VIDEO__URL=""
   OPENPROJECT_CSP__IMG__SRC="'self' data: blob:"
   OPENPROJECT_EMAIL__DELIVERY__METHOD="smtp"

   # 2. Sentralisasi SSO ke In-House IDS (Identity Server)
   # Catatan: Sesuaikan host IDS dengan parameter dari IT Development
   OPENPROJECT_OMNIAUTH__ALLOW__SINGLE__SIGN__ON="true"
   OPENPROJECT_SELF__REGISTRATION="0"
   ```
2. Buat initializer `config/initializers/inhouse_ids_sso_guard.rb` (dengan mempertahankan header `#-- copyright`) yang memastikan sistem siap menerima penyedia OIDC/SAML dari IDS internal tanpa validasi lisensi eksternal.
3. **Ritual Wajib:** Verify (`bundle exec rails runner "Rails.application.eager_load!"`) $\rightarrow$ Commit $\rightarrow$ Push $\rightarrow$ Live Deploy.

---

### MOD-02: Engine `EnterpriseToken` Dinamis & Definisi `Setting.internal_enabled_features`
**Tujuan:** Mengaktifkan ke-35 fitur secara *in-house* tanpa risiko *HTTP 500 Error*, sekaligus menghubungkannya ke penyimpanan konfigurasi dinamis `Setting.internal_enabled_features`.

1. Daftarkan definisi pengaturan `internal_enabled_features` pada `config/initializers/inhouse_feature_settings.rb` (atau di dalam `Settings::Definition`):
   ```ruby
   # frozen_string_literal: true

   #-- copyright
   # OpenProject is an open source project management software.
   # Copyright (C) the OpenProject GmbH
   # This program is free software; you can redistribute it and/or
   # modify it under the terms of the GNU General Public License version 3.
   # See COPYRIGHT and LICENSE files for more details.
   #++

   Rails.application.config.after_initialize do
     if defined?(Settings::Definition) && Settings::Definition[:internal_enabled_features].nil?
       Settings::Definition.add :internal_enabled_features,
                                default: EnterpriseToken::ALL_INHOUSE_FEATURES.map(&:to_s),
                                format: :array,
                                writable: true
     end
   end
   ```
2. Perbarui `app/models/enterprise_token.rb` dengan mempertahankan header `#-- copyright` asli dan seluruh delegasi objek token, serta menambahkan katalog `FEATURE_TAXONOMY` dan pembacaan `Setting.internal_enabled_features`:
   ```ruby
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

   class EnterpriseToken < ApplicationRecord
     ALL_INHOUSE_FEATURES = %i[
       sso_auth_providers
       ldap_groups
       scim_api
       nextcloud_sso
       placeholder_users
       team_planner_view
       board_view
       gantt_pdf_export
       baseline_comparison
       portfolio_management
       customize_life_cycle
       custom_actions
       custom_field_hierarchies
       calculated_values
       edit_attribute_groups
       weighted_item_lists
       work_package_subject_generation
       work_package_query_relation_columns
       work_package_sharing
       project_list_sharing
       one_drive_sharepoint_file_storage
       mcp_server
       project_creation_wizard
       virus_scanning
       capture_external_links
       internal_comments
       readonly_work_packages
       date_alerts
       meeting_templates
       define_custom_style
       conditional_highlighting
       multiple_active_sprints
       resource_management
       time_entry_time_restrictions
       xwiki_integration
     ].freeze

     TRUE_FEATURES = ALL_INHOUSE_FEATURES

     class << self
       def current
         @current ||= EnterpriseToken.order(Arel.sql("created_at DESC")).first || EnterpriseToken.new
       end

       def table_exists?
         super
       rescue StandardError
         false
       end

       def active?
         true
       end

       def show_banners?
         false
       end

       def enabled_feature_symbols
         if defined?(Setting) && Setting.table_exists? && Setting.respond_to?(:internal_enabled_features)
           raw = Setting.internal_enabled_features
           return ALL_INHOUSE_FEATURES if raw.nil?

           Array(raw).map(&:to_sym) & ALL_INHOUSE_FEATURES
         else
           ALL_INHOUSE_FEATURES
         end
       rescue StandardError
         ALL_INHOUSE_FEATURES
       end

       def allows_to?(action)
         return true if action.nil?

         enabled_feature_symbols.include?(action.to_sym)
       end

       def active_features
         enabled_feature_symbols
       end

       def non_triallable_features
         Set.new
       end

       def triallable_features
         Set.new
       end
     end

     delegate :will_expire?,
              :reprieve_days,
              :reprieve_days_left,
              to: :token_object,
              allow_nil: true

     def token_object
       @token_object ||= OpenProject::Token.new(
         subscriber: "In-House Organization Portal",
         mail: "admin@organisasi.local",
         company: "Internal Organization",
         domain: (Setting.host_name rescue "localhost"),
         issued_at: Time.zone.today,
         starts_at: Time.zone.today,
         expires_at: nil,
         restrictions: {}
       )
     end

     def subscriber
       "In-House Organization Portal"
     end

     def mail
       "admin@organisasi.local"
     end

     def company
       "Internal Organization"
     end

     def domain
       Setting.host_name
     rescue StandardError
       "localhost"
     end

     def issued_at
       Time.zone.today
     end

     def starts_at
       Time.zone.today
     end

     def expires_at
       nil
     end

     def restrictions
       {}
     end

     def unlimited_users?
       true
     end

     def max_active_users
       nil
     end

     def expired?(reprieve: true)
       false
     end

     def invalid_domain?
       false
     end

     def allows_to?(action)
       self.class.allows_to?(action)
     end
   end
   ```
3. **Ritual Wajib:** Verify $\rightarrow$ Commit $\rightarrow$ Push $\rightarrow$ Live Deploy.

---

### MOD-03: Pembuatan Menu & Antarmuka "Admin Feature Toggle Manager" (On/Off Modul di Menu Settings)
**Tujuan:** Menambahkan menu **Modular Feature Switcher** di dalam **Administration $\rightarrow$ System settings** agar Administrator dapat menyalakan/mematikan ke-35 fitur kapan saja, lengkap dengan tampilan Deskripsi, Tujuan, dan Output setiap fitur.

1. Buat katalog metadata fitur di `app/models/inhouse_feature_catalog.rb` (dengan header `#-- copyright` GPLv3) yang memuat struktur data ke-30 fitur utama + 5 fitur kompatibilitas beserta atribut `key`, `cluster`, `title`, `menu_location`, `description`, `objective`, dan `expected_output` persis sesuai **Bagian 3 dokumen ini**.
2. Buat controller `app/controllers/admin/settings/internal_features_settings_controller.rb`:
   ```ruby
   # frozen_string_literal: true

   #-- copyright
   # OpenProject is an open source project management software.
   # Copyright (C) the OpenProject GmbH
   # This program is free software; you can redistribute it and/or
   # modify it under the terms of the GNU General Public License version 3.
   # See COPYRIGHT and LICENSE files for more details.
   #++

   module Admin
     module Settings
       class InternalFeaturesSettingsController < ::Admin::SettingsController
         menu_item :internal_features_settings

         def show
           @clusters = ::InhouseFeatureCatalog.grouped_by_cluster
           @enabled_features = ::EnterpriseToken.enabled_feature_symbols.map(&:to_s)
         end

         def update
           selected = Array(params[:enabled_features]).map(&:to_s) &
                      ::EnterpriseToken::ALL_INHOUSE_FEATURES.map(&:to_s)
           Setting.internal_enabled_features = selected
           flash[:notice] = I18n.t(:notice_successful_update)
           redirect_to action: :show
         end
       end
     end
   end
   ```
3. Daftarkan rute di dalam `config/routes.rb` pada blok `namespace :admin do namespace :settings do`:
   ```ruby
   resource :internal_features,
            controller: "/admin/settings/internal_features_settings",
            only: %i[show update]
   ```
4. Daftarkan item menu di `config/initializers/menus.rb` pada blok `:admin_menu` di bawah parent `:settings`:
   ```ruby
   menu.push :internal_features_settings,
             { controller: "/admin/settings/internal_features_settings", action: "show" },
             caption: :"label_internal_feature_modules",
             parent: :settings,
             icon: " gear"
   ```
5. Buat tampilan `app/views/admin/settings/internal_features_settings/show.html.erb` yang menampilkan:
   - Tombol cepat **Aktifkan Seluruh Modul (35 Fitur)** dan **Matikan Semua**.
   - Tabel per klaster yang memuat *checkbox* `enabled_features[]`, Nama & Kunci Fitur, Lokasi Menu, Deskripsi, Tujuan, dan Output yang Diharapkan.
   - Tombol **Simpan Konfigurasi Modul**.
6. Tambahkan terjemahan label `label_internal_feature_modules: "In-House Feature Modules (On/Off)"` pada `config/locales/en.yml` (dan `id.yml` jika tersedia).
7. **Ritual Wajib:** Verify $\rightarrow$ Commit $\rightarrow$ Push $\rightarrow$ Live Deploy.

---

### MOD-04: Pembersihan Widget Eksternal & Security Badge pada Homescreen
**Tujuan:** Memastikan halaman utama (*Homescreen*) tidak menampilkan widget komunitas OpenProject, banner *upsell*, teaser fitur baru, maupun lencana keamanan eksternal.

1. Pertahankan header `#-- copyright` pada masing-masing file berikut, lalu ubah metode `render?` agar selalu mengembalikan `false`:
   - `app/components/homescreen/blocks/community.rb`
   - `app/components/homescreen/blocks/upsell.rb`
   - `app/components/homescreen/blocks/new_features.rb`
2. Pada `app/components/homescreen/blocks/administration.rb` (atau template partial-nya), nonaktifkan pemanggilan `security_badge` agar tidak pernah memuat skrip/gambar dari `releases.openproject.com`.
3. **Ritual Wajib:** Verify $\rightarrow$ Commit $\rightarrow$ Push $\rightarrow$ Live Deploy.

---

### MOD-05: Pemutusan Rute Trial (`augur.openproject.com`), Netralisasi `static_links.yml` & Komponen Banner Angular
**Tujuan:** Menghapus jalur *request* ke server lisensi/trial eksternal dan memastikan tidak ada tautan keluar ke `openproject.org` atau `openproject.com`.

1. Pada `config/routes.rb`, nonaktifkan (beri komentar `#`) pada blok `resource :enterprise_trial`.
2. Pada `config/static_links.yml`, ubah seluruh URL eksternal `https://www.openproject.org/...` menjadi rute relatif internal `"/"` atau `"/panduan-internal"`.
3. Pada `frontend/src/app/shared/components/enterprise-banner/enterprise-banner.component.html`, kosongkan isi template menjadi komentar HTML bersih agar tidak pernah merender elemen promosi maupun tautan eksternal di sisi *client* Angular.
4. **Ritual Wajib:** Verify (`npm run build` & `rails runner`) $\rightarrow$ Commit $\rightarrow$ Push $\rightarrow$ Live Deploy.

---

### MOD-06: Isolasi Privasi Avatar (`modules/avatars`) & Pembersihan CSP
**Tujuan:** Menghentikan pengiriman *hash* MD5 email anggota organisasi ke `secure.gravatar.com` dan membersihkan daftar domain eksternal pada kebijakan keamanan konten (CSP).

1. Pada `modules/avatars/lib/open_project/avatars/engine.rb`, ubah nilai default `enable_gravatars` menjadi `false`.
2. Pada `modules/avatars/lib/open_project/avatars/avatar_manager.rb`, ubah metode `gravatar_enabled?` agar selalu mengembalikan `false`.
3. Pada `config/initializers/content_security_policy.rb` (atau konfigurasi CSP terkait), hapus referensi domain eksternal `augur.openproject.com`, `releases.openproject.com`, dan `player.vimeo.com`.
4. **Ritual Wajib:** Verify $\rightarrow$ Commit $\rightarrow$ Push $\rightarrow$ Live Deploy.

---

### MOD-07: White-Labeling Identitas Organisasi & Netralisasi Footer Email (`UserMailer`)
**Tujuan:** Mematuhi ketentuan merek dagang dengan mengganti identitas visual aplikasi dan membersihkan atribusi eksternal pada email notifikasi.

1. Periksa template layout email di `app/views/layouts/mailer.html.erb` dan `app/mailers/user_mailer.rb` serta kunci lokalisasi `text_powered_by` di `config/locales/en.yml`.
2. Pastikan *footer* email hanya menampilkan nama portal manajemen proyek internal organisasi tanpa tautan ke `openproject.org`.
3. Set nilai default `app_title` pada `config/settings.yml` (atau melalui migrasi data `Setting.app_title`) menjadi nama sistem internal organisasi.
4. **Ritual Wajib:** Verify $\rightarrow$ Commit $\rightarrow$ Push $\rightarrow$ Live Deploy.

---

### MOD-08: Audit Akhir (Network, Legal, IDS SSO & 30-Feature Toggle Verification)
**Tujuan:** Memverifikasi secara menyeluruh bahwa sistem $100\%$ mandiri, patuh hukum, terhubung ke IDS SSO, dan saklar On/Off 30+5 fitur berfungsi tanpa *Error 500*.

1. Jalankan skrip verifikasi otomatis via `bundle exec rails runner`:
   - Pastikan `EnterpriseToken.active? == true` dan `EnterpriseToken.show_banners? == false`.
   - Uji fungsi saklar: matikan 1 fitur (misal `team_planner_view`) di `Setting.internal_enabled_features`, pastikan `EnterpriseToken.allows_to?(:team_planner_view) == false`, lalu aktifkan kembali dan pastikan nilainya `true`.
   - Pastikan `OpenProject::Avatars::AvatarManager.gravatar_enabled? == false`.
2. Pastikan file `LICENSE`, `COPYRIGHT`, dan `docs/plan/LEGAL_NOTICES.md` tersedia dan lengkap.
3. Buat laporan hasil audit di `docs/plan/AUDIT_VERIFICATION_REPORT.md`.
4. **Ritual Wajib:** Commit $\rightarrow$ Push $\rightarrow$ Live Deploy.