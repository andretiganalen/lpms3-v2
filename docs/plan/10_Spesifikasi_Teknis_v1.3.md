> **Status:** Buku Teknis v1.3 — tetap berlaku untuk rincian deploy (§4), sidebar (§12), LKP (§13), fungsi & kapabilitas (§14). **Diperbarui oleh Master Plan v2.0**: database utama = StarRocks `default_catalog.lpms3` (menggantikan `lpms3_dw` PostgreSQL), istilah fungsi mengikuti CLP-001 (Fungsi Manajemen Proyek = Fungsi Pelaksanaan Proyek BOP-001), skala risiko ROP-911.

# RENCANA DEPLOYMENT LPMS3 BERBASIS OPENPROJECT
## Len Project Management System 3 — Clean Deploy di `192.168.125.14:5100`

| Item | Nilai |
|---|---|
| Dokumen | PLAN-LPMS3-OP-001 |
| Versi | 1.3 (draft untuk dieksekusi) |
| Tanggal | 9 November 2026 |
| Riwayat | 1.0 — rencana awal deploy & konfigurasi BOP-001. 1.1 — sidebar LPMS3 wajib (§12), plugin `openproject-lpms3`, image Docker kustom, impor DB LPMS 2, Procurement Pipeline, Gate Sidebar (G-SB) sebelum deploy produksi, jadwal diperbarui. 1.2 — ETL LKP (FFR-708) multi-format dari 10 sampel Oktober 2026, tabel kanonik `lpms3_dw`, aturan validasi, hierarki approval Admin Teknis → Direksi, visibilitas berjenjang (§13). 1.3 — model Fungsi → Struktur Organisasi (berversi, SKEP.HC/DU/I/2026 & Nota 021/N/UQ/VIII/2026) → kapabilitas user; Fungsi Proyek & Fungsi Manajemen Proyek sebagai pusat pengguna (§14) |
| Penyusun | Andre Tigana (dibantu Claude) |
| Acuan utama | BOP-001 Manajemen Proyek Rev.01 (PT Len Industri), PMBOK® Guide 7th Ed., PMBOK® Guide 8th Ed. |
| Sumber aplikasi | GitHub `opf/openproject-docker-compose` (stack resmi) + repo konfigurasi internal `lpms3-openproject` |
| Target | Host `192.168.125.14`, port `5100`, instalasi bersih (tanpa migrasi data) |

---

## 0. RINGKASAN EKSEKUTIF

Rencana ini men-deploy OpenProject Community Edition dari repositori GitHub resminya ke server `192.168.125.14`, diekspos di port `5100`, lalu mengonfigurasinya sebagai **LPMS3** — sistem yang menjalankan alur BOP-001 (Inisiasi → Perencanaan → Eksekusi → Pengawasan & Pengendalian → Penutupan) lengkap dengan formulir (BFR-001, CFR-022, FFR-708, FFR-710, RFR-002, VFR-015, BOT-001), matriks RASCI, dan *Integrated Change Control*/CCM.

Prinsip desain:

1. **Infrastructure & configuration as code.** Semua yang bisa dikodekan (compose override, `.env.example`, skrip seed tipe/status/workflow/custom field/role, skrip backup, skrip laporan) disimpan di repo Git internal. Server hanya menyimpan secret (`.env`) dan data.
2. **Clean & reproducible.** Seluruh instalasi bisa dihapus dan dibangun ulang dari repo + backup dalam < 2 jam.
3. **BOP-001 sebagai "hukum", PMBOK 7/8 sebagai "kerangka".** BOP-001 menentukan alur, peran, dan formulir. PMBOK 8 (focus areas + 7 performance domains + 6 principles) dan PMBOK 7 (8 performance domains + 12 principles) dipakai untuk memastikan cakupan, struktur data, dan pelaporan.
4. **Community Edition dulu.** Fitur yang hanya tersedia di Enterprise diberi tanda **[EE]** beserta alternatif Community-nya.

5. **Sidebar LPMS3 adalah prasyarat deploy.** Navigasi pengguna disusun menjadi OVERVIEW · PHASE · PROJECT · SETTINGS (§12) melalui plugin `openproject-lpms3` yang dibangun ke image Docker kustom dari repo Git. Produksi `:5100` baru di-deploy setelah **Gate Sidebar (G-SB)** lulus di staging.
6. **LKP (FFR-708) dari berbagai format masuk ke tabel kanonik.** Unggahan Pimpro (PDF SAP, PDF Excel, .xlsx) diekstrak oleh layanan `lkp-etl`, divalidasi, disimpan di database `lpms3_dw`, lalu disetujui berjenjang **Admin Teknis → Pimpro → Fungsi Pengawasan → Eselon II → Eselon I → Direksi**; setiap level hanya melihat data yang sudah disetujui level di bawahnya (§13).
7. **Hak akses mengikuti Fungsi dan Struktur Organisasi yang berlaku.** Setiap user bertindak atas nama Fungsi; Fungsi dipetakan ke unit aktual pada versi struktur organisasi yang aktif, dan pemetaan itu menentukan kapabilitasnya. **Fungsi Proyek dan Fungsi Manajemen Proyek adalah pusat pengguna**; fungsi lain berperan sebagai kontributor atau pimpinan/tembusan (§14).

Durasi indikatif: **12 minggu** — platform & konfigurasi BOP-001 di staging berjalan paralel dengan 7 sprint plugin; G-SB minggu 8; deploy produksi bersih minggu 9; pilot/UAT minggu 9–10; go-live minggu 11; hypercare hingga minggu 12.

---

## 1. ASUMSI & KEPUTUSAN TERBUKA

### 1.1 Asumsi (dipakai bila tidak ada keputusan lain)

| # | Asumsi | Dampak bila salah |
|---|---|---|
| A1 | Server `192.168.125.14` adalah VM/fisik **Ubuntu Server 24.04 LTS** (x86_64) yang baru/bersih, akses `sudo` tersedia. | Perintah instalasi Docker perlu disesuaikan (RHEL/Rocky: `dnf`). |
| A2 | Akses hanya dari LAN/VPN Len (subnet `192.168.125.0/24` + subnet kantor lain yang ditentukan). Tidak dipublikasikan ke Internet. | Bila publik → wajib TLS + WAF sebelum go-live. |
| A3 | Fase awal memakai **HTTP** (`OPENPROJECT_HTTPS=false`) karena diakses via IP. TLS internal dijadwalkan di Fase 9. | Data login lewat jaringan tanpa enkripsi → mitigasi: batasi subnet, segera pasang TLS. |
| A4 | Server punya akses keluar ke `github.com`, `ghcr.io`/Docker Hub (`openproject/openproject`), dan repositori paket Ubuntu. | Bila air-gapped → siapkan registry mirror/`docker save` offline (Lampiran D). |
| A5 | Versi target: **OpenProject 17.x (branch `stable/17`)**, rilis terakhir yang terverifikasi 17.9.6. Saat eksekusi, cek apakah sudah ada `stable/18`. | Nama variabel/skrip seed mungkin perlu penyesuaian bila mayor berubah. |
| A6 | Edisi **Community** (gratis, GPLv3). | Fitur [EE] memakai alternatif. |
| A7 | Bahasa antarmuka default **Bahasa Indonesia**, zona waktu **Asia/Jakarta**. | — |
| A8 | Repo konfigurasi disimpan di GitHub organisasi Len (privat) atau Git internal (GitLab/Gitea). | Ganti URL remote saja. |

### 1.2 Keputusan yang perlu ditetapkan (sebelum Fase 2)

| # | Keputusan | Opsi | Rekomendasi |
|---|---|---|---|
| D1 | Autentikasi | Lokal / LDAP-AD Len / SSO (OIDC/SAML) | LDAP-AD Len (Community mendukung LDAP); SSO OIDC bila tersedia IdP. |
| D2 | SMTP notifikasi | Relay internal Len / tidak ada | Relay internal (`smtp.len.co.id` atau sesuai IT). |
| D3 | Nama host final | Tetap IP / `lpms.len.co.id` | Siapkan DNS internal; IP tetap untuk Fase 1. |
| D4 | Edisi | Community / Enterprise (Basic–Corporate) | Mulai Community; evaluasi EE setelah pilot (lihat §7.6). |
| D5 | Integrasi ERP (anggaran/PO) | Tidak / ekspor-impor / API | Di luar cakupan rilis 1; siapkan field referensi nomor PR/PO/WBS-ERP. |
| D6 | Integrasi dokumen | Modul Documents bawaan / Nextcloud / SharePoint | Bawaan dulu; Nextcloud bila Len sudah punya. |
| D7 | Pemilik sistem (System Owner) | Fungsi PMO / Project Deployment Center / TI | Fungsi Pengawasan Proyek (PMO) sebagai *business owner*, TI sebagai *technical owner*. |
| D8–D11 | Sumber LPMS 2, data pengadaan, butir menu kosong, tema | — | **Sudah ditetapkan** — lihat §12.1 |
| D12 | Lingkungan staging | VM terpisah / host yang sama port lain | VM terpisah (spesifikasi minimum §2.2) agar produksi :5100 tetap bersih |
| D13 | Keterlibatan fungsi pendukung | DIRECT (mengisi sendiri) / PROXY (diisi Fungsi Proyek, dikonfirmasi) per fungsi | DIRECT: Pengadaan, Mutu, Risiko, K3LH, Keuangan; PROXY: lainnya (§14.3) |
| D14 | Sumber data struktur & posisi | Input manual / impor HC / sinkron AD | Impor dari HC untuk versi struktur + sinkron AD untuk akun; pemetaan Fungsi → Unit oleh PMO sesuai Nota 021 |

---

## 2. ARSITEKTUR TARGET

### 2.1 Topologi

```
        Pengguna (browser, LAN/VPN Len)
                     │  http://192.168.125.14:5100
                     ▼
┌───────────────────────────── Host 192.168.125.14 (Ubuntu 24.04) ─────────────────────────────┐
│  UFW: allow 5100/tcp dari subnet yang diizinkan, 22/tcp dari subnet admin                     │
│                                                                                               │
│  Docker Compose project: lpms3                                                                │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌────────────┐                    │
│  │  proxy   │──▶│   web    │   │  worker  │   │   cron   │   │ hocuspocus │ (kolaborasi doc)   │
│  │ (Caddy)  │   │ (Rails)  │   │(GoodJob) │   │          │   │            │                    │
│  │ :80→5100 │   └────┬─────┘   └────┬─────┘   └────┬─────┘   └────────────┘                    │
│  └──────────┘        │              │              │                                          │
│                ┌─────▼──────────────▼──────────────▼─────┐   ┌──────────┐   ┌──────────┐       │
│                │        db (PostgreSQL 17)                │   │  cache   │   │ autoheal │       │
│                └──────────────────────────────────────────┘   │(memcached)│  └──────────┘       │
│                                                               └──────────┘                    │
│  Data persisten: /srv/lpms3/pgdata  (DB)   /srv/lpms3/opdata (lampiran/assets)                 │
│  Backup lokal:   /srv/lpms3/backup  ──rsync──▶ storage backup Len (NAS/off-host)               │
└───────────────────────────────────────────────────────────────────────────────────────────────┘
```

Catatan: nama layanan mengikuti `docker-compose.yml` di branch `stable/17`. Verifikasi dengan `docker compose config --services` setelah clone (Fase 2). Layanan `web`, `worker`, `cron`, `seeder` memakai **image kustom `lpms3/openproject:<versi>-lpms3.<versi plugin>`** (image resmi + plugin `openproject-lpms3`, §12.5). Plugin membuka koneksi read-only ke **DB LPMS 2** saat impor proyek (§12.7). Layanan tambahan **`lkp-etl`** (Python, tanpa port publik) mengekstrak LKP ke database **`lpms3_dw`** di container Postgres yang sama (§13.3).

### 2.2 Sizing server

| Komponen | Minimum (pilot ≤ 50 user) | Rekomendasi (produksi ≤ 300 user) |
|---|---|---|
| vCPU | 4 | 8 |
| RAM | 8 GB | 16 GB |
| Disk sistem | 40 GB SSD | 60 GB SSD |
| Disk data (`/srv/lpms3`) | 100 GB SSD | 250 GB SSD (LVM, bisa diperbesar) |
| Disk/target backup | 2× ukuran data | Off-host NAS, retensi sesuai COP-002 |

### 2.3 Struktur repositori konfigurasi (`lpms3-openproject`)

```
lpms3-openproject/
├── README.md                     # cara deploy/rebuild singkat
├── upstream/                     # git submodule → opf/openproject-docker-compose (stable/17)
├── compose/
│   ├── docker-compose.override.yml   # port, volume path, DB password, mount seed, image kustom, resource limit
│   └── .env.example                  # semua variabel TANPA secret
├── docker/
│   ├── Dockerfile                    # FROM openproject/openproject:<OP_TAG> + plugin LPMS3 (§12.5)
│   └── Gemfile.plugins
├── plugin/
│   └── openproject-lpms3/            # sidebar, halaman OVERVIEW/PHASE/PROJECT/SETTINGS, impor LPMS 2 (§12.4), approval LKP (§13.6)
├── etl/                              # layanan lkp-etl: parser V1–V5, profil YAML, validasi, DDL lpms3_dw (§13)
├── lpms3/
│   ├── seed/
│   │   ├── 00_settings.rb        # bahasa, zona waktu, kebijakan password, registrasi
│   │   ├── 10_statuses.rb
│   │   ├── 20_types.rb
│   │   ├── 30_custom_fields.rb   # WP & project attributes
│   │   ├── 40_roles.rb           # peran BOP-001 + permission
│   │   ├── 50_workflows.rb       # transisi status per tipe per peran
│   │   ├── 60_lifecycle.rb       # fase & gate proyek
│   │   └── 70_templates.rb       # project template LPMS3
│   ├── templates/                # BOT-001, CFR-022, FFR-708, FFR-710 (markdown/wiki)
│   └── reports/                  # skrip API v3 → FFR-708, Change Log, Risk Register (CSV/XLSX)
├── ops/
│   ├── backup.sh  restore.sh  upgrade.sh  healthcheck.sh
│   └── systemd/ (timer backup)
├── docs/
│   ├── PLAN (dokumen ini)  RUNBOOK.md  CHANGELOG.md
│   └── mapping-BOP001.md   matrix-PMBOK.md
└── .github/workflows/lint.yml    # rubocop/shellcheck/yamllint (opsional)
```

Aturan repo: `.env`, dump DB, dan file lampiran **tidak pernah** di-commit (`.gitignore`). Setiap perubahan konfigurasi LPMS3 melalui Pull Request dan dicatat di `CHANGELOG.md` — ini sekaligus menerapkan *Integrated Change Control* BOP-001 §5.4.2 terhadap sistemnya sendiri.

---

## 3. FASE PELAKSANAAN (RINGKAS)

| Fase | Nama | Minggu | Keluaran | Gate (kriteria lanjut) |
|---|---|---|---|---|
| F0 | Persiapan & keputusan | 0 | Keputusan D1–D12, akses server & staging, repo dibuat | Semua keputusan terisi atau ada default |
| F1 | Penyiapan server (produksi & staging) | 1 | OS terupdate, Docker, firewall, disk data | Checklist F1 lulus di kedua server |
| F2S | Deploy OpenProject di **staging** | 1 | Stack resmi berjalan di staging | `/health_checks/full` OK |
| F3 | Hardening & integrasi dasar (staging) | 2 | Admin aman, SMTP, LDAP, backup harian | Restore drill sukses |
| F4 | Konfigurasi LPMS3 (BOP-001) | 2–4 | Tipe, status, workflow, CF, role, fase/gate | Seed idempoten jalan 2× tanpa error |
| **F4b** | **Plugin LPMS3 & sidebar** (7 sprint) + **ETL LKP & approval** (E1–E4), paralel | 2–8 | Image `lpms3/openproject:17.9.6-lpms3.1.0`, `lpms3/lkp-etl`, §12–§13 | Spec plugin & golden-file hijau |
| F5 | Template & pelaporan | 5 | Project template, BOT-001, CFR-022, FFR-708 | Template menghasilkan proyek uji lengkap |
| **G-SB/ETL** | **Gate Sidebar & ETL LKP** | 8 | BA G-SB/ETL (§12.10, §13.9, §14.9) | S01–S12, E01–E10, F01–F08 lulus, disahkan SVP PMO |
| **F2P** | **Deploy produksi bersih** `192.168.125.14:5100` | 9 | Image teruji + seed + template + hardening + backup | Health check, smoke test, S01–S05 diulang di produksi |
| F6 | Pilot & UAT | 9–10 | 1–2 proyek pilot nyata (diimpor dari LPMS 2), BA UAT | ≥ 95% skenario UAT lulus, 0 defect kritikal |
| F7 | Go-live & hypercare | 11–12 | Pelatihan, cut-over, dukungan 2 minggu | BA go-live ditandatangani |
| F8 | Operasi berkelanjutan | ≥ 13 | Runbook, upgrade terjadwal, review bulanan | — |
| F9 | Peningkatan (opsional) | ≥ 13 | TLS/DNS, SSO, rilis 2 sinkron ERP Procurement, evaluasi EE | Sesuai CR |

---

## 4. LANGKAH TEKNIS DEPLOYMENT (F1–F3)

> Semua perintah dijalankan di `192.168.125.14` sebagai user admin ber-`sudo`. Blok bertanda **CEK** adalah titik verifikasi; jangan lanjut bila gagal.
>
> **Urutan v1.1:** langkah F1–F3 dan seluruh konfigurasi dijalankan **lebih dulu di staging** (ganti IP/host di `.env` staging). Di produksi `192.168.125.14:5100`, F2 dijalankan sekali saja sebagai **F2P** setelah G-SB lulus, langsung memakai image kustom (§12.5) — sehingga produksi benar-benar bersih dan tidak pernah menjalankan image tanpa plugin.

### F1 — Penyiapan server

**F1.1 Pre-flight (pastikan benar-benar bersih)**

```bash
hostnamectl; lsb_release -a; uname -m          # Ubuntu 24.04, x86_64
ip -4 addr | grep 192.168.125.14               # IP sesuai
sudo ss -ltnp | grep -E ':5100\b' || echo "port 5100 bebas"
docker ps -a 2>/dev/null || echo "docker belum terpasang"
df -h; lsblk                                   # disk data tersedia
timedatectl                                    # NTP aktif
```

Bila ditemukan instalasi OpenProject lama dan diputuskan dibersihkan: **backup dulu** (`docker compose ... run backup` atau `pg_dump`), simpan di luar host, baru hapus container, volume, dan direktori data. Pembersihan wajib dicatat di log perubahan.

**F1.2 Update OS, zona waktu, paket dasar**

```bash
sudo apt update && sudo apt -y full-upgrade
sudo timedatectl set-timezone Asia/Jakarta
sudo apt -y install ca-certificates curl gnupg git ufw openssl jq unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades   # security update otomatis
```

**F1.3 Disk data**

```bash
# contoh: disk kedua /dev/sdb → LVM → /srv/lpms3
sudo pvcreate /dev/sdb && sudo vgcreate vg_lpms3 /dev/sdb
sudo lvcreate -l 100%FREE -n lv_data vg_lpms3
sudo mkfs.ext4 /dev/vg_lpms3/lv_data
sudo mkdir -p /srv/lpms3
echo '/dev/vg_lpms3/lv_data /srv/lpms3 ext4 defaults,noatime 0 2' | sudo tee -a /etc/fstab
sudo mount -a
sudo mkdir -p /srv/lpms3/{pgdata,opdata/assets,backup,app}
sudo chown -R 1000:1000 /srv/lpms3/opdata      # UID app OpenProject
```

**F1.4 Docker Engine + Compose plugin (repo resmi Docker)**

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
sudo apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER   # logout/login
```

Batasi log container agar disk tidak penuh:

```bash
sudo tee /etc/docker/daemon.json >/dev/null <<'EOF'
{ "log-driver": "json-file", "log-opts": { "max-size": "50m", "max-file": "5" } }
EOF
sudo systemctl restart docker
```

**F1.5 Firewall**

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.125.0/24 to any port 22 proto tcp     # sesuaikan subnet admin
sudo ufw allow from 192.168.125.0/24 to any port 5100 proto tcp   # tambah subnet user lain bila perlu
sudo ufw enable && sudo ufw status verbose
```

> Perhatian: Docker dapat mem-bypass UFW untuk port yang dipublikasikan. Untuk kontrol ketat, tambahkan aturan di chain `DOCKER-USER` (Lampiran C) atau batasi via firewall jaringan.

**CEK F1:** `docker run --rm hello-world` sukses; `/srv/lpms3` ter-mount; `ufw status` sesuai; `timedatectl` = Asia/Jakarta.

### F2 — Deploy OpenProject dari GitHub (bersih)

**F2.1 Siapkan repo konfigurasi dan upstream**

```bash
cd /srv/lpms3/app
git clone git@github.com:<org-len>/lpms3-openproject.git .
# bila repo baru, tambahkan upstream resmi sebagai submodule pada branch stable:
git submodule add -b stable/17 https://github.com/opf/openproject-docker-compose.git upstream
git submodule update --init --depth=1
cd upstream && git log -1 --oneline && cd ..        # catat commit hash di CHANGELOG
```

Alternatif paling sederhana (sesuai dokumentasi resmi):
`git clone https://github.com/opf/openproject-docker-compose.git --depth=1 --branch=stable/17 upstream`

**CEK:** `ls upstream` berisi `docker-compose.yml`, `.env.example`, `docker-compose.control.yml`. Jalankan `cd upstream && docker compose config --services` dan catat daftar layanan.

**F2.2 Buat `.env` (di `upstream/`, tidak di-commit)**

```bash
cd /srv/lpms3/app/upstream
cp .env.example .env
SKB=$(openssl rand -hex 64); PGPW=$(openssl rand -base64 30 | tr -d '/+=' | cut -c1-32)
COLLAB=$(openssl rand -hex 32); ADMINPW=$(openssl rand -base64 18)
echo "Simpan di password vault: ADMINPW=$ADMINPW PGPW=$PGPW"   # lalu hapus dari history shell
```

Isi/ubah nilai berikut di `.env` (nama variabel lain dibiarkan sesuai `.env.example` versi tersebut):

