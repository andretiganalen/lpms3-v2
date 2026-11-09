# -*- coding: utf-8 -*-
"""Generator kamus data + DDL LPMS3 dari spec_forms.py.
python3 gen.py <out_repo_dir>"""
import sys, os, re, json
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "docs", "data-dictionary"))
from spec_forms import FORMS, REFERENCED_NOT_IN_FOLDER, SOP_TABLES, WBS_TEMPLATE

OUT = sys.argv[1]
SQLT = {"TEXT": "text", "LTEXT": "text", "INT": "integer", "NUM": "numeric(20,4)", "MONEY": "numeric(20,2)",
        "PCT": "numeric(9,4)", "DATE": "date", "BOOL": "boolean", "ENUM": "text", "USER": "integer",
        "FUNGSI": "integer", "UNIT": "integer", "FILE": "bigint", "WBS": "bigint", "JSON": "jsonb"}
TYPE_DESC = {"TEXT": "teks", "LTEXT": "teks panjang", "INT": "bilangan bulat", "NUM": "angka", "MONEY": "uang (Rp)",
             "PCT": "persen 0–100", "DATE": "tanggal", "BOOL": "ya/tidak", "ENUM": "pilihan", "USER": "pengguna",
             "FUNGSI": "fungsi", "UNIT": "unit organisasi", "FILE": "berkas", "WBS": "node WBS", "JSON": "daftar/terstruktur"}

def q(s): return "'" + str(s).replace("'", "''") + "'"

sql = ["-- =====================================================================",
       "-- LPMS3 · Skema formulir BOP-001 (DIBANGKITKAN dari docs/data-dictionary/spec_forms.py)",
       "-- Jangan edit manual: ubah spec lalu jalankan tools/gen_data_dictionary.py",
       "-- =====================================================================",
       "CREATE SCHEMA IF NOT EXISTS lpms3_form;", "",
       "-- Definisi formulir (versi template) ----------------------------------",
       "CREATE TABLE IF NOT EXISTS lpms3_form.form_definition (",
       "  code text NOT NULL, rev text NOT NULL, title text NOT NULL, phase text, owner_function text,",
       "  sop_refs text[], menu_path text, source_file text, active boolean DEFAULT true,",
       "  PRIMARY KEY (code, rev));", "",
       "-- Satu baris per dokumen yang diisi (instance formulir) --------------",
       "CREATE TABLE IF NOT EXISTS lpms3_form.form_instance (",
       "  id bigserial PRIMARY KEY, form_code text NOT NULL, form_rev text NOT NULL,",
       "  project_id integer NOT NULL,            -- projects.id OpenProject",
       "  wbs_node_id bigint,                     -- lpms3_wbs.wbs_node.id (folder bukti)",
       "  doc_no text,                            -- penomoran otomatis per pola formulir",
       "  period_month date,                      -- untuk formulir periodik (LKP, risk register)",
       "  revision integer NOT NULL DEFAULT 1, is_current boolean NOT NULL DEFAULT true, superseded_by bigint,",
       "  status text NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','SUBMITTED','IN_REVIEW','RETURNED','APPROVED','PUBLISHED','SUPERSEDED','CANCELLED')),",
       "  published_level integer NOT NULL DEFAULT 0,",
       "  structure_id integer, unit_id integer,   -- snapshot struktur organisasi saat dibuat (§14)",
       "  source text NOT NULL DEFAULT 'LPMS3' CHECK (source IN ('LPMS3','IMPORT_LPMS2','ETL_UPLOAD','ERP')),",
       "  pdf_render_file_id bigint,              -- PDF resmi yang dirender dari data",
       "  created_by integer NOT NULL, created_at timestamptz NOT NULL DEFAULT now(),",
       "  updated_by integer, updated_at timestamptz,",
       "  FOREIGN KEY (form_code, form_rev) REFERENCES lpms3_form.form_definition(code, rev));",
       "CREATE INDEX IF NOT EXISTS ix_form_instance_proj ON lpms3_form.form_instance(project_id, form_code, period_month);", "",
       "-- Tanda tangan / pengesahan pada formulir (sesuai kolom pengesahan form) --",
       "CREATE TABLE IF NOT EXISTS lpms3_form.form_signature (",
       "  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),",
       "  seq integer NOT NULL, role_label text NOT NULL,      -- 'Dibuat oleh', 'Diperiksa oleh', 'Disetujui oleh', ...",
       "  function_code text, position_grade text,            -- mis. F-MPR / STRUKTURAL_ES2",
       "  signer_user_id integer, signer_name text, signer_nik text, signer_jabatan text, external_party boolean DEFAULT false,",
       "  on_behalf_of integer, method text CHECK (method IN ('SYSTEM','DIGITAL_CERT','WET_SCAN')),",
       "  signed_at timestamptz, content_hash char(64));", "",
       "-- Lampiran (bukti) – disimpan di attachments OpenProject + folder WBS ---",
       "CREATE TABLE IF NOT EXISTS lpms3_form.form_attachment (",
       "  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),",
       "  field_name text, op_attachment_id bigint NOT NULL, wbs_node_id bigint, ffr710_item text, uploaded_by integer, uploaded_at timestamptz DEFAULT now());", ""]

