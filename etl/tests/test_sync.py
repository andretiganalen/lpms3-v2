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