```dotenv
# --- Versi & jaringan ---
TAG=17-slim                                  # samakan dengan default .env.example stable/17; pin minor saat go-live (mis. 17.9.6-slim)
OP_TAG=17.9.6                                # basis image kustom LPMS3 (§12.5)
LPMS3_IMAGE_TAG=17.9.6-lpms3.1.0             # image yang lulus G-SB
LPMS3_NATIVE_MENU=pmo_only                   # modul bawaan hanya untuk PMO/Admin (§12.2)
LPMS2_DATABASE_URL=<adapter>://lpms3_ro:<pw>@<host-lpms2>:<port>/<db>   # impor Add New (§12.7)
PORT=5100                                    # proxy dipublikasikan ke 0.0.0.0:5100
OPENPROJECT_HTTPS=false                      # fase 1 tanpa TLS (lihat F9)
OPENPROJECT_HOST__NAME=192.168.125.14:5100   # WAJIB sama dengan URL akses
COLLABORATIVE_SERVER_URL=ws://192.168.125.14:5100/hocuspocus
COLLABORATIVE_SERVER_SECRET=<COLLAB>

# --- Secret & data ---
SECRET_KEY_BASE=<SKB>                        # jangan diganti setelah go-live
OPDATA=/srv/lpms3/opdata
PGDATA=/srv/lpms3/pgdata

# --- Lokalisasi ---
OPENPROJECT_DEFAULT__LANGUAGE=id
OPENPROJECT_USER__DEFAULT__TIMEZONE=Asia/Jakarta

# --- Admin awal (seeder) ---
OPENPROJECT_SEED__ADMIN__USER__PASSWORD=<ADMINPW>
OPENPROJECT_SEED__ADMIN__USER__PASSWORD__RESET=true
OPENPROJECT_SEED__ADMIN__USER__MAIL=lpms-admin@len.co.id
OPENPROJECT_SEED__ADMIN__USER__NAME="LPMS Administrator"

# --- Email (D2) ---
OPENPROJECT_EMAIL__DELIVERY__METHOD=smtp
OPENPROJECT_SMTP__ADDRESS=<smtp.len.co.id>
OPENPROJECT_SMTP__PORT=587
OPENPROJECT_SMTP__DOMAIN=len.co.id
OPENPROJECT_SMTP__AUTHENTICATION=login
OPENPROJECT_SMTP__USER__NAME=<user>
OPENPROJECT_SMTP__PASSWORD=<pass>
OPENPROJECT_SMTP__ENABLE__STARTTLS__AUTO=true
OPENPROJECT_MAIL__FROM=lpms-noreply@len.co.id

# --- Postgres (dipakai override) ---
LPMS3_PG_PASSWORD=<PGPW>
```

> Verifikasi nama variabel lokalisasi/SMTP terhadap halaman *Configuration → Environment variables* OpenProject versi terpasang. Variabel yang salah nama diabaikan diam-diam, jadi cek hasilnya di Administrasi setelah start.

`chmod 600 .env`.

**F2.3 `docker-compose.override.yml`** (disimpan di repo `compose/`, di-symlink ke `upstream/`)

Tujuan: mengganti password DB default, memasang direktori data, me-mount skrip seed LPMS3, memberi batas resource.

```yaml
# compose/docker-compose.override.yml — sesuaikan nama layanan dengan hasil `docker compose config --services`
services:
  db:
    environment:
      POSTGRES_PASSWORD: ${LPMS3_PG_PASSWORD}
    restart: unless-stopped
  web:
    environment: &opdb
      DATABASE_URL: "postgres://postgres:${LPMS3_PG_PASSWORD}@db/openproject?pool=20&encoding=unicode&reconnect=true"
    volumes:
      - /srv/lpms3/app/lpms3:/app/lpms3:ro
    deploy: { resources: { limits: { memory: 6g } } }
  worker:   { environment: *opdb }
  cron:     { environment: *opdb }
  seeder:   { environment: *opdb }
```

```bash
ln -s ../compose/docker-compose.override.yml /srv/lpms3/app/upstream/docker-compose.override.yml
docker compose config > /tmp/lpms3-rendered.yml   # CEK: tidak ada "p4ssw0rd", PORT=5100, path /srv/lpms3
grep -n "p4ssw0rd" /tmp/lpms3-rendered.yml && echo "MASIH ADA PASSWORD DEFAULT!" ; rm /tmp/lpms3-rendered.yml
```

> Bila `docker-compose.yml` upstream mendefinisikan `DATABASE_URL` di anchor `x-op-app`, override di atas tetap menang karena digabung per layanan. Pastikan semua layanan aplikasi (web, worker, cron, seeder) mendapat `DATABASE_URL` yang sama.

**F2.4 Start pertama**

Di staging awal (sebelum plugin siap) image resmi boleh dipakai. Di **produksi (F2P)**, tambahkan blok image kustom §12.5 ke override, set `OP_TAG`/`LPMS3_IMAGE_TAG`, lalu `docker compose -p lpms3 build web` (atau `docker load` image yang sudah lulus G-SB) **sebelum** `up`. Jangan pakai `--pull always` untuk layanan yang memakai image kustom lokal.

```bash
cd /srv/lpms3/app/upstream
docker compose -p lpms3 pull --ignore-buildable
docker compose -p lpms3 up -d
docker compose -p lpms3 logs -f seeder     # tunggu "Seeding finished" / container exit 0
docker compose -p lpms3 ps                 # semua healthy/running (seeder: exited 0)
```

**CEK F2 (smoke test):**

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://192.168.125.14:5100/              # 200/302
curl -s http://192.168.125.14:5100/health_checks/default                         # PASSED
curl -s http://192.168.125.14:5100/health_checks/full                            # semua cek PASSED
curl -s http://192.168.125.14:5100/api/v3 | jq .instanceName
```

Dari PC di LAN: buka `http://192.168.125.14:5100`, login `admin` + `ADMINPW`, wajib ganti password. Di *Administrasi → Informasi*, catat versi dan pastikan tidak ada peringatan *host name mismatch*.

Simpan bukti (screenshot + output) ke `docs/evidence/F2/`.

### F3 — Hardening & integrasi dasar

| # | Pengaturan | Lokasi | Nilai LPMS3 |
|---|---|---|---|
| H1 | Registrasi mandiri | Admin → Autentikasi | **Nonaktif** (akun via admin/LDAP) |
| H2 | Kebijakan password | Admin → Autentikasi → Password | Min. 12 karakter, kombinasi 3 kelas, rotasi sesuai kebijakan TI Len |
| H3 | Brute force | Admin → Autentikasi | Blokir setelah 5 gagal, 30 menit |
| H4 | Sesi | Admin → Autentikasi | Kedaluwarsa idle 120 menit |
| H5 | 2FA | Admin → Autentikasi → 2FA | Wajib untuk admin; opsional user (TOTP) |
| H6 | LDAP/AD (D1) | Admin → Autentikasi → LDAP | Bind user read-only, filter grup `LPMS3-Users`, on-the-fly creation aktif, sinkron grup → group OpenProject |
| H7 | Email | Admin → Email | Uji kirim; footer: klausul kerahasiaan Len (*Internal Use*) |
| H8 | Lampiran | Admin → Lampiran | Maks. 256 MB; aktifkan *antivirus scan* bila ClamAV tersedia |
| H9 | Nama instans & branding | Admin → Pengaturan umum / Desain | "LPMS3 — PT Len Industri"; warna korporat (logo kustom adalah [EE]) |
| H10 | Bahasa | Admin → Bahasa | `id` + `en` saja |
| H11 | API | Admin → API | API v3 aktif; token hanya untuk akun servis `svc-lpms3-report` |
| H12 | Akun admin | Users | Admin bawaan dinonaktifkan setelah ada ≥ 2 admin bernama |

**Backup harian (wajib sebelum F4)** — `ops/backup.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
TS=$(date +%Y%m%d-%H%M); DST=/srv/lpms3/backup/$TS; mkdir -p "$DST"
cd /srv/lpms3/app/upstream
docker compose -p lpms3 exec -T db pg_dump -U postgres -Fc openproject > "$DST/openproject.dump"
docker compose -p lpms3 exec -T db pg_dump -U postgres -Fc lpms3_dw > "$DST/lpms3_dw.dump"   # data LKP (§13)
tar -C /srv/lpms3 -czf "$DST/opdata.tgz" opdata
tar -C /srv/lpms3 -czf "$DST/lkp-raw.tgz" lkp-raw                                               # berkas LKP asli
cp .env "$DST/env.backup" && chmod 600 "$DST/env.backup"
git -C /srv/lpms3/app rev-parse HEAD > "$DST/config-commit.txt"
sha256sum "$DST"/* > "$DST/SHA256SUMS"
find /srv/lpms3/backup -maxdepth 1 -type d -mtime +14 -exec rm -rf {} +   # retensi lokal 14 hari
rsync -a "$DST" backup@<nas-len>:/lpms3/                                   # off-host
```

Jadwalkan via systemd timer pukul 01:30 WIB. Retensi off-host mengikuti **COP-002 (Informasi Terdokumentasi)**.

**CEK F3 — Restore drill (wajib):** pada VM uji, jalankan `ops/restore.sh <backup>` → aplikasi naik, data/lampiran utuh, login berhasil. Catat RTO aktual (target ≤ 2 jam) dan RPO (≤ 24 jam).

---

## 5. KONFIGURASI LPMS3 SESUAI BOP-001 (F4–F5)

Bagian ini adalah inti: menerjemahkan BOP-001 menjadi struktur data dan alur di OpenProject.

### 5.1 Model data: siapa disimpan di mana

| Objek BOP-001 | Objek OpenProject | Catatan |
|---|---|---|
| Proyek (Kode Proyek, FOP-700) | **Project** + project attributes | Satu project per Kode Proyek; identifier = Kode Proyek (huruf kecil, tanda hubung). |
| Proyek Purnajual (§5.5.3) | **Sub-project** dari proyek induk | Kode purnajual terpisah; dibuat dari template "LPMS3-Purnajual". |
| Program/portofolio | Project induk (hierarki) | Fitur portofolio penuh [EE]; Community: proyek induk + filter project list. |
| Tahap (Inisiasi–Penutupan) | **Project phases & gates** (Project life cycle) | Lihat §5.4. Bila fitur tidak tersedia di edisi terpasang → tipe WP "Fase" + "Gate" (milestone). |
| WBS / Deliverable | Hierarki WP: **Deliverable** → **Work Package/Task** | WBS code sebagai custom field; Gantt dari hierarki. |
| Formulir BFR-001 Change Request | Tipe WP **Change Request** | Workflow CCM, §5.5. |
| Change Log (§5.4.2) | Query tersimpan "Change Log" (semua CR, semua status) + ekspor | Jejak audit dari activity/journal WP. |
| RFR-002 Project Risk Register | Tipe WP **Risiko** + query "Risk Register" | Update bulanan (§5.3.6). |
| VFR-015 Bahaya-Risiko K3 & Aspek-Dampak LH | Tipe WP **Bahaya K3L** | Terpisah dari risiko proyek; kolom HIRADC. |
| Issue Log / Action Tracker | Tipe WP **Isu** dan **Action Item** | Isu dari pengadaan (§5.3.7) juga masuk sini. |
| Lessons Learned Register (§5.3.2) | Tipe WP **Lesson Learned** + Wiki proyek "Lessons Learned" | Query global lintas proyek untuk proyek berikutnya. |
| CFR-022 Risalah Rapat | Modul **Meetings** (agenda, outcome, action item → WP) | Ekspor PDF sebagai arsip. |
| Kick-Off Meeting (§5.2.2) | Meeting template "Kick-Off" + Gate G2 | Hasil = Baseline 0. |
| Rapat Tinjauan Proyek (§5.4.8) | Meeting berulang "Tinjauan Proyek" | Agenda per aspek (Tabel 4 BOP-001). |
| FFR-708 Laporan Kemajuan | Unggahan LKP Pimpro → ETL → tabel kanonik `lpms3_dw` → approval berjenjang (§13); Project status + overview | Paling lambat tgl 5 bulan berikutnya ke Fungsi Akuntansi. |
| FFR-710 Laporan Dokumentasi Proyek | Checklist WP tipe **Dokumen Proyek** + modul Documents | Gate G4. |
| BOT-001 Template Project Charter | Template deskripsi WP "Project Charter" + Wiki template | Gate G1. |
| RAB / Rencana Arus Kas / PIS | Modul **Budgets** + Cost types + Time & costs | Nilai kontrak sebagai project attribute. |
| Top Up Anggaran (BOG-003) | Tipe WP **Top Up Anggaran** | Workflow ringan; terkait Budget. |
| Quality: inspeksi, NCR, T&C | Tipe WP **Inspeksi Mutu**, **NCR** | QOG-001/QOG-002, audit QOP-803. |
| Pengadaan (GR/SES) | Tipe WP **Item Pengadaan** | No. PR/PO/GR/SES sebagai field referensi ERP. |
| Stakeholder Register & Engagement Plan | Tipe WP **Stakeholder** + query "Stakeholder Register" | Tingkat keterlibatan *current/desired*. |
| Dokumen PMP (9 rencana anak) | Tipe WP **Dokumen Rencana** (satu per rencana) + lampiran/Documents | Status Draft → Reviu → Disahkan; versi disahkan menjadi baseline. |
| Berita Acara (penerimaan deliverable) | Status "Diterima Pelanggan" pada Deliverable + lampiran BA | §5.3.1. |

### 5.2 Project attributes (custom field level proyek)

Kelompokkan dalam section agar halaman overview rapi.

| Section | Atribut | Format | Wajib | Sumber BOP-001 |
|---|---|---|---|---|
| Identitas | Kode Proyek | Teks (unik) | Ya | §5.1.1, FOP-700 |
| | Nama Pelanggan | Teks/List | Ya | §3.15 |
| | Nomor Kontrak / Tanggal Kontrak | Teks / Tanggal | Ya | §3.12, SOP-004 |
| | Nilai Kontrak (IDR) | Float | Ya | §5.4.1 rumus bobot |
| | Jenis/Klasifikasi Proyek | List (mis. Sistem Pertahanan, Transportasi, Energi, ICT, …) | Ya | §5.1.2 |
| | Pendekatan Delivery | List: Prediktif / Hibrid / Adaptif | Ya | PMBOK 7 *Development Approach*, tailoring |
| Organisasi | Project Sponsor | User | Ya | §3.17 |
| | Pimpro | User | Ya | §3.18, HOP-609 |
| | Fungsi Pelaksanaan Proyek (struktural) | User | Ya | RASCI Tabel 1 |
| | Fungsi Pengawasan Proyek (PIC) | User | Ya | §5.4 |
| Baseline | Tanggal Kick-Off (Baseline 0) | Tanggal | Ya (setelah G2) | §5.2.2 |
| | Tanggal Selesai Kontrak | Tanggal | Ya | — |
| | Nomor Adendum Terakhir | Teks | Tidak | SOP-009 |
| Nilai & Keberlanjutan | Tujuan bisnis / manfaat yang diharapkan | Teks panjang | Ya | PMBOK 7 *Value*, PMBOK 8 *Focus on Value* |
| | Pertimbangan keberlanjutan (ESG/K3L) | Teks panjang | Ya | PMBOK 8 *Integrate Sustainability* |
| Penutupan | Jenis Penutupan | List: Selesai 100% / Terminasi | Saat G4 | §5.5.1–5.5.2 |
| | Purnajual dipersyaratkan | Boolean | Ya | §5.5.3 |
| | Nomor Laporan Akhir Proyek | Teks | Saat G4 | §5.5 |

### 5.3 Tipe Work Package, status, dan field kunci

| Tipe | Status (urut) | Field kustom utama |
|---|---|---|
| **Deliverable** | Baru → Dikerjakan → Verifikasi Internal → Validasi Pelanggan → Diterima Pelanggan / Ditolak | Kode WBS, Harga Pekerjaan (IDR), Bobot (%), Kriteria Penerimaan, No. BA |
| **Task** | Baru → Dikerjakan → Selesai / Batal | Kode WBS |
| **Milestone** | Rencana → Tercapai / Tergeser | Jenis milestone (kontraktual/internal/pembayaran) |
| **Dokumen Rencana** (PMP) | Draft → Reviu → Revisi → Disahkan → Diganti (superseded) | Jenis rencana (9 area §5.2.1), Versi, Tanggal Sah |
| **Change Request** (BFR-001) | lihat §5.5 | lihat §5.5 |
| **Risiko** (RFR-002) | Teridentifikasi → Dianalisis → Respons Direncanakan → Dipantau → Terjadi (→ Isu) / Ditutup | Kategori, Ancaman/Peluang, Penyebab, Dampak, Probabilitas (1–5), Dampak (1–5), Skor (P×D), Tingkat (Rendah/Sedang/Tinggi/Ekstrem), Strategi (Hindari/Transfer/Mitigasi/Terima/Eksploitasi/Tingkatkan/Berbagi), Rencana mitigasi, Pemilik Risiko, Tanggal review berikutnya |
| **Bahaya K3L** (VFR-015) | Teridentifikasi → Dinilai → Pengendalian Diterapkan → Ditinjau → Ditutup | Aktivitas, Bahaya/Aspek, Risiko/Dampak, Risiko awal, Hierarki pengendalian, Risiko sisa, Regulasi terkait |
| **Isu** | Baru → Analisis → Tindak Lanjut → Selesai | Sumber (Pengadaan/Teknis/Pelanggan/…), Eskalasi ke manajemen (Bool) |
| **Action Item** | Baru → Dikerjakan → Selesai | Asal rapat (link Meeting) |
| **Lesson Learned** | Draft → Ditinjau → Dipublikasikan | Area (7 domain PMBOK 8), Apa yang terjadi, Akar masalah, Rekomendasi, Dapat dipakai ulang (Bool) |
| **Inspeksi Mutu** | Direncanakan → Dilaksanakan → Lulus / Gagal | Quality metric, Hasil ukur, Alat ukur (QOP-814) |
| **NCR** | Terbuka → Analisis Akar Masalah → Koreksi → Verifikasi → Ditutup | Severity, Tindakan korektif/preventif |
| **Item Pengadaan** | Rencana → PR → Proses Pengadaan → PO/Kontrak → Pengiriman → GR/SES → Selesai | No. PR, No. PO, Rekanan, Nilai, Make-or-Buy, Tanggal dibutuhkan |
| **Stakeholder** | Aktif / Tidak aktif | Organisasi, Peran, Kepentingan, Pengaruh (1–5), Kepentingan (1–5), Keterlibatan saat ini/diinginkan (Unaware/Resistant/Neutral/Supportive/Leading), Strategi |
| **Top Up Anggaran** (BOG-003) | Diajukan → Diverifikasi Pengendali Anggaran → Disetujui → Diinput ERP / Ditolak | Mata anggaran, Nilai, Justifikasi |
| **Dokumen Proyek** (FFR-710) | Belum → Terkumpul → Diverifikasi → Diarsipkan | Kategori arsip, Lokasi, Masa retensi (COP-002) |

Semua tipe memakai field bawaan: **Accountable** (A), **Assignee** (R), **Watchers** (I). Tambahkan dua field user multi-nilai: **Supporting (S)** dan **Consulted (C)** — sehingga RASCI BOP-001 hidup di setiap WP.

### 5.4 Siklus hidup proyek: fase & gate

| Fase (OpenProject) | Tahap BOP-001 | Gate penutup fase | Kriteria gate (bukti di sistem) | Accountable gate |
|---|---|---|---|---|
| P1 Inisiasi | §5.1 | **G1 — Project Charter ditetapkan** | Kode Proyek terisi (FOP-700); Pimpro & tim inti ditetapkan ≤ 2 minggu setelah kode dibuka (HOP-609); WP "Project Charter" (BOT-001) status Disahkan | Struktural Fungsi Pelaksanaan Proyek |
| P2 Perencanaan | §5.2 | **G2 — Kick-Off / Baseline 0** | 9 Dokumen Rencana status Disahkan; Meeting Kick-Off selesai dengan risalah CFR-022; tanggal Baseline 0 terisi; baseline jadwal disimpan | Eselon I/II Fungsi Pengawasan Proyek |
| P3 Eksekusi + Pengawasan & Pengendalian (paralel) | §5.3 + §5.4 | **G3 — Serah terima** | Seluruh Deliverable "Diterima Pelanggan" (BA terlampir) atau keputusan Terminasi (Radir); tidak ada CR/NCR terbuka yang kritikal | Struktural Fungsi Pelaksanaan Proyek |
| P4 Penutupan | §5.5 | **G4 — Proyek ditutup** | Laporan Akhir Proyek; FFR-710 lengkap; Lessons Learned dipublikasikan; Kode Proyek ditutup (FOP-705); kode Purnajual dibuka bila dipersyaratkan (FOP-700) | Pimpro (arsip) / Direksi (terminasi) |

Mengapa P3 menggabungkan Eksekusi dan Pengawasan & Pengendalian: BOP-001 §5.4 menyebut pengawasan "berkelanjutan sepanjang siklus Proyek", dan PMBOK 8 memperlakukan *Monitoring & Controlling* sebagai *focus area* yang berjalan bersama, bukan fase berurutan. Aktivitas pengawasan diwujudkan sebagai rapat berulang, laporan bulanan, dan workflow CR — bukan fase kalender.

Swimlane "Pengawasan Tahap" di Alur §7.0 BOP-001 diwujudkan sebagai **WP checklist pengawasan per fase** yang di-assign ke Fungsi Pengawasan Proyek.

> Implementasi: bila fitur *Project phases & gates* tersedia di edisi/versi terpasang (cek Admin → Project life cycle), seed `60_lifecycle.rb` membuat definisi fase/gate. Bila tidak, gunakan tipe WP "Fase" (parent) dan "Gate" (milestone) di template, dengan nama sama.

### 5.5 Workflow Integrated Change Control (BFR-001 / CCM)

**Status & transisi**

```
Draft ──(Pimpro)──▶ Diajukan ──(F. Pengawasan Proyek)──▶ Analisis Dampak ──▶ Sidang CCM
                                                                               │
                         ┌──────────────── rekomendasi CCM ────────────────────┤
                         ▼                        ▼                            ▼
                Disetujui (Pejabat)      Ditolak (Pejabat)           Ditunda (Pejabat) ──▶ Sidang CCM
                         │
                         ▼
              Implementasi (Pimpro) ──▶ Verifikasi (F. Pengawasan Proyek) ──▶ Ditutup
                         │
                         └─ bila "Perlu Adendum Kontrak" = Ya → WP Action "Adendum (SOP-009)" otomatis/ manual
```

**Field Change Request**

