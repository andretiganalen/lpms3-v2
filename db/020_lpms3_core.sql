-- =====================================================================
-- LPMS3 · PostgreSQL (database OpenProject) · schema lpms3
-- Data transaksional plugin openproject-lpms3: organisasi & kapabilitas (§14),
-- WBS Template LPMS + Kurva-S + baseline (§5, §15), referensi dari SOP.
-- Seluruh tabel dicerminkan ke StarRocks default_catalog.lpms3 (db/starrocks/*).
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS lpms3;

-- ---------- Struktur organisasi & fungsi (SKEP.HC/DU/I/2026, Nota 021, CLP-001) ----------
CREATE TABLE IF NOT EXISTS lpms3.org_structure (
  id serial PRIMARY KEY, code text NOT NULL UNIQUE, name text NOT NULL,
  effective_from date NOT NULL, effective_to date,
  status text NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','ACTIVE','ARCHIVED')),
  basis_doc_attachment_id bigint, created_by integer, created_at timestamptz DEFAULT now(), updated_at timestamptz);

CREATE TABLE IF NOT EXISTS lpms3.org_unit (
  id serial PRIMARY KEY, structure_id integer NOT NULL REFERENCES lpms3.org_structure(id),
  parent_id integer REFERENCES lpms3.org_unit(id), code text NOT NULL, name text NOT NULL,
  grade text NOT NULL CHECK (grade IN ('DIREKSI','ES1','ES2','ES3','NON')),
  aliases text[] NOT NULL DEFAULT '{}', hr_code text, sap_code text, updated_at timestamptz,
  UNIQUE (structure_id, code));

CREATE TABLE IF NOT EXISTS lpms3.fungsi_generik (            -- CLP-001 (35 fungsi)
  id serial PRIMARY KEY, code text NOT NULL UNIQUE, clp_no integer, name text NOT NULL, definition text,
  category text NOT NULL CHECK (category IN ('CORE_PROYEK','CORE_MANAJEMEN_PROYEK','KONTRIBUTOR','PIMPINAN_TEMBUSAN','LAINNYA')),
  involvement_mode text NOT NULL DEFAULT 'DIRECT' CHECK (involvement_mode IN ('DIRECT','PROXY')),
  bop_alias text[] NOT NULL DEFAULT '{}', active boolean DEFAULT true, updated_at timestamptz);

CREATE TABLE IF NOT EXISTS lpms3.fungsi_unit_map (           -- Nota 021: Fungsi Generik -> Unit Aktual
  id serial PRIMARY KEY, structure_id integer NOT NULL REFERENCES lpms3.org_structure(id),
  fungsi_id integer NOT NULL REFERENCES lpms3.fungsi_generik(id), unit_id integer NOT NULL REFERENCES lpms3.org_unit(id),
  is_primary boolean DEFAULT true, basis_doc text, effective_from date, effective_to date, updated_at timestamptz,
  UNIQUE (structure_id, fungsi_id, unit_id));

CREATE TABLE IF NOT EXISTS lpms3.position (
  id serial PRIMARY KEY, unit_id integer NOT NULL REFERENCES lpms3.org_unit(id), title text NOT NULL,
  grade text NOT NULL CHECK (grade IN ('DIREKSI','STRUKTURAL_ES1','STRUKTURAL_ES2','STRUKTURAL_ES3','STAF','ADMIN_TEKNIS')),
  is_head boolean DEFAULT false, updated_at timestamptz);

CREATE TABLE IF NOT EXISTS lpms3.user_position (
  id serial PRIMARY KEY, user_id integer NOT NULL, position_id integer NOT NULL REFERENCES lpms3.position(id),
  assignment_type text NOT NULL CHECK (assignment_type IN ('DEFINITIF','PLT','PLH','DELEGASI')),
  valid_from date NOT NULL, valid_to date, basis_doc text, delegate_of integer, updated_at timestamptz);

CREATE TABLE IF NOT EXISTS lpms3.project_unit (
  project_id integer NOT NULL, unit_id integer NOT NULL REFERENCES lpms3.org_unit(id),
  role text NOT NULL CHECK (role IN ('PELAKSANA','PENGAWAS','PENDUKUNG')), updated_at timestamptz,
  PRIMARY KEY (project_id, unit_id, role));

CREATE TABLE IF NOT EXISTS lpms3.capability (
  code text PRIMARY KEY, name text NOT NULL, module text NOT NULL, description text);

CREATE TABLE IF NOT EXISTS lpms3.capability_rule (
  id serial PRIMARY KEY, fungsi_id integer REFERENCES lpms3.fungsi_generik(id), position_grade text,
  project_role text,                    -- PIMPRO, TIM_PROYEK, ADMIN_TEKNIS, SPONSOR (alternatif fungsi)
  scope text NOT NULL CHECK (scope IN ('OWN_PROJECT','UNIT','SUBTREE','ALL')),
  capability_code text NOT NULL REFERENCES lpms3.capability(code), allow boolean NOT NULL DEFAULT true,
  info_access text CHECK (info_access IN ('COPY_VALUE','HPS','KELAS_PROYEK','AKSES_PENUH')),   -- SOP-004/SOP-009
  updated_at timestamptz);

CREATE TABLE IF NOT EXISTS lpms3.capability_exception (
  id serial PRIMARY KEY, user_id integer NOT NULL, capability_code text NOT NULL REFERENCES lpms3.capability(code),
  project_id integer, unit_id integer, allow boolean NOT NULL, reason text NOT NULL, valid_until date NOT NULL,
  approved_by integer NOT NULL, created_at timestamptz DEFAULT now());

-- ---------- Referensi dari SOP ----------
CREATE TABLE IF NOT EXISTS lpms3.ref_jenis_kode (            -- FOP-700 (14 jenis kode)
  code text PRIMARY KEY, name text NOT NULL, kelompok text NOT NULL CHECK (kelompok IN ('PROYEK','PROGRAM','TRANSFER_LOAD')),
  pemilik_kode text, tujuan text, output text, template_code text);

CREATE TABLE IF NOT EXISTS lpms3.ref_kelas_kontrak (         -- SOP-004
  kelas text PRIMARY KEY, nilai_min numeric(20,2), nilai_max numeric(20,2), tinjauan_go text);

CREATE TABLE IF NOT EXISTS lpms3.ref_matriks_kewenangan (    -- BOG-003 pergeseran anggaran, BFR-001 CR
  id serial PRIMARY KEY, objek text NOT NULL CHECK (objek IN ('PERGESERAN_ANGGARAN','TOP_UP','CHANGE_REQUEST','REVISI_ANGGARAN_ABT','ADENDUM')),
  nilai_min numeric(20,2) NOT NULL, nilai_max numeric(20,2), pengaju text NOT NULL, penyetuju text NOT NULL,
  sla_hari integer, dokumen text, sumber_sop text NOT NULL,
  UNIQUE (objek, nilai_min));

CREATE TABLE IF NOT EXISTS lpms3.ref_level_risiko (          -- ROP-911
  skor_min integer NOT NULL, skor_max integer NOT NULL, level text PRIMARY KEY, warna text, tindakan text);

CREATE TABLE IF NOT EXISTS lpms3.ref_peserta_rapat (         -- BOP-001 Tabel 2/4, SOP-004, SOP-009, BOG-003
  id serial PRIMARY KEY, jenis_rapat text NOT NULL, kelas text, urutan integer NOT NULL, peran text NOT NULL,
  peserta text NOT NULL, fungsi_code text, grade text, sumber_sop text NOT NULL,
  UNIQUE NULLS NOT DISTINCT (jenis_rapat, kelas, urutan));

CREATE TABLE IF NOT EXISTS lpms3.ref_rasci (                 -- BOP-001 Tabel 1,2,3,5,6
  id serial PRIMARY KEY, tabel text NOT NULL, aktivitas_no integer NOT NULL, aktivitas text NOT NULL,
  fase text NOT NULL, peran text NOT NULL CHECK (peran IN ('A','R','S','C','I')), pihak text NOT NULL, fungsi_code text, grade text);

CREATE TABLE IF NOT EXISTS lpms3.ref_dokumen_taxonomy (      -- FFR-710 Daftar Isi (A–E) + FLP-01
  id serial PRIMARY KEY, bagian text NOT NULL, no text NOT NULL, parent_id integer REFERENCES lpms3.ref_dokumen_taxonomy(id),
  uraian text NOT NULL, form_code text, wajib_untuk text[], fase text, keterangan text, retensi_tahun integer);

-- ---------- WBS Template LPMS + Kurva-S ----------
CREATE TABLE IF NOT EXISTS lpms3.wbs_node (
  id bigserial PRIMARY KEY, project_id integer NOT NULL, work_package_id integer UNIQUE,   -- WP OpenProject (Gantt)
  parent_id bigint REFERENCES lpms3.wbs_node(id), wbs_code text NOT NULL,
  level text NOT NULL CHECK (level IN ('Level 0','Level 1','Level 2','Level 3','Level 4','Level 5 Activity','Level 6','Level 6 Activity','Level 7','Level 7 Activity')),
  is_activity boolean GENERATED ALWAYS AS (level LIKE '%Activity') STORED,
  tasks text NOT NULL, notes text, resource text, priority text CHECK (priority IN ('Low','Medium','High')),
  date_plan_start date, date_plan_finish date, date_actual_start date, date_actual_finish date,
  weigh_factor numeric(9,6) NOT NULL CHECK (weigh_factor >= 0 AND weigh_factor <= 1),
  weight numeric(12,9),                 -- = weight induk × weigh_factor (dihitung trigger/job)
  pct_complete numeric(5,4) CHECK (pct_complete IN (0,0.25,0.5,0.75,1)),
  pct_progress numeric(12,9),           -- aktivitas: weight × pct_complete; induk: Σ anak
  harga_pekerjaan numeric(20,2),        -- untuk bobot BOP-001 §5.4.1 (opsional per kontrak)
  sow_boq_ref text, evidence_folder text NOT NULL,   -- path folder bukti = /<kode proyek>/<wbs_code> <tasks>
  sort_order integer NOT NULL DEFAULT 0, updated_by integer, updated_at timestamptz DEFAULT now(),
  UNIQUE (project_id, wbs_code));

CREATE TABLE IF NOT EXISTS lpms3.wbs_progress (               -- riwayat update % Complete (bukti wajib)
  id bigserial PRIMARY KEY, wbs_node_id bigint NOT NULL REFERENCES lpms3.wbs_node(id), period_month date NOT NULL,
  pct_complete numeric(5,4) NOT NULL CHECK (pct_complete IN (0,0.25,0.5,0.75,1)), evidence_attachment_ids bigint[] NOT NULL DEFAULT '{}',
  note text, updated_by integer NOT NULL, updated_at timestamptz NOT NULL DEFAULT now(), verified_by integer, verified_at timestamptz);

CREATE TABLE IF NOT EXISTS lpms3.baseline (
  id bigserial PRIMARY KEY, project_id integer NOT NULL, version integer NOT NULL, label text NOT NULL,   -- Baseline 0 = Kick-Off
  change_request_form_id bigint,        -- wajib untuk version > 0 (BFR-001 disetujui)
  meeting_form_id bigint,               -- CFR-022 kick-off / tinjauan
  approved_by integer, approved_at timestamptz, is_active boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now(), UNIQUE (project_id, version));

CREATE TABLE IF NOT EXISTS lpms3.baseline_item (
  baseline_id bigint NOT NULL REFERENCES lpms3.baseline(id), wbs_node_id bigint NOT NULL,
  wbs_code text NOT NULL, tasks text NOT NULL, level text NOT NULL, weight numeric(12,9) NOT NULL,
  date_plan_start date, date_plan_finish date, harga_pekerjaan numeric(20,2),
  PRIMARY KEY (baseline_id, wbs_node_id));

CREATE TABLE IF NOT EXISTS lpms3.scurve_plan (                -- distribusi rencana per periode per aktivitas
  baseline_id bigint NOT NULL REFERENCES lpms3.baseline(id), wbs_node_id bigint NOT NULL,
  period_start date NOT NULL, granularity text NOT NULL CHECK (granularity IN ('WEEK','MONTH')),
  planned_weight numeric(12,9) NOT NULL, method text NOT NULL DEFAULT 'LINEAR' CHECK (method IN ('LINEAR','FRONT','BACK','MANUAL')),
  PRIMARY KEY (baseline_id, wbs_node_id, period_start, granularity));

-- ---------- Outbox sinkronisasi ke StarRocks ----------
CREATE TABLE IF NOT EXISTS lpms3.sync_outbox (
  id bigserial PRIMARY KEY, table_name text NOT NULL, row_pk text NOT NULL, op text NOT NULL CHECK (op IN ('UPSERT','DELETE')),
  created_at timestamptz NOT NULL DEFAULT now(), synced_at timestamptz, attempts integer NOT NULL DEFAULT 0, last_error text);
CREATE INDEX IF NOT EXISTS ix_sync_outbox_pending ON lpms3.sync_outbox(synced_at) WHERE synced_at IS NULL;