md = ["# Kamus Data Formulir & Prosedur BOP-001 → LPMS3", "",
      "> Dokumen ini **dibangkitkan otomatis** dari `docs/data-dictionary/spec_forms.py` (sumber: template di `docs/template-bop001`).",
      "> Setiap tabel dan kolom pada formulir dipetakan ke tabel database `lpms3_form.*` beserta tipe, pilihan (dropdown asli formulir), dan kewajiban isi.", "",
      "Kolom standar setiap tabel baris: `id`, `form_instance_id`, `line_no`. Tabel header: `form_instance_id` sebagai kunci.", "",
      "Kolom standar setiap dokumen (tabel `lpms3_form.form_instance`): proyek, node WBS (folder bukti), nomor dokumen, periode, revisi, status, level publikasi, unit & struktur organisasi saat dibuat, sumber data, PDF hasil render, audit.", "",
      "## Ringkasan", "", "| Kode | Rev | Formulir | Fase | Menu LPMS3 | Tabel | Kolom |", "|---|---|---|---|---|---|---|"]
rows_x = []; enums_x = []; forms_x = []
tot_cols = 0
for f in FORMS:
    ncols = sum(len(t["cols"]) for t in f["tables"]); tot_cols += ncols
    md.append(f"| {f['code']} | {f['rev']} | {f['title']} | {f['phase']} | {f['menu']} | {len(f['tables'])} | {ncols} |")
    forms_x.append([f["code"], f["rev"], f["title"], f["phase"], ", ".join(f["sop"]), f["owner"], f["menu"], f["src"], len(f["tables"]), ncols, " ; ".join(f["signatories"])])
    sql.append(f"INSERT INTO lpms3_form.form_definition(code,rev,title,phase,owner_function,sop_refs,menu_path,source_file) VALUES ({q(f['code'])},{q(f['rev'])},{q(f['title'])},{q(f['phase'])},{q(f['owner'])},ARRAY[{','.join(q(s) for s in f['sop'])}]::text[],{q(f['menu'])},{q(f['src'])}) ON CONFLICT DO NOTHING;")
md.append(f"| **WBS-LPMS** | – | {WBS_TEMPLATE['title']} | Perencanaan → Closing | PHASE › [Perencanaan] › WBS Generation | 1 | {len(WBS_TEMPLATE['cols'])} |")
md += ["", f"**Total:** {len(FORMS)} formulir, {sum(len(f['tables']) for f in FORMS)} tabel, {tot_cols} kolom formulir + {len(WBS_TEMPLATE['cols'])} kolom WBS.", ""]
sql.append("")

for f in FORMS:
    md += [f"## {f['code']} rev.{f['rev']} — {f['title']}", "",
           f"- **Sumber template:** `{f['src']}`", f"- **Fase:** {f['phase']}  ·  **Prosedur:** {', '.join(f['sop'])}",
           f"- **Pemilik/pengisi:** {f['owner']}", f"- **Menu LPMS3:** {f['menu']}"]
    if f["signatories"]:
        md.append("- **Pengesahan (tabel `form_signature`):** " + "; ".join(f["signatories"]))
    md.append("")
    for t in f["tables"]:
        tname = t["name"]; kind = t["kind"]
        md += [f"### Tabel `lpms3_form.{tname}` ({kind})", ""]
        if t.get("note"): md += [f"_{t['note']}_", ""]
        md += ["| # | Kolom DB | Label di formulir | Tipe | Pilihan / aturan | Wajib |", "|---|---|---|---|---|---|"]
        ddl = [f"CREATE TABLE IF NOT EXISTS lpms3_form.{tname} ("]
        if kind == "header":
            ddl.append("  form_instance_id bigint PRIMARY KEY REFERENCES lpms3_form.form_instance(id),")
        elif kind == "master":
            ddl.append("  id serial PRIMARY KEY, form_rev text NOT NULL,")
        else:
            ddl.append("  id bigserial PRIMARY KEY, form_instance_id bigint NOT NULL REFERENCES lpms3_form.form_instance(id),")
            ddl.append("  line_no integer NOT NULL,")
        for i, (col, label, typ, enum, req) in enumerate(t["cols"], 1):
            e = ", ".join(enum) if isinstance(enum, list) else enum
            md.append(f"| {i} | `{col}` | {label} | {TYPE_DESC[typ]} | {e} | {'Ya' if req else '–'} |")
            line = f"  {col} {SQLT[typ]}"
            if req and kind == "lines" and typ not in ("JSON",): line += " NOT NULL"
            if typ == "ENUM" and isinstance(enum, list) and len(enum) <= 40:
                line += f" CHECK ({col} IN ({', '.join(q(x) for x in enum)}))"
            ddl.append(line + ",")
            rows_x.append([f["code"], f["rev"], tname, kind, i, col, label, typ, SQLT[typ], e, "Ya" if req else "", f["menu"]])
            if isinstance(enum, list):
                for v in enum: enums_x.append([f["code"], tname, col, v])
        ddl.append("  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz")
        ddl.append(");")
        if kind == "lines": ddl.append(f"CREATE INDEX IF NOT EXISTS ix_{tname}_inst ON lpms3_form.{tname}(form_instance_id, line_no);")
        sql += ddl + [""]
        md.append("")