| Field | Format | Keterangan |
|---|---|---|
| Kategori perubahan | Multi-list: Ruang lingkup, Jadwal, Biaya, Mutu, Sumber daya, Risiko, Komunikasi, Pengadaan, Stakeholder, Kontrak | §5.4.2 |
| Asal permintaan | List: Pimpro, Fungsi Pengawasan, Penjaminan Mutu, Pelanggan, Rekanan | §5.4.x |
| Deskripsi & justifikasi | Teks panjang | BFR-001 |
| Dampak ruang lingkup / jadwal (hari) / biaya (IDR) / mutu / risiko / SDM / kontrak | Teks & angka | Analisis dampak wajib sebelum CCM |
| Rekomendasi CCM | List: Setuju / Tolak / Tunda + catatan | §3.2 |
| Pejabat berwenang | User | Matriks kewenangan |
| Tanggal keputusan | Tanggal | — |
| Perlu adendum kontrak | Boolean | → SOP-009 |
| Dokumen terdampak | Relasi ke WP Dokumen Rencana/Deliverable | Pembaruan baseline |

**Permission per transisi (workflow per peran)**

| Transisi | Peran yang diizinkan |
|---|---|
| Draft → Diajukan | Pimpro |
| Diajukan → Analisis Dampak | Fungsi Pengawasan Proyek |
| Analisis Dampak → Sidang CCM | Fungsi Pengawasan Proyek |
| Sidang CCM → Disetujui / Ditolak / Ditunda | Pejabat Berwenang (peran "Approver CCM") |
| Disetujui → Implementasi | Pimpro |
| Implementasi → Verifikasi | Pimpro |
| Verifikasi → Ditutup | Fungsi Pengawasan Proyek |

Setelah *Disetujui*, Pimpro memperbarui Dokumen Rencana terkait (versi baru → status Disahkan) dan, bila jadwal berubah, Fungsi Pengawasan menyimpan baseline baru. **Change Log** = query semua WP tipe CR (kolom: ID, judul, kategori, status, tanggal keputusan, pejabat, dampak biaya/jadwal) — disimpan sebagai query publik di template.

Workflow yang sama polanya (Pimpro mengajukan → Fungsi terkait meninjau) dipakai untuk permintaan perubahan yang dipicu oleh pemantauan jadwal, biaya, mutu, sumber daya, komunikasi, risiko, pengadaan, dan stakeholder (§5.4.3–5.4.11) — semua berujung pada BFR-001, sesuai BOP-001.

### 5.6 Peran (role) dan RASCI

**Peran proyek OpenProject**

| Role LPMS3 | Basis BOP-001 | Hak utama |
|---|---|---|
| Project Sponsor | §3.17 | Lihat semua, komentar, approve gate tertentu, lihat budget |
| Pimpro | §3.18 | Kelola proyek, anggota, WP, meeting, budget (lihat & edit rencana), ajukan CR |
| Tim Proyek | §3.36 | Buat/edit WP yang di-assign, log waktu, meeting |
| Fungsi Pelaksanaan Proyek (Struktural) | Tabel 1, 6 | Accountable inisiasi & penutupan, lihat semua, approve G1/G3 |
| Fungsi Pengawasan Proyek | §5.4 | Lihat semua, kelola CR workflow, baseline, status proyek, laporan, rapat tinjauan |
| Approver CCM | §3.2, §5.4.2 | Transisi keputusan CR |
| Fungsi Perencanaan Proyek | Tabel 2 | Edit Dokumen Rencana, jadwal |
| Fungsi Pengendali Anggaran / Keuangan / Akuntansi | Tabel 2, 5, 6 | Budget & cost (edit), lihat laporan |
| Fungsi Penjaminan Mutu | §5.3.4, §5.4.6 | Kelola Inspeksi Mutu, NCR, audit |
| Fungsi Manajemen Risiko | §5.3.6, §5.4.9 | Kelola Risiko, review register |
| Fungsi K3 & Lingkungan Hidup | §5.3.6 | Kelola Bahaya K3L |
| Fungsi Pengadaan (Perencanaan/Operasional) & Pengelola Gudang | §5.3.7, §5.4.10 | Kelola Item Pengadaan |
| Fungsi Pemasaran | §5.3.5, §5.3.8 | Kelola Stakeholder, komunikasi |
| Fungsi Rekayasa Solusi Teknis | Tabel 2–3 | Edit Deliverable/Task teknis |
| Fungsi Rekrutmen / Pembelajaran & Pengembangan SDM | §5.3.3 | Lihat struktur tim, komentar |
| Pembaca (Informed) | Kolom I | Lihat saja |

**Peran global:** LPMS Administrator (TI), LPMS Business Admin (PMO — kelola template, tipe, custom field tanpa akses server), Pembuat Proyek (Fungsi Pelaksanaan Proyek).

**Group (sinkron dari AD bila D1 = LDAP):** satu group per fungsi organisasi, sehingga penambahan anggota proyek cukup "tambah group Fungsi X dengan role Y".

**RASCI per aktivitas BOP-001 → WP template.** Setiap aktivitas di Tabel 1, 2, 3, 5, dan 6 BOP-001 menjadi WP di template proyek dengan Accountable, Assignee (R), Supporting, Consulted, dan Watchers (I) yang sudah terisi peran/group. Contoh:

| Aktivitas (Tabel) | A | R | S | C | I |
|---|---|---|---|---|---|
| Pembukaan Kode Proyek (T1) | Struktural F. Pelaksanaan Proyek | F. Pelaksanaan Proyek | F. Pengendali Anggaran | F. Perencanaan Proyek | Struktural F. Pelaksanaan, Struktural F. Pengawasan, Project Sponsor |
| Manajemen Biaya Proyek (T2) | Pimpro | Tim Proyek, F. Pengendali Anggaran, F. Keuangan, F. Perencanaan Pengadaan | F. Perencanaan Proyek | F. Pengawasan Proyek | Struktural F. Pelaksanaan, Struktural F. Pengawasan, Project Sponsor |
| Kendali Perubahan Terintegrasi (T5) | Struktural F. Pengawasan Proyek | F. Pengawasan Proyek | Pimpro, Tim Proyek, F. Rekayasa Solusi Teknis | Fungsi terkait sesuai jenis perubahan | Struktural F. Pelaksanaan, Project Sponsor |
| Terminasi Proyek (T6) | Direksi / Project Sponsor | Pimpro, Struktural F. Pelaksanaan, Struktural F. Pengawasan | Tim Proyek, F. Pelaksanaan, F. Pengawasan, F. Kontrak Bisnis | F. Pengendali Anggaran, F. Akuntansi, F. Manajemen Risiko | Seluruh fungsi terkait |

Seluruh baris RASCI (±32 aktivitas) diisi di `lpms3/seed/70_templates.rb` dari file data `lpms3/templates/rasci.yml` agar mudah direvisi bila BOP-001 berubah revisi.

> Catatan teknis: OpenProject mengizinkan satu nilai pada field *Accountable*. Ini selaras dengan BOP-001 §3.25 ("Hanya boleh ada satu orang yang accountable"). Untuk sel A berupa "Direksi / Project Sponsor", isi Project Sponsor dan catat Direksi di Consulted/Informed.

### 5.7 Jadwal, biaya, dan bobot progres

- **Jadwal:** Gantt dari hierarki WBS; relasi *precedes/follows*; kalender kerja Indonesia (hari libur nasional diisi di Admin → Kalender kerja, non-working days). Setelah G2, simpan tanggal Baseline 0 dan gunakan **Baseline comparison** untuk membandingkan rencana vs aktual (cek rentang waktu yang tersedia di edisi Community). Pemantauan mingguan & bulanan (milestone, kurva-S) sesuai §5.4.4.
- **Biaya:** Modul *Budgets* untuk RAB per paket (material, jasa, tenaga kerja); *Cost types* sesuai struktur anggaran Len; *Time tracking* untuk jam orang. Realisasi dari ERP diimpor bulanan (CSV) bila D5 = ekspor-impor.
- **Bobot pekerjaan (§5.4.1):** `Bobot (%) = Harga Pekerjaan per scope / Total Nilai Kontrak × 100`.
  - Field *Harga Pekerjaan* di Deliverable; *Nilai Kontrak* di project attribute.
  - Bobot dihitung oleh skrip laporan (`lpms3/reports/ffr708.py`) karena referensi silang ke atribut proyek tidak didukung oleh calculated field WP. Bila *calculated values* [EE] tersedia, bobot bisa disimpan di WP.
  - **Progres tertimbang proyek** = Σ(Bobot × %selesai Deliverable). Mode progres OpenProject diset ke *status-based* untuk Deliverable (Baru 0%, Dikerjakan 50%, Verifikasi Internal 80%, Validasi Pelanggan 90%, Diterima 100%) — persentase disepakati PMO.
- **Kurva-S:** dihasilkan skrip laporan (rencana kumulatif dari baseline vs aktual) ke XLSX/PNG, dilampirkan pada laporan FFR-708.

### 5.8 Komunikasi & pelaporan

| Kebutuhan BOP-001 | Implementasi LPMS3 | Frekuensi |
|---|---|---|
| FFR-708 Laporan Kemajuan Proyek/Program | **Rilis 1:** LKP dari Pimpro (berbagai format) diproses ETL & approval §13; PDF FFR-708 seragam di-*render* dari data kanonik. **Target:** FFR-708 dihasilkan langsung dari WBS LPMS3 (skrip `ffr708.py`), ETL menjadi alat rekonsiliasi | Bulanan, ≤ tgl 5 bulan berikutnya ke Fungsi Akuntansi |
| Laporan Evaluasi Proyek Terintegrasi (§5.4.1) | Dashboard portofolio (project list dengan kolom atribut & status) + ekspor | Bulanan |
| CFR-022 Risalah Rapat | Meetings: agenda item → outcome → action item (WP) → ekspor PDF ke Documents | Tiap rapat |
| Rapat Tinjauan Proyek (Tabel 4) | Meeting berulang dengan agenda tetap: Kemajuan, Anggaran, Risiko & Peluang, Pengadaan, Umpan balik, Mutu, Lain-lain; peserta = group fungsi | Sesuai kinerja proyek (default bulanan) |
| Project information radiator / dashboard (§5.2.1.6) | Project overview widgets: status, fase/gate, budget, query Risiko Tinggi, CR terbuka, milestone | Real time |
| Matriks Rencana Komunikasi Internal/Eksternal | WP Dokumen Rencana (Komunikasi) + tabel di Wiki | Disahkan di G2 |
| Eskalasi isu ke manajemen | Query "Isu Eskalasi" + notifikasi ke Struktural F. Pengawasan | Real time |

### 5.9 Templates

1. **Project template "LPMS3-Prediktif"** — default untuk proyek kontrak (hardware/sistem/konstruksi).
2. **Project template "LPMS3-Hibrid"** — sama + modul Backlogs/Boards untuk komponen perangkat lunak (sprint), sesuai *tailoring* PMBOK 7/8 dan klausul BOP-001 §2.0 ("Tim Proyek dapat memperinci … sesuai jenis dan karakteristik Proyek").
3. **Project template "LPMS3-Purnajual"** — ringan: Isu, Action Item, SLA milestone, Lessons Learned.

Isi setiap template: modul aktif (WP, Gantt, Boards, Meetings, Wiki, Documents, Budgets, Time & costs, News), anggota group default per role, project attributes, ±40 WP aktivitas BOP-001 dengan RASCI, 9 WP Dokumen Rencana, milestone gate G1–G4, query tersimpan (Risk Register, Change Log, Issue Log, Stakeholder Register, Lessons Learned, Pengadaan, Inspeksi Mutu), meeting template (Kick-Off, Tinjauan Proyek), halaman Wiki (Project Charter BOT-001, Team Charter, Matriks Komunikasi, Lessons Learned, Arsip FFR-710).

### 5.10 Seed sebagai kode (contoh pola)

Konfigurasi admin (status, tipe, workflow, custom field, role) tidak sepenuhnya bisa dibuat lewat API v3, sehingga dipakai **Rails runner** di dalam container dengan skrip idempoten dari repo:

```bash
cd /srv/lpms3/app/upstream
for f in /app/lpms3/seed/*.rb; do
  docker compose -p lpms3 exec -T web bundle exec rails runner "$f" || exit 1
done
```

Contoh pola idempoten (kerangka — **wajib diuji pada VM staging** karena nama model dapat berubah antar versi):

```ruby
# lpms3/seed/10_statuses.rb
STATUSES = [
  { name: "Draft" }, { name: "Diajukan" }, { name: "Analisis Dampak" }, { name: "Sidang CCM" },
  { name: "Disetujui" }, { name: "Ditolak", is_closed: true }, { name: "Ditunda" },
  { name: "Implementasi" }, { name: "Verifikasi" }, { name: "Ditutup", is_closed: true }
]
STATUSES.each_with_index do |attrs, i|
  s = Status.find_or_initialize_by(name: attrs[:name])
  s.is_closed = attrs.fetch(:is_closed, false)
  s.position  = 100 + i
  s.save!
end
puts "statuses ok: #{Status.count}"
```

```ruby
# lpms3/seed/50_workflows.rb (pola)
cr   = Type.find_by!(name: "Change Request")
role = ProjectRole.find_by!(name: "Pimpro")
[%w[Draft Diajukan], %w[Disetujui Implementasi], %w[Implementasi Verifikasi]].each do |from, to|
  Workflow.find_or_create_by!(type_id: cr.id, role_id: role.id,
                              old_status_id: Status.find_by!(name: from).id,
                              new_status_id: Status.find_by!(name: to).id)
end
```

Pembuatan proyek dari template dan pengisian data uji memakai **API v3** (`POST /api/v3/projects/{template_id}/copy`).

**CEK F4:** semua seed dijalankan **dua kali** berturut-turut tanpa error dan tanpa duplikasi; hasil di UI dicocokkan dengan `docs/mapping-BOP001.md`.

---

## 6. MATRIKS KESESUAIAN PMBOK 8th, PMBOK 7th, DAN BOP-001

### 6.1 PMBOK 8 — Focus Areas ↔ BOP-001 ↔ LPMS3

| Focus Area PMBOK 8 | BOP-001 | LPMS3 (OpenProject) |
|---|---|---|
| Initiating | §5.1 Tahap Inisiasi | Fase P1, Gate G1, project attributes, WP Project Charter (BOT-001) |
| Planning | §5.2 Tahap Perencanaan (reviu PMP 9 area, Kick-Off, Top Up) | Fase P2, 9 WP Dokumen Rencana, meeting Kick-Off, Gate G2 / Baseline 0, WP Top Up Anggaran |
| Executing | §5.3 Tahap Eksekusi (8 proses) | Fase P3: Deliverable/Task, Meetings, Risiko/K3L, Pengadaan, Stakeholder, Lessons Learned |
| Monitoring & Controlling | §5.4 Pengawasan & Pengendalian (11 proses) | Berjalan paralel di P3: workflow CR/CCM, baseline comparison, laporan FFR-708, Rapat Tinjauan, query pemantauan |
| Closing | §5.5 Tahap Penutupan | Fase P4, Gate G4, FFR-710, archive project, sub-project Purnajual |

### 6.2 PMBOK 8 — 7 Performance Domains

| Domain PMBOK 8 | BOP-001 | LPMS3 | Celah & tindakan |
|---|---|---|---|
| **Governance** | §3.2 CCM, §3.17 Sponsor, §5.4.2 Integrated Change Control, gate keputusan, Radir untuk terminasi | Role Approver CCM, workflow CR, gate G1–G4 dengan Accountable, project attributes Sponsor/Pimpro | BOP-001 belum mendefinisikan *matriks kewenangan* nilai CR → buat tabel ambang (mis. dampak biaya > x% → Direksi) sebagai lampiran konfigurasi |
| **Scope** | §5.2.1.1, §5.4.3 (scope baseline, WBS, scope creep) | Hierarki Deliverable/Task, Kode WBS, status validasi pelanggan, BA | — |
| **Schedule** | §5.2.1.2, §5.4.4 (milestone, kurva-S) | Gantt, Baseline comparison, Milestone, kurva-S dari skrip | Kurva-S tidak native → skrip laporan |
| **Finance** | §5.2.1.3 (PIS, cash flow), §5.2.3 Top Up, §5.4.5, rumus bobot | Budgets, Cost types, Time & costs, WP Top Up, laporan bobot tertimbang | Realisasi ERP manual (D5) |
| **Stakeholders** | §5.2.1.6 Komunikasi, §5.2.1.9, §5.3.5, §5.3.8, §5.4.8, §5.4.11 | Tipe Stakeholder, Meetings, Project status, News, notifikasi | PMBOK 8 memasukkan komunikasi ke domain ini — LPMS3 menaruh Matriks Komunikasi di bawah area Stakeholders pada laporan |
| **Resources** | §5.2.1.5, §5.3.3, §5.3.7 Pengadaan, §5.4.7, §5.4.10 | Anggota & role, Team planner, Time tracking, Item Pengadaan, Organizational management (17.7: departemen, atribut kerja, jadwal kerja) | Resource management module = [EE]; Community: Team planner + laporan jam |
| **Risk** | §5.2.1.7, §5.3.6, §5.4.9 (+K3L, ROP Series) | Tipe Risiko (ancaman & peluang), Bahaya K3L, query Risk Register, review bulanan | — |

**Mutu** tidak lagi menjadi domain di PMBOK 8 tetapi prinsip (*Embed Quality*): LPMS3 menanamkannya sebagai **status verifikasi wajib** pada Deliverable, tipe Inspeksi Mutu/NCR, dan kriteria gate.

### 6.3 PMBOK 8 — 6 Principles

| Prinsip | Wujud di LPMS3 |
|---|---|
| Adopt a Holistic View | Hierarki program/proyek, dashboard lintas proyek, relasi antar WP (CR ↔ Risiko ↔ Deliverable) |
| Focus on Value | Atribut "Tujuan bisnis/manfaat", kriteria penerimaan Deliverable, review manfaat di Laporan Akhir |
| Embed Quality Into Processes and Deliverables | Status Verifikasi Internal → Validasi Pelanggan, Inspeksi Mutu, NCR, gate berbasis bukti |
| Be an Accountable Leader | Field Accountable tunggal per WP, gate Accountable, jejak audit keputusan CR |
| Integrate Sustainability Within All Project Areas | Atribut keberlanjutan, tipe Bahaya K3L (aspek-dampak lingkungan), kategori Lesson Learned "Keberlanjutan" |
| Build an Empowered Culture | Tim mengelola WP sendiri (Boards, self-assign), Lessons Learned terbuka lintas proyek, diskusi di WP |

### 6.4 PMBOK 7 — 8 Performance Domains

| Domain PMBOK 7 | BOP-001 | LPMS3 |
|---|---|---|
| Stakeholders | §5.2.1.9, §5.3.8, §5.4.11 | Tipe Stakeholder, engagement current/desired |
| Team | §5.1.2, §5.3.3, Team Charter | Role, group per fungsi, Team Charter di Wiki, Team planner |
| Development Approach & Life Cycle | §5.0 (5 tahap), §2.0 (tailoring) | Atribut Pendekatan Delivery, template Prediktif/Hibrid/Purnajual, fase & gate |
| Planning | §5.2 | 9 Dokumen Rencana, Gantt, Budgets |
| Project Work | §5.3.1, §5.3.2, §5.3.7 | Deliverable/Task, Lessons Learned, Pengadaan, Isu |
| Delivery | §5.3.1 (verifikasi & validasi, BA), §5.4.3 | Status penerimaan Deliverable, kriteria penerimaan |
| Measurement | §5.4.1 (bobot, FFR-708), §5.4.4–5.4.5 | Laporan bobot tertimbang, kurva-S, Project status, baseline comparison |
| Uncertainty | §5.2.1.7, §5.3.6, §5.4.9 | Risiko (ancaman & peluang), Bahaya K3L |

### 6.5 PMBOK 7 — 12 Principles (ringkas)

| Prinsip PMBOK 7 | LPMS3 |
|---|---|
| Stewardship | Kepatuhan K3L, anti penyuapan, keamanan informasi (§5.3.1) → checklist gate |
| Team | Group per fungsi, Team Charter |
| Stakeholders | Stakeholder Register & engagement |
| Value | Atribut manfaat, kriteria penerimaan |
| Systems Thinking | Relasi WP, dampak CR lintas area |
| Leadership | Pimpro sebagai Accountable eksekusi |
| Tailoring | Template per pendekatan, BOP-001 §2.0 |
| Quality | Inspeksi/NCR, status verifikasi |
| Complexity | Klasifikasi proyek, dekomposisi WBS |
| Risk | Risk Register bulanan |
| Adaptability & Resiliency | Template Hibrid (sprint), CR terkendali |
| Change | Workflow CCM end-to-end, Change Log |

### 6.6 Celah BOP-001 yang direkomendasikan untuk revisi berikutnya (informasi untuk Fungsi Business Process Management)

1. Matriks kewenangan persetujuan CR (ambang nilai/jadwal) belum eksplisit.
2. *Tailoring* per pendekatan (prediktif/hibrid/adaptif) belum diatur — PMBOK 7/8 mensyaratkan.
3. Prinsip keberlanjutan (PMBOK 8) baru tersirat lewat K3L.
4. Manajemen manfaat (*benefits realization*) pasca proyek belum ada.
5. Rujukan "Prosedur Penanganan Adendum Kontrak" tertulis **SOP-009** di §4.0/§5.3.1 tetapi **SFR-009** di §5.4.1 — perlu diseragamkan; LPMS3 memakai SOP-009.
6. Penomoran tabel ganda: "Tabel 2" dipakai untuk RASCI Reviu PMP dan Peserta Kick-Off Meeting.

---

## 7. PILOT, UAT, DAN GO-LIVE (F6–F7)

### 7.1 Pilot

Pilih 1 proyek prediktif nyata yang baru masuk tahap Inisiasi dan (opsional) 1 proyek hibrid. Jalankan paralel dengan cara kerja lama selama 2 minggu. Data pilot diperlakukan sebagai data produksi (tidak dihapus).

### 7.2 Skenario UAT (minimum)

