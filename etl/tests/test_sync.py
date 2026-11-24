import datetime as dt
import decimal
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
from lpms3_data.sync import Syncer, coerce
from lpms3_data import mapping


def test_coerce():
    assert coerce("1500000000", "decimal(20,2)") == decimal.Decimal("1500000000")
    assert coerce("2026-11-01", "date") == dt.date(2026, 11, 1)
    assert coerce("12", "int") == 12
    assert coerce("abc", "int") is None
    assert coerce("", "varchar(10)") is None
    assert coerce("t", "boolean") is True


def test_specs_param_count():
    for t, s in mapping.SPECS.items():
        assert s.sql.count("%s") == len(s.pk_cols), t


class Cur:
    def __init__(self, db): self.db, self.rows, self.description = db, [], []
    def __enter__(self): return self
    def __exit__(self, *a): pass
    def execute(self, sql, args=None):
        self.db.log.append((sql, args))
        if sql.startswith("SELECT id, table_name"): self.rows = list(self.db.outbox)
        elif sql.startswith("DESCRIBE"): self.rows = self.db.desc
        elif "FROM projects" in sql:
            self.rows = [self.db.project] if self.db.project and args[0] == str(self.db.project[0]) else []
            self.description = [type("D", (), {"name": n}) for n in self.db.proj_cols]
        else: self.rows = []
    def fetchall(self): return self.rows
    def fetchone(self): return self.rows[0] if self.rows else None
    def close(self): pass


class Tx:
    def __enter__(self): return self
    def __exit__(self, *a): pass


class FakeDB:
    def __init__(self):
        self.log, self.outbox, self.project = [], [], None
        self.desc = [("id", "int"), ("name", "varchar(10)"), ("nilai_kontrak", "decimal(20,2)"), ("synced_at", "datetime")]
        self.proj_cols = ["id", "name", "nilai_kontrak", "extra"]
    def cursor(self): return Cur(self)
    def transaction(self): return Tx()
    def close(self): pass


def test_upsert_and_coalesce_and_delete():
    pg, sr = FakeDB(), FakeDB()
    pg.project = (6, "Demo", "1500000000", "x")
    pg.outbox = [(1, "project", "6", "UPSERT"), (2, "project", "6", "UPSERT"), (3, "project", "9", "UPSERT")]
    n = Syncer(pg, lambda: sr).run_once()
    assert n == 3
    inserts = [l for l in sr.log if l[0].startswith("INSERT")]
    assert len(inserts) == 1 and "`extra`" not in inserts[0][0] and inserts[0][1][0] == 6
    deletes = [l for l in sr.log if l[0].startswith("DELETE")]
    assert deletes and deletes[0][1] == [9]   # baris tak ada di PG -> hapus di mirror
    assert any("synced_at = now()" in l[0] and l[1][0] == [1, 2] for l in pg.log)


def test_unknown_table_counts_attempt():
    pg, sr = FakeDB(), FakeDB()
    pg.outbox = [(5, "nope", "1", "UPSERT")]
    assert Syncer(pg, lambda: sr).run_once() == 0
    assert any("attempts = attempts + 1" in l[0] for l in pg.log)


def test_sr_type_mapping():
    from lpms3_data.schema import sr_type
    assert sr_type("bigint") == "BIGINT" and sr_type("integer") == "INT" and sr_type("smallint") == "SMALLINT"
    assert sr_type("numeric(20,2)") == "DECIMAL(20,2)" and sr_type("numeric") == "DECIMAL(38,9)"
    assert sr_type("timestamp(6) with time zone") == "DATETIME" and sr_type("date") == "DATE"
    assert sr_type("jsonb") == "JSON" and sr_type("text[]") == "JSON" and sr_type("bigint[]") == "JSON"
    assert sr_type("character varying(30)") == "VARCHAR(120)" and sr_type("text") == "STRING"
    assert sr_type("text", is_pk=True) == "VARCHAR(128)"
    assert sr_type("tsvector") is None and sr_type("bytea") is None


def test_create_ddl_pk_first_and_synced_at():
    from lpms3_data.schema import create_ddl, add_column_ddl
    pg_cols = [("nama", "text"), ("project_id", "bigint"), ("fts", "tsvector"), ("role", "text")]
    ddl = create_ddl("project_unit_x", pg_cols, ["project_id", "role"], "3")
    body = ddl.split("(", 1)[1]
    assert body.index("`project_id`") < body.index("`role`") < body.index("`nama`")
    assert "`project_id` BIGINT NOT NULL" in ddl and "`role` VARCHAR(128) NOT NULL" in ddl
    assert "`fts`" not in ddl and "`synced_at` DATETIME" in ddl
    assert 'PRIMARY KEY(`project_id`, `role`)' in ddl and '"replication_num" = "3"' in ddl
    alter = add_column_ddl("t", pg_cols, ["project_id"], ["project_id", "nama", "synced_at"])
    assert alter == "ALTER TABLE `t` ADD COLUMN (`role` STRING)"
    assert add_column_ddl("t", pg_cols, ["project_id"], ["project_id", "nama", "role", "synced_at"]) is None


def test_registry_spec_and_coerce_list():
    s = mapping.registry_spec("lpms3_form", "form_definition", "code,rev")
    assert s.pk_cols == ("code", "rev") and s.sql.count("%s") == 2 and s.src == ("lpms3_form", "form_definition")
    assert coerce(["a", "b"], "varchar(65533)") == '["a", "b"]'
    assert coerce({"k": 1}, "json") == '{"k": 1}'


def test_upsert_without_synced_at_column():
    pg, sr = FakeDB(), FakeDB()
    sr.desc = [("id", "int"), ("name", "varchar(10)")]
    pg.project = (6, "Demo", "1", "x")
    pg.outbox = [(1, "project", "6", "UPSERT")]
    Syncer(pg, lambda: sr).run_once()
    ins = [l for l in sr.log if l[0].startswith("INSERT")][0]
    assert "synced_at" not in ins[0] and ins[0].endswith("VALUES (%s,%s)")