# WBS template section in md
md += ["## WBS-LPMS — WBS Template LPMS", "", "Tabel ini menjadi **struktur wajib** pengisian WBS, dasar folder bukti (Evidence Files), dan dasar Kurva-S. Skema: `db/020_lpms3_wbs.sql`.", "",
       "| # | Kolom DB | Kolom template | Tipe | Pilihan / aturan | Wajib |", "|---|---|---|---|---|---|"]
for i, (col, label, typ, enum, req) in enumerate(WBS_TEMPLATE["cols"], 1):
    e = ", ".join(enum) if isinstance(enum, list) else enum
    md.append(f"| {i} | `{col}` | {label} | {TYPE_DESC[typ]} | {e} | {'Ya' if req else '–'} |")
    rows_x.append(["WBS-LPMS", "-", "lpms3_wbs.wbs_node", "lines", i, col, label, typ, SQLT[typ], e, "Ya" if req else "", "PHASE › [Perencanaan] › WBS Generation"])
md.append("")

md += ["## Tabel di dalam Prosedur (SOP) yang diakomodasi", "", "| Prosedur | Tabel | Struktur kolom | Tabel LPMS3 | Pemakaian |", "|---|---|---|---|---|"]
for s in SOP_TABLES: md.append("| " + " | ".join(s) + " |")
md += ["", "## Formulir yang dirujuk prosedur tetapi templatenya belum ada di folder", "",
       "Ditangani sebagai **dokumen terstruktur generik** (`form_instance` + metadata + lampiran + tanda tangan) dan diberi slot di checklist FLP-01/FFR-710. Begitu template diserahkan, kolomnya ditambahkan ke `spec_forms.py` dan DDL dibangkitkan ulang (tanpa mengubah alur).", ""]
for ph, items in REFERENCED_NOT_IN_FOLDER.items():
    md.append(f"- **{ph}:** " + "; ".join(items))
md.append("")

os.makedirs(f"{OUT}/db", exist_ok=True); os.makedirs(f"{OUT}/docs/data-dictionary", exist_ok=True); os.makedirs(f"{OUT}/docs/plan", exist_ok=True)
open(f"{OUT}/db/010_lpms3_forms.sql", "w").write("\n".join(sql) + "\n")
open(f"{OUT}/docs/plan/02_Kamus_Data_Formulir_dan_SOP.md", "w").write("\n".join(md) + "\n")


# ---------------------------------------------------------------- StarRocks mirror (default_catalog.lpms3)
SRT = {"TEXT": "STRING", "LTEXT": "STRING", "INT": "INT", "NUM": "DECIMAL(20,4)", "MONEY": "DECIMAL(20,2)",
       "PCT": "DECIMAL(9,4)", "DATE": "DATE", "BOOL": "BOOLEAN", "ENUM": "STRING", "USER": "INT",
       "FUNGSI": "INT", "UNIT": "INT", "FILE": "BIGINT", "WBS": "BIGINT", "JSON": "JSON"}