| ID | Skenario | Peran penguji | Kriteria lulus |
|---|---|---|---|
| U01 | Buat proyek dari template, isi Kode Proyek & atribut wajib | F. Pelaksanaan Proyek | Proyek tercipta lengkap dengan 9 Dokumen Rencana, RASCI terisi |
| U02 | Tetapkan Pimpro & tim inti, cek batas 2 minggu | F. Pelaksanaan Proyek | Reminder/due date WP "Penetapan Tim" = tgl kode + 14 hari |
| U03 | Sahkan Project Charter (BOT-001) → G1 | Struktural F. Pelaksanaan | Gate G1 hanya bisa ditutup bila kriteria terpenuhi |
| U04 | Reviu 9 Dokumen Rencana → Disahkan | Pimpro + fungsi terkait | Hanya role berwenang dapat mengubah status ke Disahkan |
| U05 | Kick-Off Meeting, risalah CFR-022, Baseline 0 | F. Pengawasan Proyek | Risalah PDF terarsip, baseline tersimpan |
| U06 | Ajukan CR end-to-end hingga Ditutup, termasuk Ditunda dan Ditolak | Pimpro, F. Pengawasan, Approver CCM | Transisi terlarang ditolak sistem; Change Log lengkap |
| U07 | CR dengan adendum → action SOP-009 | Pimpro | WP adendum tercipta & terhubung |
| U08 | Update Risk Register bulanan, risiko berubah jadi isu | F. Manajemen Risiko | Riwayat skor terekam; relasi Risiko→Isu |
| U09 | Bahaya K3L (VFR-015) baru karena perubahan metode kerja | F. K3 | WP tercipta dan memicu CR bila perlu |
| U10 | Siklus Item Pengadaan hingga GR/SES | F. Pengadaan | Status & nomor referensi lengkap |
| U11 | Inspeksi mutu gagal → NCR → koreksi → tutup | F. Penjaminan Mutu | Deliverable tidak bisa "Diterima" bila NCR kritikal terbuka (aturan prosedural + query kontrol) |
| U12 | Deliverable diterima pelanggan dengan BA | Pimpro | Lampiran BA wajib (dicek di checklist) |
| U13 | Laporan FFR-708 bulanan dengan bobot & kurva-S | F. Pengawasan Proyek | Angka bobot = perhitungan manual sampel (selisih 0) |
| U14 | Rapat Tinjauan Proyek berulang + action item | F. Pengawasan Proyek | Action item jadi WP dengan due date |
| U15 | Lessons Learned dipublikasikan & ditemukan dari proyek lain | Pimpro | Muncul di query global |
| U16 | Penutupan Selesai 100%: FFR-710, G4, kode purnajual | Pimpro, F. Pengendali Anggaran | Sub-project purnajual tercipta; proyek diarsipkan (read-only) |
| U17 | Penutupan Terminasi (keputusan Radir) | F. Pengawasan Proyek | Atribut Jenis Penutupan = Terminasi; laporan penutupan terlampir |
| U18 | Hak akses: Pembaca tidak bisa edit; fungsi tidak melihat budget bila tidak berhak | Admin | Sesuai matriks permission |
| U19 | Notifikasi email untuk assign, mention, due date | Semua | Email diterima ≤ 5 menit |
| U20 | Backup → restore ke staging, data pilot utuh | TI | RTO ≤ 2 jam |
| U21 | Ulang uji sidebar S01–S12 (§12.10) di produksi dengan data pilot | PMO | Semua lulus |
| U22 | Proyek pilot dibuat lewat **Add New** dari LPMS 2 dan dijalankan lewat menu PHASE (tanpa membuka modul bawaan) | Pimpro pilot | Semua aktivitas BOP-001 dapat dilakukan dari sidebar |
| U23 | Procurement Pipeline 1 item penuh + Cross Payment pada proyek pilot | F. Pengadaan, F. Keuangan | Data konsisten di 4 halaman |
| U24 | LKP bulan berjalan proyek pilot diunggah dalam format asli Pimpro, dibersihkan, disetujui L0→L5 sebelum tgl 5 (L3) | Admin Teknis s.d. Direksi | Data tampil di Dashboard Direksi hanya setelah L4 |
| U25 | Return dari Eselon II ke Admin Teknis, revisi, approval ulang | Eselon II, Admin Teknis | Versi lama SUPERSEDED, jejak lengkap |
| U26 | Backfill 12 bulan LKP historis proyek pilot | F. Pengawasan | Kurva-S & kontinuitas V06 berfungsi |

### 7.3 Pelatihan

| Audiens | Durasi | Materi |
|---|---|---|
| Pimpro & Tim Proyek | 2 × 3 jam | Navigasi, WP, Gantt, Meetings, CR, Risiko, Lessons Learned |
| Fungsi Pengawasan Proyek (PMO) | 2 × 3 jam | Gate, baseline, CCM, laporan FFR-708, rapat tinjauan, project list |
| Fungsi pendukung (Mutu, Risiko, K3L, Pengadaan, Anggaran, Pemasaran) | 1 × 2 jam per fungsi | Tipe WP fungsinya, query, notifikasi |
| Sponsor/Manajemen | 1 jam | Dashboard, status proyek, approval |
| Admin bisnis & TI | 1 hari | Konfigurasi, seed repo, backup/restore, upgrade |

Materi pelatihan dan panduan singkat (Bahasa Indonesia) disimpan di Wiki proyek "LPMS3 Help Center".

### 7.4 Go-live checklist

- [ ] BA Gate Sidebar (G-SB) ditandatangani; image produksi = image teruji (tag & digest sama)
- [ ] UAT ≥ 95% lulus, 0 defect kritikal, BA UAT ditandatangani
- [ ] Password admin bawaan diganti/dinonaktifkan, 2FA admin aktif
- [ ] Backup harian berjalan ≥ 7 hari berturut-turut + 1 restore drill sukses
- [ ] `OP_TAG` & `LPMS3_IMAGE_TAG` dipin (mis. `17.9.6` / `17.9.6-lpms3.1.0`) dan dicatat di CHANGELOG
- [ ] Monitoring & alert aktif (§8.2)
- [ ] Data pilot bersih (tidak ada proyek uji tersisa kecuali yang disengaja)
- [ ] Komunikasi go-live dikirim (URL `http://192.168.125.14:5100`, kontak dukungan)
- [ ] Berita acara go-live oleh System Owner

### 7.5 Hypercare (2 minggu)

Kanal dukungan (email/grup chat), triase harian 15 menit, defect dicatat sebagai WP di proyek internal **"LPMS3 – Operasional"** (dog-fooding).

### 7.6 Evaluasi Enterprise Edition (setelah pilot)

| Kebutuhan | Fitur [EE] | Alternatif Community | Pertimbangan |
|---|---|---|---|
| Inisiasi proyek berbasis formulir | Project initiation request (17.1, Premium) | Template + WP Project Charter | EE bila volume proyek baru tinggi |
| Portofolio & program | Portfolio management (Premium/Corporate) | Hierarki proyek + project list | EE bila Direksi butuh roll-up |
| Kapasitas SDM | Resource management (Premium/Corporate) | Team planner + time report | EE bila konflik SDM lintas proyek sering |
| Skor risiko otomatis | Calculated values operator lanjutan | Skrip laporan | — |
| Branding logo | Custom logo/theme | Nama instans | Kosmetik |
| Sinkron departemen LDAP | LDAP department sync | Group manual | — |

---

## 8. OPERASI & PEMELIHARAAN (F8)

### 8.1 Runbook singkat

| Kegiatan | Frekuensi | Perintah/aksi | PIC |
|---|---|---|---|
| Cek kesehatan | Harian (otomatis) | `ops/healthcheck.sh` → `/health_checks/full` | TI |
| Backup | Harian 01:30 | `ops/backup.sh` via systemd timer | TI |
| Restore drill | Kuartalan | `ops/restore.sh` ke VM staging | TI + PMO |
| Patch OS | Bulanan | `apt full-upgrade`, reboot terjadwal | TI |
| Upgrade minor OpenProject | Bulanan/sesuai rilis keamanan | §8.3 | TI |
| Upgrade mayor | Setelah diuji di staging ≥ 2 minggu | §8.3 + CR | TI + PMO |
| Review konfigurasi & akses | Bulanan | Audit user nonaktif, role, token API | PMO |
| Review kesesuaian BOP-001 | Setiap revisi BOP-001 | Update `rasci.yml`, seed, template via PR | PMO + BPM |

### 8.2 Monitoring

- Ketersediaan: cek HTTP `:5100/health_checks/default` tiap 1 menit dari server monitoring (Zabbix/Uptime Kuma/Prometheus blackbox — sesuai standar TI Len).
- Resource: CPU, RAM, disk `/srv/lpms3` (alert > 80%).
- Container: `docker compose ps` unhealthy → alert; layanan `autoheal` me-restart otomatis.
- Background job: antrean GoodJob (Admin → Background jobs) tidak menumpuk.
- Log: `docker compose -p lpms3 logs --since 1h web worker`.

### 8.3 Prosedur upgrade (aman)

```bash
cd /srv/lpms3/app/upstream
ops/backup.sh                                                    # 1. backup penuh
git fetch origin && git checkout stable/17 && git pull           # 2. update compose upstream (atau stable/18 setelah diuji)
# 3. ubah TAG di .env ke versi target (mis. 17.9.7-slim)
docker compose -p lpms3 pull
docker compose -p lpms3 up -d --build --pull always              # 4. migrasi DB berjalan otomatis lewat seeder
docker compose -p lpms3 logs -f seeder                            # 5. pastikan exit 0
curl -s http://192.168.125.14:5100/health_checks/full             # 6. verifikasi
# 7. jalankan ulang seed LPMS3 (idempoten) + smoke test U06, U13
```

Dengan plugin: langkah 3–4 diganti **ubah `OP_TAG` → rebuild image kustom → jalankan spec plugin & S01–S12 di staging → baru produksi**. Plugin pihak ketiga tidak dijamin kompatibel otomatis dengan versi OpenProject baru.

Rollback: `down` → restore DB dump + opdata dari backup langkah 1 → set `TAG` lama → `up -d`. Mayor version tidak bisa *downgrade* tanpa restore.

### 8.4 Rebuild bersih dari nol (disaster recovery)

1. Server baru → F1.
2. `git clone` repo `lpms3-openproject` (commit dari `config-commit.txt` backup).
3. Pulihkan `.env` dari vault/backup.
4. `docker compose up -d db` → `pg_restore` dump → pulihkan `opdata.tgz`.
5. `docker compose up -d` → health check → login → verifikasi 5 proyek sampel.

---

## 9. RISIKO DEPLOYMENT (RISK REGISTER PROYEK LPMS3)

| ID | Risiko | P (1–5) | D (1–5) | Skor | Respons | Pemilik |
|---|---|---|---|---|---|---|
| R1 | Password/data terkirim tanpa TLS di LAN | 3 | 4 | 12 | Batasi subnet, F9 TLS internal ≤ 1 bulan setelah go-live | TI |
| R2 | Port 5100 dipakai layanan lain / bentrok | 2 | 3 | 6 | Pre-flight F1.1; `PORT` dapat diubah tanpa ubah data (ingat ubah `OPENPROJECT_HOST__NAME`) | TI |
| R3 | Perubahan hostname/IP merusak link & notifikasi | 2 | 3 | 6 | Tetapkan D3 sebelum go-live; prosedur ubah host tercatat | TI |
| R4 | Nama variabel/model berubah di versi baru → seed gagal | 3 | 3 | 9 | Pin versi; uji seed di staging setiap upgrade | TI |
| R5 | Fitur yang diasumsikan Community ternyata [EE] | 3 | 3 | 9 | Verifikasi di F2 (Admin → Enterprise) dan pakai alternatif §7.6 | PMO |
| R6 | Resistensi pengguna / input ganda selama transisi | 4 | 4 | 16 | Sponsor eksekutif, pelatihan, template sederhana, pilot paralel singkat | PMO |
| R7 | Kehilangan data karena backup tidak teruji | 2 | 5 | 10 | Restore drill wajib di F3 dan kuartalan | TI |
| R8 | Disk penuh oleh lampiran/log | 2 | 4 | 8 | Limit log Docker, monitoring disk, LVM dapat diperbesar | TI |
| R9 | Docker mem-bypass UFW, port terbuka lebih luas | 3 | 3 | 9 | Aturan `DOCKER-USER` (Lampiran C) + firewall jaringan | TI |
| R10 | Kebutuhan laporan FFR-708 tidak terpenuhi native | 3 | 3 | 9 | Skrip API laporan diuji di UAT U13 | PMO |
| R11 | Revisi BOP-001 berikutnya mengubah alur | 3 | 2 | 6 | RASCI & seed berbasis data (`rasci.yml`), perubahan via PR | PMO/BPM |
| R12 | Lisensi/keamanan: kerentanan di image lama | 2 | 4 | 8 | Ikuti rilis keamanan OpenProject, upgrade minor bulanan | TI |
| R13 | Plugin LPMS3 rusak saat upgrade OpenProject (API menu/komponen berubah) | 3 | 4 | 12 | Pin versi, spec otomatis, hindari override view, upgrade lewat staging | TI |
| R14 | Skema/akses DB LPMS 2 tidak tersedia atau berubah | 3 | 4 | 12 | View kontrak `v_lpms3_*`, akun read-only, mapping YAML, fallback impor Excel | PMO + DBA LPMS 2 |
| R15 | Kapasitas developer Rails/OpenProject terbatas → G-SB mundur | 3 | 4 | 12 | Prioritaskan S1–S4; Procurement & Health bisa rilis 1.1 bila perlu (dengan persetujuan Sponsor) | PMO |
| R16 | Data pengadaan manual tidak sinkron dengan ERP | 4 | 3 | 12 | Field referensi ERP wajib, rekonsiliasi bulanan, rilis 2 sinkron ERP | F. Pengadaan |
| R17 | Format LKP baru/berubah membuat ekstraksi gagal | 4 | 3 | 12 | Profil varian berbasis konfigurasi, wizard pemetaan, fallback input manual di layar rekonsiliasi | PMO + data engineer |
| R18 | Approval macet di satu level → tenggat tgl 5 terlewat | 3 | 4 | 12 | SLA, pengingat, eskalasi, delegasi | F. Pengawasan |
| R19 | Data LKP rahasia (proyek pertahanan) bocor via akses/BI langsung | 2 | 5 | 10 | Visibilitas berjenjang + RLS PostgreSQL, berkas raw read-only, audit SPI, sampel uji di repo privat | TI + Keamanan Informasi |
| R20 | Data struktur organisasi/posisi tidak mutakhir → approver & hak akses salah | 3 | 4 | 12 | Versi struktur berjangka, sinkron HC/AD, pratinjau dampak, Plt/Plh, review akses bulanan | PMO + HC |
| R21 | Fungsi pendukung enggan memakai LPMS3 | 4 | 3 | 12 | Fungsi Proyek sebagai pusat; mode PROXY + konfirmasi ringan via email/tautan | PMO |

---

## 10. RASCI PROYEK DEPLOYMENT LPMS3

| Aktivitas | A | R | S | C | I |
|---|---|---|---|---|---|
| F0 Keputusan D1–D7 | Sponsor LPMS3 (SVP PMO) | Andre Tigana | TI Infra, PMO | Fungsi BPM, Keamanan Informasi | Fungsi Pelaksanaan Proyek |
| F1–F3 Server, deploy, hardening | Kepala TI Infra | Admin TI | Andre Tigana | Keamanan Informasi | PMO |
| F4–F5 Konfigurasi BOP-001 & template | SVP PMO | Andre Tigana | Admin Bisnis PMO | Fungsi Pengawasan, Mutu, Risiko, K3L, Pengadaan, Anggaran | Project Sponsor |
| F6 Pilot & UAT | SVP PMO | Pimpro pilot | Andre Tigana, Admin TI | Seluruh fungsi pendukung | Direktur Operasi |
| F7 Go-live & pelatihan | SVP PMO | Andre Tigana | Admin TI, PMO | Fungsi Pembelajaran & Pengembangan SDM | Seluruh pengguna |
| F4b Plugin LPMS3 & G-SB | SVP PMO | Tim developer LPMS3 | Andre Tigana, Admin TI, DBA LPMS 2 | Fungsi Pengadaan, Keuangan, Komunikasi Korporat (tema) | Seluruh fungsi pengguna |
| ETL LKP & matriks approval | SVP PMO | Data engineer + developer LPMS3 | Fungsi Pengawasan Proyek, Admin Teknis pilot | Fungsi Akuntansi, SPI, Pimpro (pemilik format) | Eselon I, Direksi |
| F8 Operasi | Kepala TI Infra | Admin TI | Admin Bisnis PMO | — | PMO |

(Nama jabatan disesuaikan dengan struktur organisasi SKEP.HC/DU/I/2026.)

---

## 11. JADWAL INDIKATIF

| Minggu | Kegiatan (staging ║ plugin) | Milestone |
|---|---|---|
| 0 | F0: keputusan, akses server produksi & staging, repo | Keputusan D1–D12 |
| 1 | F1 kedua server + F2S staging ║ S1 kerangka plugin & sidebar, discovery LPMS 2 | **M1: Staging online; sidebar kerangka tampil** |
| 2 | F3 hardening, backup + restore drill ║ S2 | **M2: Platform siap konfigurasi** |
| 3 | F4: status, tipe, CF, role, workflow CR ║ S3 | — |
| 4 | F4: fase/gate, RASCI, query ║ S4 | **M3: Seed lulus 2× idempoten** |
| 5 | F5: template, BOT-001, CFR-022, FFR-708 ║ S5 | **M4: Template siap** |
| 6 | Integrasi seed + plugin ║ S6 | — |
| 7 | Uji performa & dokumentasi ║ S7 | Image kandidat `17.9.6-lpms3.1.0` |
| 8 | Uji S01–S12 | **M5: Gate Sidebar (G-SB) disahkan** |
| 9 | **F2P deploy produksi bersih :5100** + F6 pilot mulai | **M6: Produksi online** |
| 10 | F6 UAT, perbaikan | **M7: BA UAT** |
| 11 | F7 pelatihan & go-live | **M8: Go-live** |
| 12 | Hypercare, serah terima operasi; F9 (TLS/DNS, rilis 2 ERP) direncanakan | **M9: Serah terima ke operasi** |

---

## 12. SPESIFIKASI SIDEBAR & PLUGIN LPMS3 (PRASYARAT DEPLOY PRODUKSI)

> **Aturan:** produksi di `192.168.125.14:5100` **tidak** di-deploy sebelum **Gate Sidebar (G-SB)** lulus di staging (§12.10). Sidebar standar OpenProject tidak bisa disusun seperti ini lewat menu Administrasi saja, sehingga dibuat **plugin `openproject-lpms3`** (Rails engine) yang dibangun ke dalam **image Docker kustom**.

### 12.1 Keputusan yang sudah ditetapkan (9 Nov 2026)

| # | Keputusan | Pilihan | Konsekuensi desain |
|---|---|---|---|
| D8 | Sumber data "Add New" | **Koneksi DB LPMS 2 langsung (read-only)** | Koneksi DB kedua di plugin, akun read-only, sebaiknya lewat *view* khusus (§12.7) |
| D9 | Data Procurement Pipeline | **Gabungan**: rilis 1 input manual, rilis 2 sinkron ERP | Model data sudah memuat field referensi ERP & penanda sumber sejak rilis 1 (§12.6) |
| D10 | Butir kosong di [Perencanaan] & [Eksekusi] | **Diusulkan Claude** dari BOP-001 | Ditandai *(usulan)* di §12.2; bisa diubah sebelum G-SB |
| D11 | Theme/Font/Logo/Image | **Plugin LPMS3 sendiri** (bukan lisensi Enterprise) | Halaman Settings milik plugin; CSS variables + aset unggahan. Kode pembatas fitur Enterprise OpenProject **tidak** diubah |

### 12.2 Struktur sidebar final

Kurung siku `[ ]` = judul grup (bisa diklik → halaman ringkasan grup).

```
OVERVIEW
  ├─ Dashboard
  └─ Project Health

PHASE  — konteks: proyek yang dipilih di bagian PROJECT  (judul grup menampilkan "Kode – Nama Proyek")
  ├─ [Inisiasi]                       → ringkasan fase + checklist Gate G1
  │    ├─ Team Assignment
  │    └─ Preliminary Project Management Aspect (9 aspek)
  ├─ [Perencanaan]                    → ringkasan fase + checklist Gate G2
  │    ├─ Reviu PMP & Kick-Off Meeting              (usulan, mengisi butir kosong)
  │    ├─ Baseline & Rebaseline
  │    └─ WBS Generation
  ├─ [Eksekusi]                       → ringkasan fase
  │    ├─ Work Order
  │    └─ Change Request (BFR-001)                  (usulan, mengisi butir kosong)
  ├─ [Monitoring]                     → ringkasan pengawasan & pengendalian
  │    ├─ Laporan Kemajuan (LKP / FFR-708)          (usulan v1.2, lihat §13.2)
  │    ├─ Procurement Pipeline
  │    │    ├─ Pra Procurement up to Purchase Requisition
  │    │    ├─ Purchase Requisition up to Contract
  │    │    ├─ Contract Milestone up to Vendor Paid Status
  │    │    └─ Cross Payment Project and Vendors Management
  │    ├─ Issue Status
  │    ├─ Risk Status
  │    ├─ K3LH Status
  │    └─ Quality Status
  └─ [Closing]                        → "as BOP Planned" (§5.5 BOP-001) + checklist Gate G4

PROJECT
  ├─ <Kode – Proyek 1>
  ├─ <Kode – Proyek 2>
  ├─ <Kode – Proyek 3>
  ├─ …  (maks. 10 terakhir dibuka; "Lihat semua proyek" bila lebih)
  └─ + Add New (Tarik data dari LPMS 2)

SETTINGS
  ├─ User & Access (Fungsi Manajemen)
  └─ Settings (Application: Theme, Font, Logo, Image)
```

**Perilaku:**

1. Sidebar **sama** di halaman global maupun halaman proyek. Grup PHASE mengikuti proyek aktif. Bila belum ada proyek dipilih, PHASE memakai proyek terakhir yang dibuka (disimpan di sesi) atau menampilkan "Pilih proyek di bagian PROJECT".
2. Menu tampil sesuai hak akses: item tanpa izin disembunyikan. Contoh: "Add New" hanya untuk peran Pembuat Proyek/PMO; SETTINGS hanya untuk LPMS Business Admin/Administrator.
3. Badge di kanan item: jumlah item terbuka/terlambat (mis. Risk Status ⚠3, Issue Status 5) dan titik warna RAG di samping nama proyek.
4. **Modul bawaan OpenProject** (Work packages, Gantt, Boards, Meetings, Wiki, Documents, Budgets, Time & costs) tidak tampil di sidebar pengguna biasa — dibuka dari tombol di halaman LPMS3 (mis. WBS Generation → "Buka Gantt"). Untuk PMO/Admin tersedia grup lipat tambahan "Modul Lanjutan" (konfigurasi `LPMS3_NATIVE_MENU=pmo_only|all|none`, default `pmo_only`) agar administrasi tetap mudah.
5. Urutan [Perencanaan] mengikuti permintaan (Baseline sebelum WBS Generation). Secara proses BOP-001, WBS disusun lebih dulu lalu di-baseline; halaman Baseline menolak pembuatan baseline bila WBS belum ada.

