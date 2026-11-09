# LPMS3 v2 — Len Project Management System 3

Aplikasi manajemen proyek PT Len Industri yang menjalankan **BOP-001 Manajemen Proyek** dari Inisiasi sampai Closing, berbasis OpenProject + plugin LPMS3, dengan **StarRocks `default_catalog.lpms3`** sebagai database utama.

| Mulai dari | Isi |
|---|---|
| [docs/plan/00_LPMS3_Master_Plan.md](docs/plan/00_LPMS3_Master_Plan.md) | **Master Plan v2.0** (tujuan, arsitektur, WBS, UX, alur Inisiasi→Closing, formulir, deploy, jadwal, risiko, telusur BOP-001) |
| [docs/plan/01_Katalog_Form_SOP.md](docs/plan/01_Katalog_Form_SOP.md) | Peta 80 berkas formulir & prosedur |
| [docs/plan/02_Kamus_Data_Formulir_dan_SOP.md](docs/plan/02_Kamus_Data_Formulir_dan_SOP.md) | Kamus data seluruh tabel & kolom formulir |
| [docs/plan/10_Spesifikasi_Teknis_v1.3.md](docs/plan/10_Spesifikasi_Teknis_v1.3.md) | Buku Teknis (deploy rinci, sidebar, LKP, fungsi & kapabilitas) |
| `docs/data-dictionary/` | `LPMS3_Data_Dictionary.xlsx`, `spec_forms.py` (sumber generator) |
| `docs/wbs/WBS_Template_LPMS.xlsx` | Template WBS resmi |
| `docs/template-bop001/` | Formulir & prosedur resmi (sumber, tidak diubah) |
| `db/` · `db/starrocks/` | DDL PostgreSQL (schema `lpms3`, `lpms3_form`) & StarRocks (`lpms3`) |
| `deploy/` · `ops/` | `.env.example`, compose override, Dockerfile, skrip apply/backup |

Bangkitkan ulang kamus data & DDL setelah mengubah `spec_forms.py`:
`python3 tools/gen_data_dictionary.py .`

Rahasia (password StarRocks/PG, SECRET_KEY_BASE) **hanya** di `deploy/.env` pada VM — tidak pernah di repo.