sr = ["-- =====================================================================",
      "-- LPMS3 · StarRocks default_catalog.lpms3 · mirror tabel formulir (DIBANGKITKAN)",
      "-- Sumber tulis: PostgreSQL schema lpms3_form (aplikasi). Disinkron oleh db/starrocks/900_sync_tasks.sql",
      "-- =====================================================================",
      "SET CATALOG default_catalog;", "USE lpms3;", "",
      "CREATE TABLE IF NOT EXISTS form_definition (code VARCHAR(20) NOT NULL, rev VARCHAR(10) NOT NULL, title STRING, phase STRING, owner_function STRING, sop_refs JSON, menu_path STRING, source_file STRING, active BOOLEAN) PRIMARY KEY (code, rev) DISTRIBUTED BY HASH(code);",
      "CREATE TABLE IF NOT EXISTS form_instance (id BIGINT NOT NULL, form_code VARCHAR(20), form_rev VARCHAR(10), project_id INT, wbs_node_id BIGINT, doc_no STRING, period_month DATE, revision INT, is_current BOOLEAN, superseded_by BIGINT, status VARCHAR(20), published_level INT, structure_id INT, unit_id INT, source VARCHAR(20), pdf_render_file_id BIGINT, created_by INT, created_at DATETIME, updated_by INT, updated_at DATETIME, synced_at DATETIME) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);",
      "CREATE TABLE IF NOT EXISTS form_signature (id BIGINT NOT NULL, form_instance_id BIGINT, seq INT, role_label STRING, function_code VARCHAR(20), position_grade VARCHAR(30), signer_user_id INT, signer_name STRING, signer_nik VARCHAR(30), signer_jabatan STRING, external_party BOOLEAN, on_behalf_of INT, method VARCHAR(20), signed_at DATETIME, content_hash VARCHAR(64), synced_at DATETIME) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);",
      "CREATE TABLE IF NOT EXISTS form_attachment (id BIGINT NOT NULL, form_instance_id BIGINT, field_name STRING, op_attachment_id BIGINT, wbs_node_id BIGINT, ffr710_item STRING, uploaded_by INT, uploaded_at DATETIME, synced_at DATETIME) PRIMARY KEY (id) DISTRIBUTED BY HASH(id);", ""]
for f in FORMS:
    for t in f["tables"]:
        tname = t["name"]; kind = t["kind"]
        if kind == "header":
            cols = ["form_instance_id BIGINT NOT NULL"]; pk = "form_instance_id"
        elif kind == "master":
            cols = ["id INT NOT NULL", "form_rev VARCHAR(10)"]; pk = "id"
        else:
            cols = ["id BIGINT NOT NULL", "form_instance_id BIGINT", "line_no INT"]; pk = "id"
        for (col, label, typ, enum, req) in t["cols"]:
            cols.append(f"{col} {SRT[typ]} COMMENT {q(label[:200])}")
        cols += ["created_at DATETIME", "updated_at DATETIME", "synced_at DATETIME"]
        sr.append(f"CREATE TABLE IF NOT EXISTS form_{tname} (\n  " + ",\n  ".join(cols) + f"\n) PRIMARY KEY ({pk})\nCOMMENT {q(f['code'] + ' ' + f['title'][:120])}\nDISTRIBUTED BY HASH({pk});\n")
os.makedirs(f"{OUT}/db/starrocks", exist_ok=True)
open(f"{OUT}/db/starrocks/110_lpms3_forms_mirror.sql", "w").write("\n".join(sr) + "\n")

# XLSX
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment
from openpyxl.utils import get_column_letter
wb = Workbook()
def sheet(title, header, data, widths):
    ws = wb.create_sheet(title)
    ws.append(header)
    for c in ws[1]:
        c.font = Font(bold=True, color="FFFFFF"); c.fill = PatternFill("solid", fgColor="B91C1C"); c.alignment = Alignment(wrap_text=True, vertical="top")
    for r in data: ws.append(r)
    for i, w in enumerate(widths, 1): ws.column_dimensions[get_column_letter(i)].width = w
    ws.freeze_panes = "A2"; ws.auto_filter.ref = ws.dimensions
wb.remove(wb.active)
sheet("Formulir", ["Kode", "Rev", "Judul", "Fase", "Prosedur", "Pemilik/pengisi", "Menu LPMS3", "Sumber template", "Jml tabel", "Jml kolom", "Pengesahan"], forms_x, [10, 5, 45, 28, 28, 40, 45, 50, 8, 8, 60])
sheet("Kolom", ["Kode", "Rev", "Tabel DB", "Jenis", "#", "Kolom DB", "Label formulir", "Tipe", "Tipe SQL", "Pilihan/aturan", "Wajib", "Menu"], rows_x, [10, 5, 30, 8, 4, 28, 60, 8, 14, 60, 6, 40])
sheet("Pilihan", ["Kode", "Tabel", "Kolom", "Nilai"], enums_x, [10, 30, 28, 60])
sheet("Tabel_SOP", ["Prosedur", "Tabel", "Struktur", "Tabel LPMS3", "Pemakaian"], [list(s) for s in SOP_TABLES], [16, 40, 80, 26, 40])
sheet("Belum_di_folder", ["Fase", "Formulir"], [[ph, it] for ph, items in REFERENCED_NOT_IN_FOLDER.items() for it in items], [24, 70])
wb.save(f"{OUT}/docs/data-dictionary/LPMS3_Data_Dictionary.xlsx")
print("forms", len(FORMS), "tables", sum(len(f['tables']) for f in FORMS), "cols", tot_cols, "rows", len(rows_x), "enums", len(enums_x))