### 12.3 Spesifikasi tiap item menu

#### OVERVIEW

| Item | Cakupan | Isi halaman | Sumber data |
|---|---|---|---|
| **Dashboard** | Semua proyek tempat user menjadi anggota (PMO/Sponsor: semua proyek) | Kartu KPI (jumlah proyek per fase, gate jatuh tempo 30 hari, CR menunggu keputusan *saya*, WP saya terlambat), daftar "Perlu tindakan saya", kalender milestone, pengumuman (News) | WP, project attributes, fase/gate, snapshot kesehatan |
| **Project Health** | Portofolio sesuai hak akses | Tabel per proyek: fase & gate, progres tertimbang (bobot §5.7), SPI, CPI, risiko Tinggi/Ekstrem terbuka, isu terbuka, CR tertunda, NCR kritikal, temuan K3LH, keterlambatan pengadaan, RAG keseluruhan; tren 6 bulan; ekspor XLSX | Tabel `lpms3_health_snapshots` (job harian 02:00) + hitung langsung |

Aturan RAG default (ambang dapat diubah di Settings):

| Dimensi | Hijau | Kuning | Merah |
|---|---|---|---|
| Jadwal (SPI = progres aktual tertimbang / progres rencana baseline) | ≥ 0,95 | 0,90–0,95 | < 0,90 |
| Biaya (CPI = nilai hasil / biaya aktual) | ≥ 0,95 | 0,90–0,95 | < 0,90 |
| Risiko | Tidak ada Tinggi/Ekstrem | ≥ 1 Tinggi | ≥ 1 Ekstrem atau lewat tanggal review |
| K3LH | Tidak ada temuan terbuka | Temuan sedang terbuka | Insiden/temuan tinggi tanpa pengendalian |
| Mutu | Tidak ada NCR terbuka | NCR minor terbuka | NCR kritikal terbuka |
| Pengadaan | Semua item on-time | Item terlambat ≤ 14 hari | Item jalur kritis terlambat > 14 hari |
| Keseluruhan | Semua hijau | Ada kuning | Ada merah |

#### PHASE — [Inisiasi] (BOP-001 §5.1)

| Item | Acuan | Detail |
|---|---|---|
| **[Inisiasi]** (judul grup) | §5.1.1, §5.1.3 | Ringkasan & Gate G1: status Kode Proyek (FOP-700), Pimpro, tim inti, **Project Charter (BOT-001)**, tombol "Ajukan Gate G1" (aktif bila kriteria terpenuhi). Kode Proyek & Project Charter dikelola di halaman ini agar BOP-001 terpenuhi tanpa menambah item menu. |
| **Team Assignment** | §5.1.2, HOP-609, §5.3.3 | Penetapan Pimpro & tim inti per peran LPMS3 (§5.6), jabatan proyek, alokasi %, periode; hitung mundur **≤ 2 minggu** sejak Kode Proyek dibuka (kuning H-3, merah lewat batas); unggah SK/penugasan; RASCI aktivitas terkait. Menulis ke *memberships* OpenProject + atribut Pimpro. |
| **Preliminary Project Management Aspect (9 aspek)** | §5.1.1 (PMP diserahterimakan dari Fungsi Perencanaan Proyek) | Kartu 9 aspek: Ruang Lingkup, Jadwal, Biaya, Mutu, Sumber Daya, Komunikasi, Risiko & K3L, Pengadaan, Stakeholder. Setiap kartu = WP "Dokumen Rencana" versi *preliminary*: status, PIC, lampiran, catatan kekurangan. Menjadi masukan Reviu PMP di [Perencanaan]. |

#### PHASE — [Perencanaan] (BOP-001 §5.2)

| Item | Acuan | Detail |
|---|---|---|
| **[Perencanaan]** | §5.2 | Ringkasan & Gate G2: progres reviu 9 aspek, status Kick-Off, Baseline 0, Top Up Anggaran berjalan |
| **Reviu PMP & Kick-Off Meeting** *(usulan)* | §5.2.1, §5.2.2 | Matriks reviu 9 aspek × fungsi (Tabel 2 RASCI Reviu PMP), status Draft → Reviu → Revisi → Disahkan; daftar keluaran wajib per aspek (mis. WBS Plan, Requirements, Scope Statement, Assumption Log, CDRL); penjadwalan Kick-Off dengan peserta otomatis dari tabel peserta BOP-001; risalah **CFR-022**; tombol "Tetapkan Baseline 0" setelah risalah disahkan |
| **Baseline & Rebaseline** | §3.1, §3.4, §5.2.3, §5.4.2 | Tab **Jadwal** (snapshot tanggal semua WP; versi Baseline 0, 1, 2…), tab **Biaya** (RAB/Budget per versi + **Top Up Anggaran BOG-003**), tab **Ruang Lingkup** (Deliverable tersahkan). **Rebaseline wajib terhubung ke CR berstatus Disetujui** — sistem menolak rebaseline tanpa CR. Perbandingan antar versi (selisih tanggal, durasi, biaya). |
| **WBS Generation** | §3.39, §5.2.1.1 | Pembuat WBS: (a) template per jenis proyek, (b) impor Excel (Kode WBS, Nama, Induk, Tipe, Durasi, Harga Pekerjaan), (c) salin dari proyek sejenis/LPMS 2. Validasi: kode unik, hierarki valid, Σ Harga Pekerjaan = Nilai Kontrak (toleransi diatur) agar **bobot §5.4.1** konsisten. Hasil: WP Deliverable/Task berhierarki → tombol "Buka Gantt". |

#### PHASE — [Eksekusi] (BOP-001 §5.3)

| Item | Acuan | Detail |
|---|---|---|
| **[Eksekusi]** | §5.3 | Ringkasan: Deliverable per status (Verifikasi Internal → Validasi Pelanggan → Diterima), BA tertunda, rapat berikutnya, **Rapat (CFR-022) & Lessons Learned** (§5.3.2, §5.3.5) diakses dari sini |
| **Work Order** | §5.3.1 | Tipe WP **Work Order** (perintah kerja ke fungsi pelaksana): No. WO, fungsi penerima, WBS terkait, lingkup, target tanggal, estimasi jam/biaya. Status: Draft → Diterbitkan → Diterima Fungsi → Dikerjakan → Selesai → Diverifikasi / Dibatalkan. Daftar + Kanban per fungsi; realisasi jam & biaya. |
| **Change Request (BFR-001)** *(usulan)* | §5.3.1, §5.4.2 | Formulir CR & workflow CCM (§5.5): CR proyek, CR menunggu tindakan saya, Change Log, tautan ke Rebaseline |

#### PHASE — [Monitoring] (BOP-001 §5.4)

**Procurement Pipeline** — tampilan *pipeline* (kolom = tahap, kartu = item pengadaan, warna = keterlambatan terhadap tanggal dibutuhkan). Satu objek **Item Pengadaan** bergerak melintasi tiga halaman tahap:

| Sub-menu | Tahap (status) | Field utama | Rilis 1 (manual) | Rilis 2 (ERP) |
|---|---|---|---|---|
| **Pra Procurement up to Purchase Requisition** | Kebutuhan teridentifikasi (WBS/BOM) → Spesifikasi teknis → Make-or-Buy → Owner Estimate → **PR dibuat** | Kode WBS, deskripsi, qty, satuan, tanggal dibutuhkan, make-or-buy, OE, No. PR | Tim Proyek / F. Perencanaan Pengadaan | No. & status PR dari ERP |
| **Purchase Requisition up to Contract** | PR disetujui → RFQ/Tender → Evaluasi teknis & harga → Negosiasi → Penetapan pemenang → **PO/Kontrak** | Metode pengadaan (POP Series), calon rekanan, penawaran, rekanan terpilih, No. PO/Kontrak, nilai, tanggal | F. Operasional Pengadaan | PO/Kontrak dari ERP |
| **Contract Milestone up to Vendor Paid Status** | Milestone kontrak vendor (uang muka, pengiriman, FAT/SAT, serah terima) → **GR/SES** → Invoice → Verifikasi → **Dibayar** | % termin, tanggal rencana/aktual, No. GR/SES, No. invoice, nilai tagihan, tanggal & status bayar | F. Pengadaan & Keuangan | GR/SES, invoice, pembayaran dari ERP |
| **Cross Payment Project and Vendors Management** | Lintas proyek & vendor | (1) **Arus kas proyek**: termin Pelanggan (rencana vs diterima) vs kewajiban bayar vendor (jatuh tempo vs dibayar) per bulan, gap kas. (2) **Manajemen vendor**: total kontrak, outstanding, ketepatan waktu, skor kinerja (§5.3.7), proyek terkait | Termin pelanggan oleh F. Keuangan; vendor master oleh Pengadaan | Sinkron ERP |

Aturan sumber data (D9): setiap field ERP punya pasangan `sumber` (MANUAL/ERP) dan `terakhir_sinkron`. Saat rilis 2 aktif, field bersumber ERP menjadi *read-only*; selisih data manual vs ERP ditampilkan di laporan rekonsiliasi sebelum ditimpa.

**Status per area** — default menampilkan **proyek yang dipilih**; tab kedua **"Semua proyek saya"** menampilkan agregat seluruh proyek tempat user menjadi anggota (tafsiran "Each Project for this user"; PMO/Sponsor melihat semua sesuai hak).

| Item | Isi | Sumber |
|---|---|---|
| **Issue Status** | Jumlah per status & umur isu, isu eskalasi, daftar berfilter (sumber, PIC, jatuh tempo) | WP Isu + Action Item |
| **Risk Status** | Peta panas 5×5, top-10 risiko, ancaman vs peluang, risiko lewat tanggal review (siklus bulanan §5.3.6), ekspor **RFR-002** | WP Risiko |
| **K3LH Status** | Bahaya/aspek per tingkat risiko awal vs sisa, pengendalian belum diterapkan, inspeksi K3LH, ekspor **VFR-015** | WP Bahaya K3L (+ Insiden K3L opsional) |
| **Quality Status** | Inspeksi lulus/gagal, NCR per severity & umur, status T&C, audit mutu (QOP-803), quality metrics vs target | WP Inspeksi Mutu, NCR |

Setiap halaman status punya tombol "Buat CR" yang membuka BFR-001 terisi (asal permintaan = fungsi pemantau), sesuai pola BOP-001 §5.4.3–5.4.11.

#### PHASE — [Closing] "as BOP Planned" (BOP-001 §5.5)

Halaman berlangkah (wizard) mengikuti BOP-001 apa adanya, RASCI sesuai Tabel 6:

1. Pilih jalur: **Proyek Selesai 100%** (§5.5.1) atau **Terminasi Proyek** (§5.5.2: pengunduran diri disetujui / sanksi pelanggan / force majeure; keputusan Radir dilampirkan).
2. Checklist penutupan Kode Proyek (**FOP-705**).
3. **Pembukaan Kode Purnajual** (§5.5.3, FOP-700) bila "Purnajual dipersyaratkan" = Ya → sub-proyek dari template LPMS3-Purnajual.
4. **Pendokumentasian Arsip** (§5.5.4): checklist **FFR-710**, retensi COP-002.
5. Laporan Akhir Proyek + Lessons Learned dipublikasikan.
6. Gate G4 → proyek diarsipkan (read-only).

#### PROJECT

| Item | Perilaku |
|---|---|
| **Daftar proyek** | Proyek tempat user menjadi anggota, urut terakhir dibuka (maks. 10), format "Kode – Nama", titik RAG, fase saat ini, kotak cari cepat. Klik → proyek aktif berganti, grup PHASE ikut berganti. |
| **Add New (Tarik data dari LPMS 2)** | Wizard impor dari DB LPMS 2 (§12.7), membuat proyek dari template LPMS3 lalu mengisi data. Opsi "Proyek baru tanpa LPMS 2" tetap tersedia untuk PMO. |

#### SETTINGS

| Item | Isi | Catatan |
|---|---|---|
| **User & Access (Fungsi Manajemen)** | (1) **Versi Struktur Organisasi** (SKEP) & pohon unit beserta alias; (2) katalog **Fungsi Generik** BOP-001 dan **pemetaan Fungsi → Unit** (Nota 021), berversi; (3) posisi & penempatan user (Definitif/Plt/Plh/Delegasi); (4) **matriks kapabilitas** Fungsi × Jenjang × Lingkup dan pengecualian berjangka; (5) mode DIRECT/PROXY per fungsi; (6) pratinjau dampak perubahan struktur; (7) log audit — rincian di **§14** | Dikelola Fungsi Manajemen Proyek. Mesin kapabilitas menurunkan Users/Groups/Memberships OpenProject dan menyinkronkan `lpms3_dw.ref.*`. Bila *Organizational management* (17.7) tersedia di Community, unit disinkronkan ke Departemen. |
| **Settings (Application)** | **Theme**: warna primer/sekunder/aksen, header, sidebar, pratinjau langsung. **Font**: font sistem atau unggah WOFF2 (maks. 4 file), ukuran dasar. **Logo**: logo header, logo login, favicon. **Image**: latar login, banner Dashboard. Juga: ambang RAG, mode Modul Lanjutan, teks footer kerahasiaan Len | Disimpan di tabel pengaturan plugin; diterapkan lewat *view hook* (CSS variables + `@font-face`). Unggahan divalidasi (tipe, ≤ 2 MB, SVG disanitasi). |

### 12.4 Arsitektur plugin `openproject-lpms3`

```
plugin/openproject-lpms3/                # di dalam repo lpms3-openproject
├── openproject-lpms3.gemspec
├── lib/
│   ├── openproject-lpms3.rb
│   └── open_project/lpms3/
│       ├── engine.rb                    # registrasi plugin, project_module :lpms3, permission
│       ├── sidebar.rb                   # SATU definisi struktur menu → dipasang ke :global_menu & :project_menu
│       └── hooks.rb                     # view hook: CSS variables, font, logo
├── app/
│   ├── controllers/lpms3/               # dashboard, health, phases, team_assignment, pm_aspects, baselines,
│   │                                    # wbs, work_orders, procurement, status, closing, projects_import,
│   │                                    # functions_access, app_settings
│   ├── components/lpms3/                # ViewComponent + Primer (gaya UI OpenProject)
│   ├── models/lpms3/                    # Vendor, CustomerPaymentTerm, HealthSnapshot, Baseline(+Item),
│   │                                    # ImportLog, AppSetting, Function, Lpms2::Base (koneksi DB kedua)
│   ├── services/lpms3/                  # HealthCalculator, BaselineService, WbsImporter, Lpms2Importer, ErpSync (rilis 2)
│   └── workers/lpms3/                   # HealthSnapshotJob (harian), ErpSyncJob (rilis 2)
├── config/{routes.rb, locales/id.yml, locales/en.yml}
├── db/migrate/                          # tabel lpms3_*
└── spec/                                # RSpec + feature test sidebar (S01–S12)
```

Prinsip:

- **Satu sumber struktur menu** (`sidebar.rb`) dipasang ke `:global_menu` dan `:project_menu` sehingga tampilan identik. Item PHASE di konteks global mengarah ke `/lpms3/go/<item>` yang mengalihkan ke proyek terakhir atau pemilih proyek.
- **Daftar proyek dinamis** memakai opsi `children:` (Proc) pada item menu — fitur MenuManager warisan Redmine. Bila tidak dirender oleh versi terpasang, fallback: override terbatas satu partial menu utama, dicatat sebagai titik rawan upgrade.
- **Item bawaan** dipindah ke grup "Modul Lanjutan" (PMO/Admin) atau dihapus via `Redmine::MenuManager.map(:project_menu) { |m| m.delete :<item> }` bila `LPMS3_NATIVE_MENU=none`.
- **Data sebisa mungkin tetap Work Package** (Work Order, Item Pengadaan, Milestone Vendor, Risiko, dst.) agar Gantt, notifikasi, API, filter, dan jejak audit bawaan tetap berfungsi. Tabel `lpms3_*` hanya untuk yang bukan WP.
- **Hak akses** sebagai permission plugin: `view_lpms3`, `manage_team_assignment`, `manage_baselines` (F. Pengawasan), `manage_work_orders`, `manage_procurement`, `view_cross_payment` (Keuangan/PMO/Sponsor), `manage_closing`, `import_lpms2` (global), `manage_lpms3_functions` (global), `manage_lpms3_app_settings` (global).
- Kerangka mengikuti contoh plugin resmi (`opf/openproject-proto_plugin`) dan **diverifikasi terhadap kode sumber OpenProject versi yang dipin** — nama helper menu dan sintaks permission dapat berubah antar versi.

Pola registrasi (kerangka, diuji di staging):

```ruby
# plugin/openproject-lpms3/lib/open_project/lpms3/engine.rb
module OpenProject::Lpms3
  class Engine < ::Rails::Engine
    engine_name :openproject_lpms3
    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-lpms3", author_url: "https://www.len.co.id", bundled: false do
      project_module :lpms3 do
        permission :view_lpms3,         { "lpms3/phases": %i[show] },                         permissible_on: :project
        permission :manage_work_orders, { "lpms3/work_orders": %i[new create edit update] }, permissible_on: :project
        permission :manage_procurement, { "lpms3/procurement": %i[edit update] },            permissible_on: :project
        # … permission lain
      end
      OpenProject::Lpms3::Sidebar.register!(self)   # pasang struktur §12.2 ke :global_menu & :project_menu
    end
  end
end
```

### 12.5 Image Docker kustom (deploy plugin dari GitHub)

Image resmi tidak memuat plugin, jadi dibangun image turunan (pola resmi: `Gemfile.plugins` + `bundle install` di Dockerfile turunan). Di repo `lpms3-openproject`:

```dockerfile
# docker/Dockerfile
ARG OP_TAG=17.9.6
FROM openproject/openproject:${OP_TAG}
COPY plugin/openproject-lpms3 /app/custom-plugins/openproject-lpms3
COPY docker/Gemfile.plugins /app/Gemfile.plugins
RUN bundle config unset deployment && bundle install && bundle config set deployment 'true'
# Bila plugin menambah aset frontend, jalankan skrip postinstall bawaan image (precompile aset):
RUN ./docker/prod/setup/postinstall.sh
```

```ruby
# docker/Gemfile.plugins
group :opf_plugins do
  gem "openproject-lpms3", path: "/app/custom-plugins/openproject-lpms3"
  # Driver DB LPMS 2 bila bukan PostgreSQL (pg sudah tersedia):
  # gem "mysql2"                                            # MySQL/MariaDB — tambah paket libmysqlclient di Dockerfile
  # gem "activerecord-sqlserver-adapter"; gem "tiny_tds"     # SQL Server — tambah freetds di Dockerfile
end
```

Gunakan image **non-slim** sebagai basis bila `postinstall.sh` membutuhkan toolchain frontend; verifikasi di S1.

Tambahan di `compose/docker-compose.override.yml` (semua layanan aplikasi memakai image yang sama):

```yaml
x-lpms3-image: &lpms3img
  image: lpms3/openproject:${LPMS3_IMAGE_TAG}
services:
  web:    { <<: *lpms3img, build: { context: /srv/lpms3/app, dockerfile: docker/Dockerfile, args: { OP_TAG: "${OP_TAG}" } } }
  worker: { <<: *lpms3img }
  cron:   { <<: *lpms3img }
  seeder: { <<: *lpms3img }
```

Variabel `.env` baru: `OP_TAG=17.9.6`, `LPMS3_IMAGE_TAG=17.9.6-lpms3.1.0`, `LPMS3_NATIVE_MENU=pmo_only`, `LPMS2_DATABASE_URL=<adapter>://lpms3_ro:<pw>@<host-lpms2>:<port>/<db>`.

```bash
cd /srv/lpms3/app/upstream
docker compose -p lpms3 build web       # → lpms3/openproject:${LPMS3_IMAGE_TAG}
docker compose -p lpms3 up -d           # seeder menjalankan migrasi, termasuk tabel lpms3_*
docker compose -p lpms3 exec web bundle exec rails runner 'puts Redmine::Plugin.all.map(&:id)'   # CEK: openproject-lpms3 terdaftar
```

Penamaan image: `<versi OpenProject>-lpms3.<versi plugin>`; disimpan di registry internal (atau `docker save`) agar rollback cepat. Setiap upgrade OpenProject = **rebuild image + jalankan spec plugin di staging** sebelum produksi. Hindari menimpa *selector* CSS internal; gunakan CSS variables & komponen Primer agar tahan upgrade.

### 12.6 Model data tambahan

| Objek | Jenis | Field/relasi pokok |
|---|---|---|
| Work Order | Tipe WP baru | No. WO, fungsi penerima, WBS terkait, estimasi & realisasi jam/biaya |
| Item Pengadaan | Tipe WP (diperluas dari §5.3) | Tahap pipeline (§12.3), No. PR/PO/Kontrak/GR/SES, rekanan, OE, nilai kontrak vendor, tanggal dibutuhkan, `sumber_*`, `terakhir_sinkron` |
| Milestone Vendor | Tipe WP baru (anak Item Pengadaan) | % termin, nilai, tanggal rencana/aktual, No. invoice, status & tanggal bayar |
| Vendor | Tabel `lpms3_vendors` | Nama, NPWP, kategori, kontak, kode vendor ERP, skor kinerja |
| Termin Pelanggan | Tabel `lpms3_customer_payment_terms` | Proyek, termin ke-, %/nilai, syarat (milestone/BA), tanggal rencana/tagih/terima |
| Baseline | Tabel `lpms3_baselines` + `lpms3_baseline_items` | Proyek, versi (0,1,2…), CR pemicu, tanggal, snapshot tanggal/durasi/biaya per WP |
| Snapshot kesehatan | Tabel `lpms3_health_snapshots` | Proyek, tanggal, SPI, CPI, progres, hitungan per dimensi, RAG |
| Log impor | Tabel `lpms3_import_logs` | ID proyek LPMS 2, pengguna, waktu, pemetaan, hasil/kesalahan |
| Pengaturan aplikasi | Tabel `lpms3_app_settings` + lampiran | Tema, font, logo, gambar, ambang RAG |
| Fungsi | Tabel `lpms3_functions` | Nama fungsi, group OpenProject, group AD, kepala fungsi (eselon) |

