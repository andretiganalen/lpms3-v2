-- 060: trigger outbox PG -> StarRocks (Master Plan §2). Idempoten.
-- Setiap perubahan baris sumber menulis lpms3.sync_outbox dalam transaksi yang sama.
-- row_pk: nilai kolom PK mirror digabung '|' (urutan sama dengan etl/lpms3_data/mapping.py).

CREATE OR REPLACE FUNCTION lpms3.fn_outbox() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE j jsonb; pk text; col text; parts text[] := '{}';
BEGIN
  j := to_jsonb(CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END);
  FOREACH col IN ARRAY string_to_array(TG_ARGV[1], ',') LOOP
    parts := parts || coalesce(j->>col, '');
  END LOOP;
  pk := array_to_string(parts, '|');
  INSERT INTO lpms3.sync_outbox(table_name, row_pk, op)
  VALUES (TG_ARGV[0], pk, CASE WHEN TG_OP = 'DELETE' THEN 'DELETE' ELSE 'UPSERT' END);
  RETURN NULL;
END $$;

-- custom value proyek -> baris project
CREATE OR REPLACE FUNCTION lpms3.fn_outbox_custom_value() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE r record;
BEGIN
  r := CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
  IF r.customized_type = 'Project' THEN
    INSERT INTO lpms3.sync_outbox(table_name, row_pk, op) VALUES ('project', r.customized_id::text, 'UPSERT');
  END IF;
  RETURN NULL;
END $$;

-- project_phases -> baris project (fase aktif)
CREATE OR REPLACE FUNCTION lpms3.fn_outbox_project_child() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE r record;
BEGIN
  r := CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
  INSERT INTO lpms3.sync_outbox(table_name, row_pk, op) VALUES ('project', r.project_id::text, 'UPSERT');
  RETURN NULL;
END $$;

DO $$
DECLARE t record;
BEGIN
  FOR t IN SELECT * FROM (VALUES
    ('public',  'projects',        'project',         'id'),
    ('public',  'users',           'app_user',        'id'),
    ('lpms3',   'org_structure',   'org_structure',   'id'),
    ('lpms3',   'org_unit',        'org_unit',        'id'),
    ('lpms3',   'fungsi_generik',  'fungsi_generik',  'id'),
    ('lpms3',   'fungsi_unit_map', 'fungsi_unit_map', 'id'),
    ('lpms3',   'position',        'position',        'id'),
    ('lpms3',   'user_position',   'user_position',   'id'),
    ('lpms3',   'project_unit',    'project_unit',    'project_id,unit_id,role'),
    ('lpms3',   'wbs_node',        'wbs_node',        'id'),
    ('lpms3',   'wbs_progress',    'wbs_progress',    'id'),
    ('lpms3',   'baseline',        'baseline',        'id'),
    ('lpms3',   'baseline_item',   'baseline_item',   'baseline_id,wbs_node_id'),
    ('lpms3',   'scurve_plan',     'scurve_plan',     'baseline_id,wbs_node_id,period_start,granularity')
  ) AS v(sch, tbl, mirror, pkcols) LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_lpms3_outbox ON %I.%I', t.sch, t.tbl);
    EXECUTE format('CREATE TRIGGER trg_lpms3_outbox AFTER INSERT OR UPDATE OR DELETE ON %I.%I
                    FOR EACH ROW EXECUTE FUNCTION lpms3.fn_outbox(%L, %L)', t.sch, t.tbl, t.mirror, t.pkcols);
  END LOOP;
END $$;

DROP TRIGGER IF EXISTS trg_lpms3_outbox_cv ON public.custom_values;
CREATE TRIGGER trg_lpms3_outbox_cv AFTER INSERT OR UPDATE OR DELETE ON public.custom_values
  FOR EACH ROW EXECUTE FUNCTION lpms3.fn_outbox_custom_value();
DROP TRIGGER IF EXISTS trg_lpms3_outbox_ph ON public.project_phases;
CREATE TRIGGER trg_lpms3_outbox_ph AFTER INSERT OR UPDATE OR DELETE ON public.project_phases
  FOR EACH ROW EXECUTE FUNCTION lpms3.fn_outbox_project_child();

-- Backfill: antrikan seluruh baris yang sudah ada (dipanggil sekali bila outbox kosong, atau manual untuk rebuild mirror)
CREATE OR REPLACE FUNCTION lpms3.sync_backfill() RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE n bigint := 0; c bigint;
BEGIN
  INSERT INTO lpms3.sync_outbox(table_name,row_pk,op) SELECT 'project', id::text, 'UPSERT' FROM public.projects;
  GET DIAGNOSTICS c = ROW_COUNT; n := n + c;
  INSERT INTO lpms3.sync_outbox(table_name,row_pk,op) SELECT 'app_user', id::text, 'UPSERT' FROM public.users WHERE type = 'User';
  GET DIAGNOSTICS c = ROW_COUNT; n := n + c;
  INSERT INTO lpms3.sync_outbox(table_name,row_pk,op) SELECT 'org_structure', id::text, 'UPSERT' FROM lpms3.org_structure;
  GET DIAGNOSTICS c = ROW_COUNT; n := n + c;
  INSERT INTO lpms3.sync_outbox(table_name,row_pk,op) SELECT 'org_unit', id::text, 'UPSERT' FROM lpms3.org_unit;
  GET DIAGNOSTICS c = ROW_COUNT; n := n + c;
  INSERT INTO lpms3.sync_outbox(table_name,row_pk,op) SELECT 'fungsi_generik', id::text, 'UPSERT' FROM lpms3.fungsi_generik;
  GET DIAGNOSTICS c = ROW_COUNT; n := n + c;
  INSERT INTO lpms3.sync_outbox(table_name,row_pk,op) SELECT 'fungsi_unit_map', id::text, 'UPSERT' FROM lpms3.fungsi_unit_map;
  GET DIAGNOSTICS c = ROW_COUNT; n := n + c;
  INSERT INTO lpms3.sync_outbox(table_name,row_pk,op) SELECT 'position', id::text, 'UPSERT' FROM lpms3."position";
  GET DIAGNOSTICS c = ROW_COUNT; n := n + c;
  INSERT INTO lpms3.sync_outbox(table_name,row_pk,op) SELECT 'user_position', id::text, 'UPSERT' FROM lpms3.user_position;
  GET DIAGNOSTICS c = ROW_COUNT; n := n + c;
  INSERT INTO lpms3.sync_outbox(table_name,row_pk,op) SELECT 'project_unit', project_id||'|'||unit_id||'|'||role, 'UPSERT' FROM lpms3.project_unit;
  GET DIAGNOSTICS c = ROW_COUNT; n := n + c;
  RETURN n;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM lpms3.sync_outbox) THEN PERFORM lpms3.sync_backfill(); END IF;
END $$;
