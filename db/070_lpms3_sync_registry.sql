-- 070: mirror SEMUA tabel LPMS3 ke StarRocks lewat registry (idempoten).
-- PostgreSQL tetap system of entry (OpenProject tidak bisa berjalan di StarRocks); setiap tabel
-- skema lpms3, lpms3_form, tabel plugin public.lpms3_* dan tabel domain OpenProject terpilih
-- didaftarkan otomatis, lalu diaktifkan oleh lpms3-data begitu tabel StarRocks-nya tersedia.
--
-- Nama mirror:  lpms3.<t> -> <t> · lpms3_form.<t> -> form_<t> · public.lpms3_<t> -> lpms3_<t> · public.<t> -> op_<t>
-- Alur: lpms3-data memanggil sync_register_all() berkala -> membuat tabel StarRocks (atau menunggu
-- admin menjalankan db/starrocks/120_lpms3_auto_mirror.sql) -> sync_activate(mirror) = pasang trigger
-- outbox + antrikan semua baris dalam satu transaksi.

CREATE TABLE IF NOT EXISTS lpms3.sync_registry (
  mirror        text PRIMARY KEY,
  src_schema    text NOT NULL,
  src_table     text NOT NULL,
  pk_cols       text NOT NULL,            -- urutan = argumen trigger fn_outbox
  aktif         boolean NOT NULL DEFAULT false,
  registered_at timestamptz NOT NULL DEFAULT now(),
  activated_at  timestamptz,
  UNIQUE (src_schema, src_table)
);

-- Tabel inti OpenProject yang memuat data domain LPMS3 (Risiko, CR, NCR, Deliverable, dll. = work package).
-- projects & users TIDAK di sini: dimirror khusus sebagai `project` dan `app_user` (060).
CREATE OR REPLACE FUNCTION lpms3.sync_op_tables() RETURNS text[] LANGUAGE sql IMMUTABLE AS $$
  SELECT ARRAY['work_packages','types','statuses','enumerations','custom_fields','custom_options','custom_values',
               'attachments','members','member_roles','roles','project_phases','project_phase_definitions',
               'versions','categories']
$$;

-- 14 tabel yang sudah dimirror 060 (trigger sudah terpasang) -> langsung aktif.
INSERT INTO lpms3.sync_registry(mirror, src_schema, src_table, pk_cols, aktif, activated_at) VALUES
  ('org_structure',   'lpms3', 'org_structure',   'id', true, now()),
  ('org_unit',        'lpms3', 'org_unit',        'id', true, now()),
  ('fungsi_generik',  'lpms3', 'fungsi_generik',  'id', true, now()),
  ('fungsi_unit_map', 'lpms3', 'fungsi_unit_map', 'id', true, now()),
  ('position',        'lpms3', 'position',        'id', true, now()),
  ('user_position',   'lpms3', 'user_position',   'id', true, now()),
  ('project_unit',    'lpms3', 'project_unit',    'project_id,unit_id,role', true, now()),
  ('wbs_node',        'lpms3', 'wbs_node',        'id', true, now()),
  ('wbs_progress',    'lpms3', 'wbs_progress',    'id', true, now()),
  ('baseline',        'lpms3', 'baseline',        'id', true, now()),
  ('baseline_item',   'lpms3', 'baseline_item',   'baseline_id,wbs_node_id', true, now()),
  ('scurve_plan',     'lpms3', 'scurve_plan',     'baseline_id,wbs_node_id,period_start,granularity', true, now())
ON CONFLICT DO NOTHING;