### 12.7 Add New — impor dari DB LPMS 2 (D8)

**Prasyarat (discovery, sprint S1):**

1. Identifikasi jenis DB LPMS 2 (PostgreSQL/MySQL/SQL Server/Oracle), host, port, versi.
2. Minta DBA LPMS 2 membuat **akun read-only `lpms3_ro`** dan, sangat disarankan, **view khusus** sebagai kontrak antarmuka agar perubahan skema LPMS 2 tidak merusak impor:
   - `v_lpms3_project` (kode proyek, nama, pelanggan, no./tanggal/nilai kontrak, klasifikasi, sponsor, pimpro, tanggal mulai/selesai, status)
   - `v_lpms3_wbs` (kode, nama, induk, durasi, harga pekerjaan)
   - `v_lpms3_milestone`, `v_lpms3_team`, `v_lpms3_risk`, `v_lpms3_procurement` (opsional)
3. Buka firewall dari `192.168.125.14` ke host DB LPMS 2 pada port DB saja.
4. Workshop pemetaan field LPMS 2 → atribut/tipe LPMS3; hasil di `lpms3/templates/lpms2_mapping.yml` (dapat diubah tanpa ubah kode).

**Alur wizard:**

1. Cari proyek LPMS 2 (Kode Proyek / no. kontrak / nama) → tampil yang **belum pernah diimpor**.
2. Pratinjau data & pemetaan; field wajib yang kosong ditandai.
3. Pilih template (Prediktif/Hibrid/Purnajual) dan komponen yang diimpor (atribut wajib; WBS, milestone, tim, risiko opsional).
4. Konfirmasi → proyek dibuat dari template → data diisi → `lpms2_project_id` disimpan sebagai atribut unik (mencegah impor ganda) → log impor.
5. Proyek muncul di bagian PROJECT; fase ditentukan dari status LPMS 2 (mis. sedang berjalan → Eksekusi; Gate G1/G2 ditandai "dimigrasikan" dengan catatan).

**Keamanan:** kredensial di `.env` (tidak di repo), koneksi dibuka hanya saat impor, hak `import_lpms2` hanya untuk PMO/Pembuat Proyek, seluruh impor tercatat.

### 12.8 Theme/Font/Logo/Image (D11)

- Plugin menyuntikkan CSS variables ke `<head>` lewat view hook; nilai dari halaman Settings (`--lpms3-primary`, `--lpms3-header-bg`, `--lpms3-sidebar-bg`, `--lpms3-font-family`, …) dipetakan ke variabel tema OpenProject yang setara (diverifikasi pada versi terpasang).
- Font unggahan disajikan dengan `@font-face`; default font sistem.
- Logo, favicon, latar login, banner Dashboard disimpan sebagai lampiran dan dirender komponen plugin.
- Ini kustomisasi milik Len di atas kode GPLv3; **tidak** mengubah atau melewati pemeriksaan token Enterprise OpenProject. Halaman Design bawaan (EE) tidak dipakai.
- Nilai awal tema ditetapkan bersama Fungsi Komunikasi Korporat sesuai panduan identitas visual Len.

### 12.9 Rencana pengembangan plugin

| Sprint (1 minggu) | Lingkup |
|---|---|
| S1 | Kerangka plugin, image kustom, `sidebar.rb` (struktur penuh, halaman placeholder), **tabel Fungsi/Struktur/Posisi & mesin kapabilitas dasar (§14)**, i18n, discovery LPMS 2 — DoD: S01–S05, F01–F02 lulus |
| S2 | Settings (Theme/Font/Logo/Image), User & Access lengkap (versi struktur, pemetaan Fungsi → Unit, Plt/Plh, pratinjau dampak, sinkron ke OpenProject & `lpms3_dw`), Tier pengguna & halaman awal, Team Assignment, Preliminary 9 Aspek, ringkasan [Inisiasi] + G1 |
| S3 | Reviu PMP & Kick-Off, WBS Generation (template/Excel/salin), Baseline & Rebaseline (+ Top Up) |
| S4 | Work Order, Change Request, ringkasan [Eksekusi]; Issue/Risk/K3LH/Quality Status (+ tab "Semua proyek saya") |
| S5 | Procurement Pipeline (4 halaman), vendor master, termin pelanggan, Cross Payment |
| S6 | Dashboard, Project Health + job snapshot, Closing wizard, Add New (impor LPMS 2) |
| S7 | Stabilisasi, uji performa (≥ 50 proyek, ≥ 20.000 WP data uji), dokumentasi, **Gate G-SB**, rilis image `17.9.6-lpms3.1.0` |

Tim minimum: 2 developer Ruby on Rails (pengalaman OpenProject/Redmine diutamakan), 1 analis bisnis PMO, 1 penguji. Rilis 2 (sinkron ERP Procurement) dijadwalkan terpisah setelah go-live.

### 12.10 Gate Sidebar (G-SB) — kriteria lulus sebelum deploy produksi :5100

| ID | Uji | Kriteria |
|---|---|---|
| S01 | Struktur menu | Urutan, label, pengelompokan **persis** §12.2 (dibandingkan tangkapan layar acuan yang disahkan) |
| S02 | Konsistensi | Sidebar identik di Dashboard, halaman proyek, halaman Settings |
| S03 | Konteks proyek | Klik proyek di PROJECT → judul grup & seluruh tautan PHASE berganti ke proyek tersebut |
| S04 | Tanpa proyek | PHASE menampilkan proyek terakhir / pesan pilih proyek, tidak error |
| S05 | Hak akses | 6 persona (Pimpro, Tim Proyek, F. Pengawasan, F. Pengadaan, Sponsor, Pembaca) hanya melihat item yang diizinkan; URL langsung tanpa izin → 403 |
| S06 | Badge & RAG | Angka badge = hasil query pembanding; warna RAG sesuai aturan §12.3 |
| S07 | Add New | Impor 3 proyek uji dari salinan DB LPMS 2; impor ganda ditolak; log tercatat |
| S08 | Procurement | Satu item bergerak dari Kebutuhan hingga Dibayar melalui 3 halaman tahap; muncul di Cross Payment |
| S09 | Settings | Ubah warna, font, logo, latar login → berlaku tanpa restart; reset ke default berfungsi |
| S10 | Responsif & performa | Sidebar dapat dilipat; berfungsi di 1366×768 dan tablet; render sidebar < 300 ms dengan 50 proyek |
| S11 | Reproducible | Image dibangun ulang dari repo bersih menghasilkan hasil sama; spec plugin hijau |
| S12 | Bahasa | Semua label tersedia dalam `id` dan `en` |

G-SB disahkan SVP PMO (Accountable) dengan berita acara. Setelah itu dilakukan **deploy produksi bersih (F2P)** di `192.168.125.14:5100` dengan image yang sama persis (tag & digest) dengan yang diuji.

---

## 13. LKP (FFR-708): ETL MULTI-FORMAT, TABEL PENYIMPANAN, HIERARKI APPROVAL & VISIBILITAS BERJENJANG

> Tujuan: Pimpro tetap boleh menyerahkan LKP dalam format yang dipakai sekarang (PDF SAP, PDF Excel, workbook .xlsx). LPMS3 mengekstrak, membersihkan, memvalidasi, dan menyimpannya dalam **tabel kanonik**. Data hanya naik ke atasan setelah **disetujui oleh tingkat di bawahnya**, sampai Direksi. Ini menjalankan BOP-001 §5.3.1 (Pimpro melapor dengan FFR-708) dan §5.4.1 (Fungsi Pengawasan Proyek mengirim laporan bulanan ke Fungsi Akuntansi paling lambat tanggal 5).

### 13.1 Hasil pemetaan 10 sampel LKP Oktober 2026

| # | Berkas | Kode Proyek | Varian | Ciri teknis | Total (Rencana kum. / Prestasi kum. / Deviasi) |
|---|---|---|---|---|---|
| 1 | Refurbishment KRI Sigma Diponegoro Class (PDF) | 1LC-522UD024 | **V1** SAP murni | Creator `Form ZSFPS001`, SAP NetWeaver; 79 baris datar | 46,32 / 42,67 / −3,65 |
| 2 | LKP Oktober 26 Sigma Diponegoro Class (.xlsx) | 1LC-522UD024 | **V5** Workbook | Sheet 1.Cover, 2.Rekap (WBS 3 level: 79 kegiatan + 9 baris induk; nomor 1.2 tidak ada), 3.Kurva-S, sheet tersembunyi "3. Kurva-S Copy", 4.QFR-017 (20 isu) | 46,32 / 42,67 / −3,65 |
| 3 | Refurbishment KRI Parchim Pattimura Class | 1UP-123UD022 | **V1** | SAP; nama proyek terpotong ("…CLAS") | 50,92 / 50,12 / −0,80 |
| 4 | Harwat Meriam 155mm Caesar | 1LC-522UD013 | **V2** SAP + lampiran | Halaman SAP + lampiran Kurva-S bulanan ("Bulan ke 32") | 97,66 / 96,66 / −1,00 |
| 5 | System Interoperability Kodal LC-4 | 1UP-324UD013 | **V2** | Lampiran Kurva-S **mingguan** | 91,60 / 91,60 / 0,00 |
| 6 | Backbone NCW Tahap 3 | 1UP-324UD019 | **V2** | Lampiran matriks P/A bulanan + grafik | 67,02 / 63,72 / −3,30 |
| 7 | Satelit Pertahanan | 1UP-123UD011 | **V2** | Lampiran Kurva-S | 45,04 / 43,53 / −1,51 |
| 8 | E-Bike Tahap III | 1UP-326UD005 | **V2** | Laporan pertama (prestasi lalu 0) | 20,02 / 19,02 / −1,00 |
| 9 | Pengadaan Critical Item Radar Master-T | 1UP-226UD002 | **V4** Excel FFR-708 → PDF | Penomoran hierarkis (3.3.1), tanggal berhuruf, "Rp.", tanda "%", minus di depan, No. Laporan & Bulan ke, 4 penanda tangan (+PPK), blok Akuntansi | 67,00 / 31,60 / −35,40 |
| 10 | CTDLS Lanjutan PDN TA 2020–2024 | 1LC-521UD009 | **V3** SAP via "Microsoft Print to PDF" | Sama dengan V1, tata letak teks berbeda | 92,64 / 92,77 / +0,13 |

**Inti temuan:** semua LKP memakai struktur FFR-708 yang sama (Informasi Umum, Informasi Laporan, Pengesahan, tabel kolom a–j). Perbedaannya ada pada *wadah* (SAP/Excel/xlsx), format angka/tanggal, hierarki WBS, dan lampiran. Karena 8 dari 10 berasal dari **form SAP ZSFPS001**, datanya sebenarnya sudah ada di SAP — lihat rekomendasi §13.11.

**Format angka & teks yang harus dinormalisasi**

| Gejala | Contoh dari sampel | Normalisasi |
|---|---|---|
| Desimal koma, ribuan titik | `5.658.552.408.913`, `42,85` | Locale id-ID |
| Minus di belakang (SAP) | `1,63-`, `3,65-` | → `-1.63` |
| Minus di depan + persen | `-27,70%` | → `-27.70` |
| Pecahan 0–1 (xlsx) | Bobot `0.04` | Deteksi Σbobot ≈ 1 → ×100 |
| Format US di teks xlsx | `Rp 4,533,963,135,549.60` | Deteksi pola pemisah per nilai |
| Tanggal angka / berhuruf / formula | `30/12/2022`, `30 Januari 2026`, `=EOMONTH(L20,0)` | Nilai cache Excel; nama bulan Indonesia |
| Nilai tidak diketahui | `TBD` | `NULL` + peringatan |
| Nama kegiatan terbungkus/terpotong (SAP) | "Satelit Communication Interfacing (SATIF", "…(Stabilized Tur" | Gabung baris lanjutan; petakan via nomor baris + tabel alias, nama master menang |
| Header tabel berulang tiap halaman | SAP 4–5 halaman | Dibuang |
| Baris ringkasan/induk tanpa nilai | "1.1 ENGINEERING", "3.3 Manufacturing" | `is_summary = true`, tidak dijumlah |

**Temuan kualitas data (menjadi aturan validasi §13.5)**

| Sampel | Temuan | Aturan |
|---|---|---|
| Backbone NCW | Periode di header **01/11–30/11/2026**, padahal lampiran "PERIODE: OKTOBER 2026" dan dibuat 04/11/2026 | V03 (BLOCK) |
| Radar Master-T | Periode **01 Sep – 31 Okt 2026** (dua bulan), BOP-001 mensyaratkan bulanan; deviasi −35,40 poin | V02 (BLOCK), V18 |
| Satelit Pertahanan | LKP Oktober, lampiran Kurva-S "PERIODE: September 2026" | V11 |
| Sigma (PDF vs .xlsx, proyek & periode sama) | No. Kontrak berbeda (TRAK/734/PLN/VIII/2021/AL vs TRAK/433/PLN/VII/2023/AL), Nilai Proyek berbeda (5.658.552.408.913 vs 4.533.963.135.549,60), tanggal mulai/selesai "TBD" di .xlsx, unit kerja "UP-1" vs "Project Operation Defence", tanggal pembuatan 04/11 vs 29/10 (formula) | V10, V21 |
| Sigma .xlsx | Sheet tersembunyi berisi Kurva-S lama (mulai Okt 2022) sementara sheet aktif mulai Des 2024 → indikasi rebaseline | V20 |
| Kodal LC-4 | Pada lampiran, baris "BOBOT REALISASI" identik dengan "BOBOT RENCANA" di seluruh kolom; tanggal selesai kontrak 31/10/2026 dengan progres 91,60% | V12, V14 |
| Parchim, CTDLS | Kontrak berakhir 07/12/2026 (progres 50,12%) dan 30/11/2026 (progres 92,77%) | V14 |
| E-Bike Tahap III | Nomor Kontrak kosong; nama proyek terpotong | V13 |

Temuan ini contoh untuk merancang aturan validasi, **bukan** kesimpulan atas kinerja proyek; setiap peringatan diselesaikan atau dijelaskan oleh Admin Teknis/Pimpro.

### 13.2 Posisi di sidebar (usulan tambahan)

```
PHASE
  └─ [Monitoring]
       ├─ Laporan Kemajuan (LKP / FFR-708)        ← usulan item baru
       │    ├─ Unggah & Validasi                   (Admin Teknis, Pimpro)
       │    ├─ Approval                            (sesuai level)
       │    └─ Riwayat & Kurva-S                   (semua yang berhak)
       ├─ Procurement Pipeline …
OVERVIEW
  └─ Dashboard  → kotak "LKP menunggu persetujuan saya" + status LKP bulan berjalan per proyek
SETTINGS
  └─ Settings (Application) → tab "Format LKP" (profil varian) & "Matriks Approval"
```

Bila tidak ingin menambah item, halaman yang sama dapat ditaruh di ringkasan grup [Monitoring]; keputusan ini dikunci sebelum G-SB.

### 13.3 Arsitektur pipeline

```
 Pimpro / Admin Teknis
        │ unggah PDF/XLSX + pilih proyek & bulan
        ▼
 ┌──────────────┐   simpan berkas asli (immutable, SHA-256)   ┌───────────────────────────┐
 │ Plugin LPMS3 │ ──────────────────────────────────────────▶ │ /srv/lpms3/lkp-raw (RO)   │
 │ (Rails)      │ ── job: POST /extract ──┐                    └───────────────────────────┘
 └──────┬───────┘                         ▼
        │                    ┌─────────────────────────────┐
        │                    │ lkp-etl (Python, internal)  │  deteksi varian → parser profil →
        │                    │ FastAPI + worker            │  normalisasi → validasi → tulis staging
        │                    └──────────────┬──────────────┘
        ▼                                   ▼
 ┌──────────────────────────────── PostgreSQL: database lpms3_dw ────────────────────────────────┐
 │ raw.*      berkas & metadata, hasil ekstraksi mentah (JSON + koordinat sel/halaman)           │
 │ stg.*      baris ternormalisasi + hasil validasi + koreksi Admin Teknis (bisa diedit)         │
 │ core.*     versi yang sudah disubmit/disetujui (immutable per versi), jejak approval          │
 │ mart.*     view untuk Dashboard, Project Health, Kurva-S — difilter aturan visibilitas §13.7  │
 │ ref.*      profil format, alias kegiatan, hierarki organisasi, matriks approval               │
 └───────────────────────────────────────────────────────────────────────────────────────────────┘
```

Keputusan teknis:

- **Database terpisah `lpms3_dw`** (di container Postgres yang sama) agar skema OpenProject tidak tersentuh migrasi ETL; plugin membaca lewat koneksi Rails kedua. Backup harian wajib mencakup `lpms3_dw` dan folder `lkp-raw` (§13.10).
- **Layanan `lkp-etl`** (Python 3.12: pdfplumber untuk tabel PDF berbasis teks, openpyxl untuk .xlsx dengan *nilai cache* — formula tidak pernah dieksekusi, pandas; OCR ocrmypdf + Tesseract `ind+eng` hanya sebagai fallback untuk PDF hasil scan). Tidak mempublikasikan port; hanya jaringan internal compose.
- **Profil varian sebagai konfigurasi** (`ref.format_profile`, YAML berversi): jangkar teks, urutan kolom, locale angka, gaya minus, skala persen, halaman lampiran. Varian baru → Admin Bisnis membuat profil lewat wizard pemetaan kolom, tanpa rilis kode.
- **Keamanan berkas**: hanya `.pdf`, `.xlsx` (tolak `.xlsm`/makro), ≤ 25 MB, pindai antivirus bila tersedia, sheet tersembunyi dicatat, folder raw tidak dapat ditulis oleh web.

**Deteksi varian (urutan aturan):**

| Varian | Sidik jari |
|---|---|
| V5 Workbook | `.xlsx` berisi sheet bernama seperti `1.Cover` dan `2.Rekap` |
| V1 SAP | PDF metadata Creator `Form ZSFPS001` / Producer `SAP NetWeaver` |
| V3 Print-to-PDF | Producer `Microsoft: Print To PDF` + teks "INFORMASI UMUM" + header kolom a–j |
| V2 SAP + lampiran | Producer `PDFium` + halaman awal berpola SAP; halaman berikut berisi "REALISASI PELAKSANAAN PEKERJAAN"/"Kurva S"/"RENCANA PER BULAN" → diklasifikasi sebagai lampiran |
| V4 Excel FFR-708 | Creator Microsoft Excel + teks "FFR-708" + "REKAPITULASI KEMAJUAN PROYEK" |
| Tidak dikenal | Masuk antrean "Pemetaan manual" (wizard) → hasilnya menjadi profil baru |

### 13.4 Tabel penyimpanan (skema kanonik)

DDL inti (PostgreSQL; nilai persen disimpan **0–100** dengan `numeric(9,4)`, uang `numeric(20,2)`):

```sql
-- ===== referensi =====
CREATE TABLE ref.format_profile (
  id serial PRIMARY KEY, code text UNIQUE,             -- V1_SAP_ZSFPS001, V2_SAP_ATTACH, V3_PRINT, V4_XLS_FFR708, V5_XLSX_WB, …
  version int NOT NULL, config jsonb NOT NULL,         -- jangkar, kolom, locale, gaya minus, skala
  active boolean DEFAULT true, created_by text, created_at timestamptz DEFAULT now());

CREATE TABLE ref.org_unit (                            -- Direksi → Eselon I → Eselon II → (opsional Eselon III) → Proyek
  id serial PRIMARY KEY, parent_id int REFERENCES ref.org_unit, code text UNIQUE, name text,
  level_code text NOT NULL,                            -- DIREKSI | ES1 | ES2 | ES3
  aliases text[] DEFAULT '{}');                        -- "UP-1", "Project Operation Defence", "Project Operation 2", …

CREATE TABLE ref.approval_level (                      -- dapat diubah di Settings → Matriks Approval
  seq int PRIMARY KEY, code text UNIQUE, name text, sla_day_of_month int, signs_as text);

CREATE TABLE ref.position (                            -- siapa memegang level apa, di unit mana
  user_id int NOT NULL, org_unit_id int REFERENCES ref.org_unit, level_code text REFERENCES ref.approval_level(code),
  valid_from date, valid_to date, delegate_of int NULL, PRIMARY KEY (user_id, org_unit_id, level_code, valid_from));

CREATE TABLE ref.activity_alias (                      -- pemetaan nama/nomor baris LKP → WP WBS master
  project_id int, raw_key text, wp_id int, confidence numeric, confirmed_by int, PRIMARY KEY (project_id, raw_key));

-- ===== raw =====
CREATE TABLE raw.lkp_file (
  id bigserial PRIMARY KEY, project_id int NOT NULL, period_month date NOT NULL,
  file_name text, mime text, sha256 char(64) UNIQUE, size_bytes bigint, storage_path text,
  pdf_creator text, pdf_producer text, page_count int, sheet_names text[], hidden_sheets text[],
  detected_profile text, uploaded_by int, uploaded_at timestamptz DEFAULT now());

CREATE TABLE raw.lkp_extract (                         -- keluaran parser apa adanya + koordinat sumber
  file_id bigint REFERENCES raw.lkp_file, profile_code text, profile_version int,
  payload jsonb, warnings jsonb, extracted_at timestamptz DEFAULT now());

-- ===== core (stg.* memiliki struktur sama + kolom edit) =====
CREATE TABLE core.lkp_submission (
  id bigserial PRIMARY KEY, project_id int NOT NULL, kode_proyek text NOT NULL,
  period_month date NOT NULL, period_from date, period_to date,
  revision int NOT NULL DEFAULT 1, is_current boolean DEFAULT true, superseded_by bigint,
  no_laporan int, bulan_ke int, tanggal_pembuatan date, disiapkan_oleh text, jabatan text,
  source_profile text, main_file_id bigint REFERENCES raw.lkp_file,
  status text NOT NULL,                                -- DRAFT | VALIDATING | NEEDS_FIX | SUBMITTED | APPROVED_Lk | RETURNED | PUBLISHED | SUPERSEDED
  published_level int NOT NULL DEFAULT 0,              -- level tertinggi yang SUDAH menyetujui (lihat §13.7)
  is_historical boolean DEFAULT false,                 -- backfill data lama
  created_by int, created_at timestamptz DEFAULT now(),
  UNIQUE (project_id, period_month, revision));

CREATE TABLE core.lkp_header (                         -- sebagaimana tertulis di dokumen + selisih vs master
  submission_id bigint PRIMARY KEY REFERENCES core.lkp_submission,
  nama_proyek text, nomor_kontrak text, nilai_proyek numeric(20,2), mata_uang text DEFAULT 'IDR',
  tgl_mulai date, tgl_selesai date, termin_pembayaran jsonb, institusi_pemberi_kerja text,
  unit_kerja_raw text, org_unit_id int, pimpro_nama text, pimpro_telp text,
  master_diff jsonb);                                  -- {"nomor_kontrak": {"doc": "...", "master": "..."}, …}

CREATE TABLE core.lkp_signatory (                      -- tanda tangan di dokumen (bukan approval sistem)
  submission_id bigint REFERENCES core.lkp_submission, role text,   -- DIBUAT | DIPERIKSA | DISETUJUI | PEMBERI_KERJA | PPK
  nama text, jabatan text, nomor_induk text, pihak text);           -- LEN | PEMBERI_KERJA

CREATE TABLE core.lkp_progress_line (
  id bigserial PRIMARY KEY, submission_id bigint REFERENCES core.lkp_submission,
  line_no int, wbs_code text, parent_wbs text, level int, is_summary boolean DEFAULT false,
  rincian_raw text, wp_id int,                         -- terpetakan ke WP Deliverable/Task LPMS3
  bobot_a numeric(9,4),
  rencana_kum_keg_b numeric(9,4), rencana_kum_tot_c numeric(9,4),
  prestasi_lalu_keg_d numeric(9,4), prestasi_lalu_tot_e numeric(9,4),
  prestasi_ini_keg_f numeric(9,4), prestasi_ini_tot_g numeric(9,4),
  prestasi_kum_keg_h numeric(9,4), prestasi_kum_tot_i numeric(9,4),
  deviasi_j numeric(9,4),
  src_page int, src_ref text, confidence numeric(4,3));   -- halaman/sel asal, keyakinan ekstraksi

CREATE TABLE core.lkp_total (                          -- dilaporkan vs dihitung ulang
  submission_id bigint PRIMARY KEY REFERENCES core.lkp_submission,
  rep_bobot numeric(9,4), rep_rencana_kum numeric(9,4), rep_prestasi_lalu numeric(9,4),
  rep_prestasi_ini numeric(9,4), rep_prestasi_kum numeric(9,4), rep_deviasi numeric(9,4),
  calc_bobot numeric(9,4), calc_rencana_kum numeric(9,4), calc_prestasi_kum numeric(9,4), calc_deviasi numeric(9,4));

CREATE TABLE core.lkp_scurve_point (                   -- lampiran Kurva-S, bulanan atau mingguan
  submission_id bigint REFERENCES core.lkp_submission, wbs_code text NULL,   -- NULL = tingkat proyek
  granularity text CHECK (granularity IN ('WEEK','MONTH')), period_start date, seq_label text,  -- "Bulan 9", "T21", "W3"
  rencana numeric(9,4), realisasi numeric(9,4), rencana_kum numeric(9,4), realisasi_kum numeric(9,4),
  attachment_period date);                             -- periode yang tertulis di lampiran (untuk V11)

CREATE TABLE core.lkp_issue (                          -- dari QFR-017 / bagian kendala; disinkron ke WP Isu/NCR
  submission_id bigint REFERENCES core.lkp_submission, no int, tanggal_laporan date,
  pelapor_unit text, pelapor_nama text, penerima_unit text, penerima_nama text,
  kategori text, detail text, analisa_penyebab text, kategori_5m text,
  tindakan_koreksi text, tindakan_korektif text, target_tgl date, penanggung_jawab text,
  status text,                                         -- OK | On Progress | Not OK
  realisasi_tgl date, verifikasi text, wp_id int);

CREATE TABLE core.lkp_narrative (submission_id bigint REFERENCES core.lkp_submission, section text, body text);

-- ===== kualitas, koreksi, approval =====
CREATE TABLE core.lkp_validation (
  id bigserial PRIMARY KEY, submission_id bigint, rule_code text, severity text,  -- BLOCK | WARN | INFO
  field text, expected text, actual text, message text,
  state text DEFAULT 'OPEN',                           -- OPEN | FIXED | EXPLAINED | WAIVED
  resolved_by int, resolution_note text, resolved_at timestamptz);

CREATE TABLE core.lkp_correction (                     -- setiap perubahan Admin Teknis terhadap hasil ETL
  id bigserial PRIMARY KEY, submission_id bigint, table_name text, row_id bigint, field text,
  old_value text, new_value text, reason text, corrected_by int, corrected_at timestamptz DEFAULT now());

CREATE TABLE core.lkp_approval (
  id bigserial PRIMARY KEY, submission_id bigint, level_seq int, level_code text,
  actor_id int, on_behalf_of int NULL,                 -- delegasi
  action text,                                         -- SUBMIT | APPROVE | RETURN | REJECT | ACKNOWLEDGE
  comment text, acted_at timestamptz DEFAULT now(),
  content_hash char(64));                              -- hash isi versi yang disetujui (anti-ubah)
```

Prinsip:

- **Tidak ada `UPDATE` pada versi yang sudah SUBMITTED.** Perbaikan = revisi baru (`revision + 1`), versi lama `SUPERSEDED` dan tetap dapat dilihat oleh yang pernah melihatnya.
- **Nilai yang dilaporkan dan nilai hitungan ulang disimpan berdampingan** (`core.lkp_total`), sehingga selisih pembulatan tidak hilang.
- Baris LKP dipetakan ke **WP WBS LPMS3** (`wp_id`); setelah publikasi, % selesai Deliverable di LPMS3 dapat diperbarui dari LKP (opsional, sesuai keputusan PMO) sehingga Project Health (§12.3) memakai data yang sama dengan LKP resmi.
- Isu dari QFR-017 dibuat/diperbarui sebagai WP **Isu/NCR** (kunci: proyek + no + tanggal laporan) agar Issue Status & Quality Status (§12.3) terisi.

### 13.5 Aturan validasi

| Kode | Aturan | Tingkat | Contoh sampel |
|---|---|---|---|
| V01 | Kode proyek di dokumen = proyek yang dipilih & ada di master | BLOCK | — |
| V02 | Periode = satu bulan kalender penuh | BLOCK (waiver PMO) | Radar (Sep–Okt) |
| V03 | Periode dokumen = bulan yang dipilih saat unggah; tidak di masa depan relatif tanggal pembuatan | BLOCK | Backbone NCW |
| V04 | Σ bobot = 100 ± 0,05 | BLOCK | — |
| V05 | Aritmetika per baris & total: c≈a×b, e≈a×d, g≈a×f, h≈d+f, i≈e+g, j≈i−c; baris total = Σ baris (toleransi 0,02 poin) | BLOCK | — |
| V06 | Prestasi s/d bulan lalu = prestasi kumulatif LKP bulan sebelumnya yang sudah PUBLISHED | BLOCK (boleh "dijelaskan") | E-Bike = laporan pertama → lewati |
| V07 | Semua persen 0–100; prestasi kumulatif kegiatan ≤ 100 | BLOCK | — |
| V10 | Header ≠ master proyek LPMS3 (No. Kontrak, Nilai, tanggal, unit, Pimpro) → master menang, selisih ditampilkan | WARN | Sigma PDF vs .xlsx |
| V11 | Periode lampiran Kurva-S ≠ periode LKP | WARN | Satelit |
| V12 | Realisasi identik dengan rencana di seluruh periode lampiran | WARN | Kodal LC-4 |
| V13 | Field wajib kosong (No. Kontrak, tanggal) / bernilai "TBD" | WARN | E-Bike, Sigma .xlsx |
| V14 | Tanggal selesai kontrak sudah lewat atau ≤ 60 hari lagi dan progres < 100% | WARN → tampil di Project Health | Kodal, Parchim, CTDLS |
| V15 | Prestasi bulan ini negatif | WARN (wajib keterangan) | — |
| V16 | Prestasi kumulatif turun vs bulan lalu | WARN (wajib keterangan) | — |
| V17 | Baris tidak terpetakan ke WBS master | WARN | Nama terpotong SAP |
| V18 | Deviasi total < −5 poin tanpa narasi kendala atau CR terkait | WARN | Radar (−35,40) |
| V19 | Diserahkan setelah tenggat internal (default tgl 3; batas BOP-001 ke Akuntansi tgl 5) | INFO → indikator ketepatan waktu | — |
| V20 | Kurva-S rencana berbeda dari baseline LPMS3 aktif / ada sheet tersembunyi berbaseline lain tanpa CR rebaseline | WARN → tautan ke Baseline & Rebaseline | Sigma .xlsx |
| V21 | Dua berkas untuk proyek & periode sama dengan nilai berbeda | WARN → pilih satu sebagai utama, lainnya lampiran | Sigma PDF & .xlsx |
| V22 | Berkas identik (SHA-256) sudah pernah diunggah | INFO (tolak duplikat) | — |

Submit ke level berikutnya hanya bisa bila **tidak ada BLOCK terbuka** dan setiap WARN berstatus FIXED/EXPLAINED/WAIVED. WAIVED hanya oleh Fungsi Pengawasan Proyek (L2) ke atas.

### 13.6 Hierarki approval: Admin Teknis → Direksi

| Level | Peran | Tindakan pada LKP | Padanan tanda tangan form | SLA default |
|---|---|---|---|---|
| **L0** | Admin Teknis Proyek | Unggah, jalankan ETL, perbaiki hasil ekstraksi, selesaikan/jelaskan flag, petakan baris ke WBS | — | tgl 2 |
| **L1** | Pimpinan Proyek (Pimpro) | Review data bersih, isi narasi kendala & rencana, **submit** | "Dibuat oleh" | tgl 3 |
| **L2** | Fungsi Pengawasan Proyek (Project Control/PMO) | Verifikasi kontinuitas bulan, baseline, CR, waiver; menyusun laporan bulanan BOP-001 §5.4.1 | — | tgl 4 |
| **L3** | Ka. Unit Eselon II | Periksa & setujui | "Diperiksa oleh" | tgl 5 → otomatis tembusan ke Akuntansi, Keuangan, Perencanaan & Evaluasi Korporasi, SPI |
| **L4** | Ka. Unit Eselon I | Setujui untuk konsumsi Direksi (tanda tangan basah/digital pada PDF tetap hanya saat 100% atau akhir tahun, sesuai catatan kaki form) | "Disetujui oleh" | tgl 8 |
| **L5** | Direksi (Direktur Operasi & Direktur terkait) | Tinjau, beri arahan/catatan (*acknowledge*), tandai proyek "perhatian Direksi" | — | tgl 12 |

Aturan:

1. **Berurutan** L0 → L5. Setiap level dapat **Approve**, **Return** (kembali ke L0/L1 dengan komentar wajib per baris/flag), atau **Reject** (hanya L2 ke atas, misalnya berkas salah proyek).
2. **Approver ditentukan otomatis** dari model Fungsi → Struktur Organisasi (§14.6): L2 = Fungsi Pengawasan Proyek; L3/L4 = Struktural ES2/ES1 unit yang dipetakan ke Fungsi Pelaksanaan Proyek dan menaungi unit pelaksana proyek (dari master proyek, bukan teks di dokumen). Plt/Plh/delegasi dipakai otomatis; bila jabatan kosong → naik ke level berikutnya + notifikasi ke Admin Bisnis.
3. **Delegasi** (BOP-001: struktural berhalangan mendelegasikan ke perwakilan): diatur di Settings → User & Access, berlaku per periode; jejak `on_behalf_of` disimpan.
4. **Matriks dapat dikonfigurasi** per jenis dokumen & unit (mis. menambah Eselon III/Manajer Project Control, atau menjadikan L2 paralel dengan L3) tanpa ubah kode.
5. **Pengingat & eskalasi**: H-1 SLA ke approver, lewat SLA ke atasan approver; status tampil di Dashboard.
6. **Tanda tangan Pemberi Kerja** (pejabat Kemhan/Mabes/PPK) di luar sistem: lembar pengesahan bertanda tangan diunggah sebagai lampiran; namanya tercatat di `core.lkp_signatory`.
7. **Integritas**: setiap approval menyimpan `content_hash` versi yang disetujui; perubahan setelah itu otomatis menjadi revisi baru dan mengulang approval mulai L1 (atau mulai level yang meminta perbaikan).
8. Dokumen lain yang perlu jenjang sama (Project Charter, Dokumen Rencana PMP, Change Request bernilai besar, Laporan Akhir) memakai **mesin approval yang sama** dengan matriks masing-masing.

### 13.7 Visibilitas berjenjang ("data bersih naik ke atas")

**Aturan inti:** pengguna di level *k* pada rantai unit sebuah proyek dapat melihat sebuah versi LKP bila **level *k−1* sudah menyetujuinya** (`published_level ≥ k−1`). Sebelum itu, ia hanya melihat status ("LKP Oktober — sedang di L2, jatuh tempo 4 Nov"), bukan datanya.

| Viewer | Lingkup proyek | Melihat data LKP bulan berjalan ketika | Sebelum itu melihat |
|---|---|---|---|
| Admin Teknis (L0) | Proyek yang ditugaskan | Selalu (termasuk raw & staging) | — |
| Pimpro (L1) | Proyeknya | Setelah L0 menandai "siap review" | Status |
| F. Pengawasan Proyek (L2) | Semua proyek di unit yang diawasi | Setelah L1 submit | LKP terakhir yang ia setujui |
| Eselon II (L3) | Proyek di unitnya | Setelah L2 approve | LKP bulan lalu yang published |
| Tembusan (Akuntansi, Keuangan, Perencanaan & Evaluasi Korporasi, SPI) | Semua (read-only) | Setelah L3 approve | LKP bulan lalu |
| Eselon I (L4) | Proyek di direktorat/divisinya | Setelah L3 approve | LKP bulan lalu |
| Direksi (L5) | Semua proyek | Setelah L4 approve | LKP terakhir yang published + label "data bulan X; bulan Y masih di L3" |
| Auditor (SPI) | Semua | Read-only termasuk raw, koreksi, dan jejak approval | — |

Implementasi:

- `mart.v_lkp_visible(user_id)` menghasilkan versi **terbaru yang boleh dilihat** per proyek-periode untuk user tersebut; Dashboard, Project Health, dan Kurva-S hanya membaca view ini.
- **Row-Level Security PostgreSQL** pada `core`/`mart` dengan variabel sesi `lpms3.user_id` sebagai lapis kedua, sehingga alat BI yang tersambung langsung ke `lpms3_dw` (bila ada) tetap tunduk pada aturan yang sama.
- Hierarki diambil dari `ref.org_unit` + `ref.position`, yaitu salinan tersinkron dari model Fungsi → Struktur Organisasi berversi di plugin (§14.4), dikelola di **Settings → User & Access (Fungsi Manajemen)**.
- Agregat portofolio (mis. total proyek merah per direktorat) untuk Direksi dihitung hanya dari versi yang sudah published ke L4.

### 13.8 Alur pengguna (ringkas)

1. Admin Teknis membuka proyek → [Monitoring] → LKP → **Unggah** (pilih bulan, unggah 1 berkas utama + lampiran opsional).
2. Sistem mendeteksi varian, mengekstrak, lalu menampilkan **layar rekonsiliasi berdampingan**: pratinjau dokumen (halaman/sel sumber disorot) | tabel hasil ekstraksi yang dapat diedit | daftar flag.
3. Admin Teknis memperbaiki (setiap edit masuk `core.lkp_correction` dengan alasan), memetakan baris ke WBS (sekali saja; berikutnya otomatis lewat alias), menandai siap review.
4. Pimpro review, mengisi narasi, submit → L2 … L5 sesuai §13.6.
5. Setelah L3: paket laporan bulanan (PDF FFR-708 seragam yang di-*render* LPMS3 dari data kanonik + berkas asli) otomatis tersedia untuk Fungsi Akuntansi (BOP-001 §5.4.1).
6. Setelah L4: data tampil di Dashboard/Project Health Direksi.

### 13.9 Uji golden-file (bagian dari G-SB → menjadi **G-SB/ETL**)

10 sampel di atas menjadi berkas uji (disimpan di repositori uji **privat** dengan akses terbatas — dokumen bersifat *Internal Use*, tidak di-commit ke repo kode). Kriteria lulus:

| ID | Uji | Kriteria |
|---|---|---|
| E01 | Deteksi varian | 10/10 berkas terdeteksi sesuai tabel §13.1 |
| E02 | Ekstraksi baris | Jumlah baris & nilai a–j 100% sama dengan dokumen (Sigma PDF 79 baris; Sigma .xlsx 79 kegiatan + 9 induk, dan ke-79 kegiatan cocok dengan PDF) |
| E03 | Total | Total dihitung = total dilaporkan (toleransi 0,02) untuk semua sampel |
| E04 | Flag yang diharapkan | Backbone NCW → V03; Radar → V02 & V18; Satelit → V11; Sigma → V10, V20, V21; Kodal → V12 & V14; Parchim, CTDLS → V14; E-Bike → V13 |
| E05 | Normalisasi | `3,65-` → −3,65; `0.04` → 4,00; `30 Januari 2026` → 2026-01-30; `TBD` → NULL |
| E06 | QFR-017 | 20 isu Sigma tersimpan (17 OK, 2 On Progress, 1 Not OK) dan tersinkron ke WP Isu |
| E07 | Approval | Alur L0→L5 lengkap, Return dari L3 ke L1, delegasi L3, revisi baru mengulang approval |
| E08 | Visibilitas | Persona L3/L4/L5/Tembusan hanya melihat data sesuai §13.7 (uji via UI **dan** query SQL langsung dengan RLS) |
| E09 | Kinerja | Ekstraksi PDF ≤ 5 halaman < 30 detik; .xlsx < 60 detik |
| E10 | Varian baru | Admin Bisnis membuat profil baru via wizard untuk 1 format tak dikenal tanpa rilis kode |

### 13.10 Dampak ke deployment

- **Compose**: tambah layanan `lkp-etl` (image `lpms3/lkp-etl:<versi>`, dibangun dari folder `etl/` repo), volume `/srv/lpms3/lkp-raw` (web: tulis lewat plugin; etl: baca), skrip init membuat database `lpms3_dw` dan role `lpms3_etl` (tulis staging/core) serta `lpms3_app` (baca mart, tulis approval).
- **Repo**: folder baru `etl/` (parser, profil YAML default V1–V5, tes golden-file yang menunjuk ke penyimpanan uji privat).
- **Backup**: `ops/backup.sh` ditambah `pg_dump lpms3_dw` dan arsip `lkp-raw`; retensi berkas LKP mengikuti COP-002.
- **Backfill**: saat pilot, impor LKP 12 bulan terakhir proyek aktif dengan penanda `is_historical` (approval cepat oleh L2) agar aturan kontinuitas V06 dan tren Kurva-S langsung berfungsi.
- **Pengembangan**: tambah 1 *data engineer* Python; sprint E1–E4 berjalan paralel dengan S3–S6 plugin:

| Sprint | Lingkup ETL/Approval |
|---|---|
| E1 (minggu 3) | Skema `lpms3_dw`, layanan `lkp-etl`, unggah & raw store, deteksi varian, parser V1/V3 |
| E2 (minggu 4) | Parser V2 (lampiran bulanan & mingguan), V4, V5 (.xlsx + QFR-017), normalisasi |
| E3 (minggu 5) | Aturan validasi V01–V22, layar rekonsiliasi, koreksi & alias WBS |
| E4 (minggu 6–7) | Mesin approval L0–L5, delegasi, SLA/eskalasi, visibilitas + RLS, mart untuk Dashboard/Project Health, render PDF FFR-708 seragam |

Tanpa tambahan data engineer, G-SB/ETL bergeser ±3 minggu.

### 13.11 Rekomendasi tahap berikutnya

1. **Ambil langsung dari SAP**: 8 dari 10 LKP dihasilkan form SAP `ZSFPS001`. Rilis 2 sebaiknya menarik data progres dari SAP PS (RFC/OData atau tabel ekspor) sebagai varian "V0 SAP-direct", sehingga parsing PDF hanya untuk lampiran dan proyek non-SAP.
2. **Tujuan akhir: LKP lahir di LPMS3.** Setelah tim terbiasa memperbarui progres WBS di LPMS3, FFR-708 di-*render* dari data LPMS3; unggahan Pimpro tinggal lampiran pendukung, dan ETL berubah fungsi menjadi alat rekonsiliasi.
3. **Satu sumber master proyek.** Perbedaan No. Kontrak/Nilai Proyek antar-dokumen (contoh Sigma) diselesaikan sekali di master LPMS3 (atribut proyek, dengan CR/adendum bila memang berubah), lalu dokumen divalidasi terhadap master tersebut.

---

## 14. FUNGSI → STRUKTUR ORGANISASI → KAPABILITAS, DAN FUNGSI PROYEK SEBAGAI PUSAT PENGGUNA

### 14.1 Prinsip

1. **Pengguna bertindak atas nama Fungsi.** Hak seseorang di LPMS3 tidak ditempel langsung ke akun, tetapi diturunkan dari **Fungsi** yang ia jalankan.
2. **Setiap Fungsi menempel pada Struktur Organisasi yang sedang berlaku.** BOP-001 memakai *Fungsi Generik* (Fungsi Pelaksanaan Proyek, Fungsi Pengawasan Proyek, dst.), sedangkan organisasi nyata memakai *Unit Aktual* yang dapat berubah. BOP-001 §4.0 sudah menyebut kedua dokumennya: **SKEP.HC/DU/I/2026** (Struktur Organisasi beserta Fungsi dan Tugas Pokok) dan **Nota 021/N/UQ/VIII/2026** (Pembaruan Pemetaan Fungsi Generik terhadap Unit Aktual). LPMS3 menyimpan keduanya sebagai data berversi.
3. **Kapabilitas = Fungsi × Jenjang Jabatan × Lingkup Unit × Peran Proyek.** Pemetaan Fungsi → Struktur menentukan *apa* yang boleh dilakukan dan *di proyek mana*.
4. **Fungsi Proyek dan Fungsi Manajemen Proyek adalah pusat pengguna (*center of usage*).** Seluruh alur, halaman awal, dan prioritas fitur dirancang untuk mereka; fungsi lain berinteraksi sebagai kontributor atau penerima informasi.