-- Daftarkan semua tabel ber-PK yang belum terdaftar. Return jumlah tabel baru.
CREATE OR REPLACE FUNCTION lpms3.sync_register_all() RETURNS integer LANGUAGE plpgsql AS $$
DECLARE n integer;
BEGIN
  INSERT INTO lpms3.sync_registry(mirror, src_schema, src_table, pk_cols)
  SELECT CASE
           WHEN ns.nspname = 'lpms3' THEN c.relname
           WHEN ns.nspname = 'lpms3_form' THEN CASE WHEN c.relname LIKE 'form\_%' THEN c.relname ELSE 'form_' || c.relname END
           WHEN c.relname LIKE 'lpms3\_%' THEN c.relname
           ELSE 'op_' || c.relname
         END,
         ns.nspname, c.relname,
         (SELECT string_agg(a.attname, ',' ORDER BY k.ord)
            FROM pg_index i
            CROSS JOIN LATERAL unnest(i.indkey::int2[]) WITH ORDINALITY AS k(attnum, ord)
            JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = k.attnum
           WHERE i.indrelid = c.oid AND i.indisprimary)
    FROM pg_class c
    JOIN pg_namespace ns ON ns.oid = c.relnamespace
   WHERE c.relkind IN ('r', 'p') AND NOT c.relispartition
     AND (ns.nspname IN ('lpms3', 'lpms3_form')
          OR (ns.nspname = 'public' AND (c.relname LIKE 'lpms3\_%' OR c.relname = ANY (lpms3.sync_op_tables()))))
     AND NOT (ns.nspname = 'lpms3' AND c.relname IN ('sync_outbox', 'sync_registry'))
     AND EXISTS (SELECT 1 FROM pg_index i WHERE i.indrelid = c.oid AND i.indisprimary)
  ON CONFLICT DO NOTHING;
  GET DIAGNOSTICS n = ROW_COUNT;
  RETURN n;
END $$;

-- Antrikan seluruh baris satu mirror. row_pk dibentuk sama dengan fn_outbox (060).
CREATE OR REPLACE FUNCTION lpms3.sync_enqueue_all(p_mirror text) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE r lpms3.sync_registry; pkexpr text; n bigint;
BEGIN
  SELECT * INTO r FROM lpms3.sync_registry WHERE mirror = p_mirror;
  IF NOT FOUND THEN RAISE EXCEPTION 'mirror % tidak terdaftar di lpms3.sync_registry', p_mirror; END IF;
  SELECT string_agg(format('coalesce(to_jsonb(t)->>%L, %L)', col, ''), ' || ''|'' || ')
    INTO pkexpr FROM unnest(string_to_array(r.pk_cols, ',')) AS col;
  EXECUTE format('INSERT INTO lpms3.sync_outbox(table_name, row_pk, op) SELECT %L, %s, %L FROM %I.%I t',
                 r.mirror, pkexpr, 'UPSERT', r.src_schema, r.src_table);
  GET DIAGNOSTICS n = ROW_COUNT;
  RETURN n;
END $$;

-- Aktifkan mirror: pasang trigger outbox + antrikan seluruh baris (satu transaksi, tidak ada perubahan yang lolos).
CREATE OR REPLACE FUNCTION lpms3.sync_activate(p_mirror text) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE r lpms3.sync_registry; n bigint;
BEGIN
  SELECT * INTO r FROM lpms3.sync_registry WHERE mirror = p_mirror FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'mirror % tidak terdaftar di lpms3.sync_registry', p_mirror; END IF;
  EXECUTE format('DROP TRIGGER IF EXISTS trg_lpms3_outbox ON %I.%I', r.src_schema, r.src_table);
  EXECUTE format('CREATE TRIGGER trg_lpms3_outbox AFTER INSERT OR UPDATE OR DELETE ON %I.%I
                  FOR EACH ROW EXECUTE FUNCTION lpms3.fn_outbox(%L, %L)', r.src_schema, r.src_table, r.mirror, r.pk_cols);
  n := lpms3.sync_enqueue_all(p_mirror);
  UPDATE lpms3.sync_registry SET aktif = true, activated_at = now() WHERE mirror = p_mirror;
  RETURN n;
END $$;

-- Backfill (rebuild mirror / rekonsiliasi): project, app_user, lalu semua mirror aktif di registry.
-- Menggantikan versi 060 yang hanya mencakup 9 tabel (wbs_*, baseline*, scurve_plan terlewat).
CREATE OR REPLACE FUNCTION lpms3.sync_backfill() RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE n bigint := 0; c bigint; m text;
BEGIN
  INSERT INTO lpms3.sync_outbox(table_name,row_pk,op) SELECT 'project', id::text, 'UPSERT' FROM public.projects;
  GET DIAGNOSTICS c = ROW_COUNT; n := n + c;
  INSERT INTO lpms3.sync_outbox(table_name,row_pk,op) SELECT 'app_user', id::text, 'UPSERT' FROM public.users WHERE type = 'User';
  GET DIAGNOSTICS c = ROW_COUNT; n := n + c;
  FOR m IN SELECT mirror FROM lpms3.sync_registry WHERE aktif ORDER BY mirror LOOP
    n := n + lpms3.sync_enqueue_all(m);
  END LOOP;
  RETURN n;
END $$;

SELECT lpms3.sync_register_all();