Bukti kebutuhan dari sampel LKP: unit kerja proyek tertulis dengan nama berbeda-beda — "UP-1", "UP-3", "Project Operation 2", "Project Operation Defence" — menandakan nama unit pernah berubah. Tanpa pemetaan berversi, approver dan hak lihat akan salah sasaran.

### 14.2 Model konsep

```
Struktur Organisasi (versi, mis. SKEP.HC/DU/I/2026, berlaku mulai …)
  └─ Unit Aktual (pohon: Direksi → Eselon I → Eselon II → Eselon III)
        ├─ Posisi (Struktural ES1/ES2/ES3 | Staf | Admin Teknis)  ←── User (Definitif / Plt / Plh / Delegasi, berjangka waktu)
        └─ dipetakan ke ──▶ Fungsi Generik BOP-001 (Nota 021, berversi)

Proyek ──▶ Unit Pelaksana (+ unit pengawas, unit pendukung bila perlu)

Kapabilitas user di proyek P =
   ∪ aturan(Fungsi dari unit posisinya, Jenjang posisi, Lingkup)  yang lingkupnya mencakup unit P
   ∪ aturan(Peran proyek di P: Pimpro, Tim Proyek, …)
   ∪ pengecualian manual (berjangka, beralasan, tercatat)
```

Istilah BOP-001 langsung terpetakan:

| Istilah di RASCI BOP-001 | Arti di LPMS3 |
|---|---|
| "Struktural Fungsi X" | Pemegang posisi **struktural** (kepala unit, Eselon) pada unit yang dipetakan ke Fungsi X, dalam lingkup unit proyek |
| "Fungsi X" | **Staf** pada unit yang dipetakan ke Fungsi X |
| "Eselon I/II Fungsi X" (peserta Kick-Off, Rapat Tinjauan) | Posisi struktural ES1/ES2 pada unit Fungsi X |
| "Pimpro", "Tim Proyek" | **Peran proyek** (ditetapkan per proyek, HOP-609), bukan jabatan organisasi |
| "Project Sponsor", "Direksi" | Posisi pada unit Direksi / sponsor yang ditunjuk per proyek |

### 14.3 Katalog Fungsi Generik dan kategorinya

| Kategori | Fungsi (dari BOP-001 & RASCI) | Pola penggunaan |
|---|---|---|
| **CORE — Fungsi Proyek** | Fungsi Pelaksanaan Proyek (Pimpro, Admin Teknis Proyek, Tim Proyek inti) | Pengguna utama harian |
| **CORE — Fungsi Manajemen Proyek** | Fungsi Pengawasan Proyek (PMO / Project Control), Fungsi Perencanaan Proyek | Pengguna utama harian; pemilik bisnis LPMS3 |
| **KONTRIBUTOR — pendukung proyek** | Pengendali Anggaran, Keuangan, Penjaminan Mutu, Quality Control, Manajemen Risiko, K3, Pengelolaan Lingkungan Hidup, Perencanaan Pengadaan, Operasional Pengadaan, Pengelola Gudang, Pemasaran, Rekayasa Solusi Teknis, Kontrak Bisnis, Rekrutmen, Pembelajaran & Pengembangan SDM, Pengembangan Organisasi, Pengelolaan Data | Berbasis tugas/permintaan di area fungsinya |
| **PIMPINAN & TEMBUSAN** | Direksi / Project Sponsor, Kepala Unit Es. I, Akuntansi, Perencanaan & Evaluasi Korporasi, SPI | Ringkasan, approval, baca |

Setiap Fungsi dapat diset mode keterlibatan: **DIRECT** (pengguna fungsi itu mengisi sendiri di LPMS3) atau **PROXY** (Fungsi Proyek mengisi atas nama fungsi tersebut, lalu fungsi itu cukup mengonfirmasi lewat tautan/email). Default: DIRECT untuk Pengadaan, Mutu, Risiko, K3LH, Keuangan; PROXY untuk fungsi lain — dapat diubah di Settings (keputusan D13).

### 14.4 Tabel data (plugin `openproject-lpms3`, database OpenProject)

Sumber kebenaran ada di tabel plugin; `lpms3_dw.ref.org_unit`, `ref.position`, dan `ref.approval_level` (§13.4) menjadi **salinan tersinkron** (saat ada perubahan + harian) agar ETL dan RLS memakai struktur yang sama.

| Tabel | Isi utama |
|---|---|
| `lpms3_org_structures` | Versi struktur: kode dokumen (SKEP), nama, berlaku dari/sampai, status DRAFT/ACTIVE/ARCHIVED, lampiran SK |
| `lpms3_org_units` | `structure_id`, induk, kode, nama, jenjang (DIR/ES1/ES2/ES3), **alias** (nama lama/teks di dokumen), kode unit HR/SAP |
| `lpms3_functions` | Katalog Fungsi Generik: kode (mis. `F-PLK` Pelaksanaan Proyek, `F-PWS` Pengawasan Proyek, `F-PRC` Perencanaan Proyek, `F-ANG`, `F-KEU`, `F-AKT`, `F-PMT`, `F-MR`, `F-K3`, `F-LH`, `F-PRP`, `F-OPP`, `F-GDG`, `F-PMS`, `F-RST`, `F-KTB`, …), kategori (§14.3), mode DIRECT/PROXY, rujukan BOP-001 |
| `lpms3_function_unit_maps` | `structure_id`, `function_id`, `unit_id`, utama/tambahan, dokumen dasar (Nota 021), berlaku dari/sampai |
| `lpms3_positions` | `unit_id`, nama jabatan, jenjang posisi (STRUKTURAL_ES1/ES2/ES3, STAF, ADMIN_TEKNIS), kepala unit (bool) |
| `lpms3_user_positions` | `user_id`, `position_id`, jenis (DEFINITIF/PLT/PLH/DELEGASI), periode, dasar penugasan |
| `lpms3_project_units` | `project_id`, `unit_id`, peran unit (PELAKSANA/PENGAWAS/PENDUKUNG) |
| `lpms3_capabilities` | Katalog kapabilitas (§14.5) |
| `lpms3_capability_rules` | `function_id` × `position_grade` × `scope` (OWN_PROJECT / UNIT / SUBTREE / ALL) → `capability_code`; juga aturan per peran proyek |
| `lpms3_capability_exceptions` | Hak tambahan/pencabutan manual: user, kapabilitas, proyek/unit, alasan, berlaku sampai, disetujui oleh |
| `lpms3_capability_snapshots` | Hasil hitung kapabilitas per user (cache) + jejak perubahan ("siapa mendapat/kehilangan apa, kapan, karena apa") |

Setiap tindakan penting (approval, gate, keputusan CR, LKP) menyimpan **`structure_id`, `unit_id`, `function_id`, dan `position_id` pada saat itu**, sehingga riwayat tetap benar walaupun struktur organisasi berganti.

### 14.5 Katalog kapabilitas dan matriks default

Kapabilitas (ringkas): `PRJ_CREATE` (buat proyek / Add New LPMS 2), `PRJ_CODE` (Kode Proyek), `TEAM_ASSIGN`, `PMP_EDIT` (9 aspek), `PMP_APPROVE`, `WBS_EDIT`, `BASELINE_SET`, `REBASELINE_APPROVE`, `WO_ISSUE`, `WO_EXECUTE`, `CR_SUBMIT`, `CR_ANALYZE`, `CR_DECIDE`, `GATE_DECIDE`, `LKP_UPLOAD` (L0), `LKP_SUBMIT` (L1), `LKP_VERIFY` (L2), `LKP_APPROVE_ES2` (L3), `LKP_APPROVE_ES1` (L4), `LKP_ACK_DIR` (L5), `LKP_VIEW_CC` (tembusan), `VALIDATION_WAIVE`, `PROC_EDIT`, `PAYMENT_EDIT`, `PAYMENT_VIEW`, `RISK_EDIT`, `K3LH_EDIT`, `QA_EDIT`, `STAKEHOLDER_EDIT`, `HEALTH_VIEW_PORTFOLIO`, `AUDIT_READ_RAW`, `ORG_ADMIN` (Settings → User & Access), `APP_ADMIN` (Settings → Application).

| Fungsi / jenjang | Lingkup default | Kapabilitas utama |
|---|---|---|
| **Pelaksanaan Proyek — Admin Teknis** | Proyek yang ditugaskan | `LKP_UPLOAD`, `WBS_EDIT`, `WO_ISSUE` (draft), `PROC_EDIT`/`RISK_EDIT`/`QA_EDIT` mode PROXY |
| **Pelaksanaan Proyek — peran Pimpro** | Proyeknya | `LKP_SUBMIT`, `TEAM_ASSIGN`, `PMP_EDIT`, `WO_ISSUE`, `CR_SUBMIT`, penutupan |
| **Pelaksanaan Proyek — Tim Proyek** | Proyeknya | `WBS_EDIT` (WP yang di-assign), `WO_EXECUTE`, isu/risiko |
| **Pelaksanaan Proyek — Struktural ES2** | UNIT (proyek di unitnya) | `LKP_APPROVE_ES2`, `PRJ_CODE`, `GATE_DECIDE` G1/G3 (A di Tabel 1 & 6 BOP-001), `PMP_APPROVE` |
| **Pelaksanaan Proyek — Struktural ES1** | SUBTREE | `LKP_APPROVE_ES1`, `HEALTH_VIEW_PORTFOLIO` |
| **Pengawasan Proyek (Manajemen Proyek/PMO) — Staf** | ALL (atau subtree yang diawasi) | `LKP_VERIFY`, `CR_ANALYZE`, `BASELINE_SET`, `HEALTH_VIEW_PORTFOLIO`, pengawasan tiap tahap |
| **Pengawasan Proyek — Struktural** | ALL | `VALIDATION_WAIVE`, `REBASELINE_APPROVE`, `GATE_DECIDE` G2, `CR_DECIDE` sesuai matriks kewenangan, `ORG_ADMIN` (bersama Admin Bisnis) |
| **Perencanaan Proyek** | Proyek yang ditangani | `PMP_EDIT` (preliminary 9 aspek), template WBS |
| **Pengadaan (Perencanaan/Operasional/Gudang)** | Proyek dengan item pengadaan | `PROC_EDIT` pada tahap miliknya |
| **Keuangan / Pengendali Anggaran** | UNIT/ALL | `PAYMENT_EDIT`, `PAYMENT_VIEW`, Top Up Anggaran |
| **Akuntansi, Perencanaan & Evaluasi Korporasi** | ALL | `LKP_VIEW_CC`, `PAYMENT_VIEW` |
| **Penjaminan Mutu / QC** | Proyek terkait | `QA_EDIT` |
| **Manajemen Risiko / K3 / LH** | Proyek terkait | `RISK_EDIT` / `K3LH_EDIT` |
| **Pemasaran** | Proyek terkait | `STAKEHOLDER_EDIT` |
| **SPI** | ALL | `AUDIT_READ_RAW`, `LKP_VIEW_CC` |
| **Direksi / Project Sponsor** | ALL / proyek yang disponsori | `LKP_ACK_DIR`, `HEALTH_VIEW_PORTFOLIO`, keputusan terminasi |

Matriks ini adalah **data** (`lpms3_capability_rules`), bukan kode; perubahan dilakukan lewat Settings → User & Access dan dicatat.

### 14.6 Cara kapabilitas diterapkan

- **Halaman LPMS3 (plugin):** setiap controller/menu memeriksa `Lpms3::Capability.allowed?(user, :LKP_APPROVE_ES2, project)`. Item sidebar tanpa kapabilitas disembunyikan (§12.2).
- **Modul bawaan OpenProject:** mesin kapabilitas **menurunkan** keanggotaan OpenProject secara otomatis — group per (Fungsi × Unit) dan role proyek LPMS3 (§5.6) — lewat job saat ada perubahan dan setiap malam. Keanggotaan manual tetap boleh tetapi ditandai sebagai pengecualian berjangka.
- **Approval (§13.6):** approver L3/L4 = pemegang posisi Struktural ES2/ES1 pada unit yang dipetakan ke **Fungsi Pelaksanaan Proyek** dan menaungi unit pelaksana proyek; L2 = Fungsi Pengawasan Proyek. Plt/Plh/delegasi otomatis dipakai bila pejabat definitif berhalangan.
- **Visibilitas berjenjang (§13.7):** rantai level dihitung dari pohon unit pada versi struktur yang berlaku.
- **Data (lpms3_dw):** RLS memakai salinan `ref.*` yang tersinkron.

### 14.7 Pergantian struktur organisasi (SKEP baru / Nota pemetaan baru)

1. Admin Bisnis (Fungsi Manajemen Proyek) membuat **versi struktur DRAFT** — salin dari versi aktif.
2. Ubah unit (tambah/gabung/ganti nama — nama lama otomatis menjadi alias), petakan Fungsi → Unit sesuai Nota, petakan user ke posisi (sumber: HC/AD).
3. **Pratinjau dampak:** daftar user yang mendapat/kehilangan kapabilitas, proyek yang pindah unit, approval yang sedang berjalan dan akan berpindah approver.
4. Persetujuan: Fungsi Pengembangan Organisasi/HC (kebenaran struktur) + Struktural Fungsi Pengawasan Proyek (dampak ke proyek).
5. **Aktif pada tanggal berlaku**; kapabilitas dihitung ulang, approval berjalan dialihkan ke pejabat baru dengan catatan, riwayat lama tetap memakai struktur lama.

### 14.8 Fungsi Proyek & Fungsi Manajemen Proyek sebagai pusat pengguna

**Tingkat pengguna**

| Tier | Siapa | Halaman awal | Sidebar | Gaya kerja |
|---|---|---|---|---|
| **1 — Core** | Fungsi Proyek (Pimpro, Admin Teknis, Tim inti) & Fungsi Manajemen Proyek (Pengawasan/PMO, Perencanaan Proyek) | Pimpro/Admin Teknis: [fase aktif] proyek terakhir; PMO: Project Health | Lengkap (OVERVIEW · PHASE · PROJECT · SETTINGS sesuai kapabilitas) | Bekerja harian di LPMS3, memiliki data proyek |
| **2 — Kontributor** | Fungsi pendukung (§14.3) | Dashboard "Permintaan untuk Fungsi Saya" | OVERVIEW + item PHASE di area fungsinya + PROJECT yang melibatkan fungsinya | Menjawab permintaan: Work Order, item pengadaan, inspeksi mutu, konsultasi CR, risiko/K3LH |
| **3 — Pimpinan & Tembusan** | Eselon I, Direksi, Sponsor, Akuntansi, Perencanaan Korporasi, SPI | Dashboard / Project Health | OVERVIEW + PROJECT (baca) + kotak approval | Melihat data yang sudah disetujui, memberi keputusan |

**Aturan desain yang mengikutinya**

1. **Setiap fitur harus melayani pekerjaan Fungsi Proyek atau Fungsi Manajemen Proyek.** Fitur untuk fungsi lain dibuat dalam pola **permintaan → tanggapan** yang dipicu dari proyek (mis. Pimpro menerbitkan Work Order ke Fungsi Rekayasa; Admin Teknis meminta konfirmasi pembayaran ke Keuangan), bukan modul berdiri sendiri.
2. **Proyek adalah wadah utama.** Semua data (LKP, pengadaan, mutu, risiko, K3LH) selalu terikat ke proyek; tampilan per fungsi hanyalah *filter* lintas proyek.
3. **Mode PROXY** memungkinkan Fungsi Proyek tetap berjalan walaupun fungsi pendukung belum aktif memakai LPMS3; setiap isian proxy menampilkan "diisi oleh … atas nama Fungsi …" dan status konfirmasi.
4. **Pemilik sistem & admin bisnis = Fungsi Manajemen Proyek** (Settings → User & Access dan Application dikelola PMO; TI menangani infrastruktur). Ini menegaskan keputusan D7.
5. **Ukuran keberhasilan** diukur pada Tier 1: % proyek aktif dengan LKP terbit tepat waktu lewat LPMS3, % Pimpro aktif mingguan, waktu siklus approval LKP, % CR lewat sistem.
6. **Pelatihan & dukungan** diprioritaskan untuk Tier 1 (lihat §7.3); PMO menjadi dukungan lini pertama bagi Tier 2 dan 3.

### 14.9 Uji tambahan (masuk G-SB/ETL)

| ID | Uji | Kriteria |
|---|---|---|
| F01 | Kapabilitas dari Fungsi | User staf di unit yang dipetakan ke Fungsi Pengadaan otomatis mendapat `PROC_EDIT` di proyek terkait, tanpa set manual |
| F02 | Jenjang | Kepala unit (ES2) Fungsi Pelaksanaan mendapat `LKP_APPROVE_ES2` hanya untuk proyek di unitnya |
| F03 | Ganti struktur | Aktivasi versi struktur baru: pratinjau dampak benar; approval berjalan pindah ke pejabat baru; riwayat lama tetap menunjukkan unit lama |
| F04 | Alias unit | Teks "UP-1" dan "Project Operation Defence" di LKP terpetakan ke unit yang benar |
| F05 | Plt/Plh/Delegasi | Plt ES2 dapat menyetujui L3 selama masa tugas; setelah berakhir hak hilang otomatis |
| F06 | Tier | Persona Tier 2 hanya melihat item sidebar fungsinya; Tier 3 hanya ringkasan & approval |
| F07 | Proxy | Admin Teknis mengisi data pengadaan atas nama Fungsi Pengadaan; konfirmasi Fungsi Pengadaan tercatat |
| F08 | Sinkron DW | Perubahan posisi user tercermin di RLS `lpms3_dw` ≤ 5 menit |

---

## LAMPIRAN

### A. Checklist eksekusi cepat (untuk operator)

```
[ ] F1.1 pre-flight OK (IP, port 5100 bebas, disk, NTP)
[ ] F1.2 OS update, TZ Asia/Jakarta
[ ] F1.3 /srv/lpms3 mounted, opdata chown 1000:1000
[ ] F1.4 Docker + compose plugin, log rotation
[ ] F1.5 UFW (22, 5100 dari subnet yang diizinkan)
[ ] G-SB lulus di staging; image lpms3/openproject:<tag> tersedia (build/load) di produksi
[ ] F2.1 repo + upstream stable/17, commit hash dicatat
[ ] F2.2 .env (PORT=5100, HOST__NAME=192.168.125.14:5100, HTTPS=false, secrets) chmod 600
[ ] F2.3 override: tidak ada p4ssw0rd di config ter-render
[ ] F2.4 up -d (image kustom), seeder exit 0, health_checks/full PASSED, plugin openproject-lpms3 terdaftar
[ ] F2   login admin, ganti password, versi dicatat
[ ] F3   hardening H1–H12
[ ] F3   backup timer aktif + restore drill sukses
[ ] F4   seed 00–70 jalan 2× tanpa error
[ ] F5   template Prediktif/Hibrid/Purnajual
[ ] F2P  sidebar S01–S05 diulang di produksi
[ ] F2P  lkp-etl & lpms3_dw aktif, backup mencakup lpms3_dw + lkp-raw
[ ] F2P  versi struktur organisasi aktif, pemetaan Fungsi → Unit & posisi user dimuat, kapabilitas terhitung
[ ] F6   UAT U01–U26
[ ] F7   go-live checklist
```

### B. Variabel kunci yang tidak boleh berubah sembarangan

| Variabel | Akibat bila diubah |
|---|---|
| `SECRET_KEY_BASE` | Semua sesi & token 2FA "remember" tidak valid |
| `OPENPROJECT_HOST__NAME` | Link di email/notifikasi salah; harus sama dengan URL akses |
| `PORT` | Harus diikuti perubahan `OPENPROJECT_HOST__NAME`, `COLLABORATIVE_SERVER_URL`, firewall |
| `PGDATA` / `OPDATA` | Container akan melihat direktori kosong (tampak seperti data hilang) |
| `TAG` | Upgrade/downgrade; downgrade mayor tidak didukung |

### C. Contoh aturan `DOCKER-USER` (membatasi akses port container)

```bash
# Izinkan hanya subnet 192.168.125.0/24 ke port 5100 yang dipublikasikan Docker
sudo iptables -I DOCKER-USER -p tcp --dport 80 -m conntrack --ctorigdstport 5100 ! -s 192.168.125.0/24 -j DROP
# Persistenkan dengan iptables-persistent atau unit systemd. Uji dari subnet lain sebelum dan sesudah.
```

(Aturan berbasis `--ctorigdstport` karena setelah DNAT port tujuan menjadi port internal container; uji dulu di staging.)

### D. Deploy pada server tanpa Internet (bila A4 tidak terpenuhi)

```bash
# Di mesin yang terhubung Internet:
git clone --depth=1 --branch=stable/17 https://github.com/opf/openproject-docker-compose.git
cd openproject-docker-compose && docker compose pull
docker compose config --images | xargs docker save | gzip > lpms3-images.tar.gz
# Pindahkan repo + lpms3-images.tar.gz ke 192.168.125.14, lalu:
gunzip -c lpms3-images.tar.gz | docker load
docker compose -p lpms3 up -d            # tanpa --pull always
```

### E. Rujukan

- BOP-001 Manajemen Proyek Rev.01, PT Len Industri (Persero), September 2026 — termasuk formulir BFR-001, CFR-022, FFR-708, FFR-710, RFR-002, VFR-015, BOT-001 dan prosedur terkait (FOP-700, FOP-705, HOP-609, SOP-004, SOP-009, BOG-003, QOG-001, QOG-002, QOP-803, QOP-814, COP-002, ROP/VOP/POP Series).
- PMI, *A Guide to the Project Management Body of Knowledge (PMBOK® Guide) – Seventh Edition* (2021): 12 principles, 8 performance domains.
- PMI, *PMBOK® Guide – Eighth Edition* (digital, November 2025): 6 principles, 7 performance domains (Governance, Scope, Schedule, Finance, Stakeholders, Resources, Risk), 5 focus areas, ±40 processes.
- OpenProject Docs — *Installation with Docker Compose* (branch `stable/17`), *Configuration via environment variables*, *Backup/Upgrade*.
- OpenProject release notes 17.1 (project initiation request, EE) dan 17.7 (phases & gates widget, organizational management, resource management EE).
- GitHub: `https://github.com/opf/openproject-docker-compose`, `https://github.com/opf/openproject`.

---
*Dokumen ini adalah rencana kerja. Setiap perubahan setelah disahkan diproses melalui Change Request dan dicatat di `docs/CHANGELOG.md` repo `lpms3-openproject`.*
