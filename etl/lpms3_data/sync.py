"""Sinkron outbox lpms3.sync_outbox (PG) -> StarRocks (upsert tabel Primary Key; idempoten)."""
import datetime as dt
import decimal
import json
import logging
import re

from . import schema
from .mapping import SPECS, registry_spec

log = logging.getLogger("lpms3_data.sync")
MAX_ATTEMPTS = 10


def coerce(value, sr_type):
    """Ubah nilai PG (sering teks dari custom_values) ke tipe kolom StarRocks; gagal cast -> None."""
    if value is None or value == "":
        return None
    t = sr_type.lower()
    try:
        if t.startswith(("int", "bigint", "smallint", "tinyint", "largeint")):
            if isinstance(value, bool):
                return int(value)
            return int(decimal.Decimal(str(value)))
        if t.startswith(("decimal", "double", "float")):
            return decimal.Decimal(str(value))
        if t.startswith("boolean"):
            return value if isinstance(value, bool) else str(value).lower() in ("1", "t", "true")
        if t == "date":
            return value if isinstance(value, dt.date) else dt.date.fromisoformat(str(value)[:10])
        if t.startswith("datetime"):
            if isinstance(value, dt.datetime):
                return value.replace(tzinfo=None)
            return dt.datetime.fromisoformat(str(value).replace("Z", ""))
        if t.startswith("json"):
            return value if isinstance(value, str) else json.dumps(value, default=str)
        if isinstance(value, (list, dict)):
            return json.dumps(value, default=str)
        return str(value)
    except (ValueError, decimal.InvalidOperation, TypeError):
        log.warning("cast gagal %r -> %s", value, sr_type)
        return None


class Syncer:
    def __init__(self, pg, sr_factory):
        self.pg, self.sr_factory, self._sr, self._cols = pg, sr_factory, None, {}
        self.specs = dict(SPECS)
        self._warned = set()

    @property
    def sr(self):
        if self._sr is None:
            self._sr = self.sr_factory()
        return self._sr

    def _reset_sr(self):
        try:
            if self._sr is not None:
                self._sr.close()
        finally:
            self._sr = None

    def sr_columns(self, table):
        if table not in self._cols:
            with self.sr.cursor() as c:
                c.execute(f"DESCRIBE `{table}`")
                self._cols[table] = [(r[0], r[1]) for r in c.fetchall()]
        return self._cols[table]

    def _fetch(self, table, pk):
        spec = self.specs[table]
        parts = pk.split("|")
        if len(parts) != len(spec.pk_cols):
            raise ValueError(f"row_pk {pk!r} tidak cocok dengan pk {spec.pk_cols}")
        with self.pg.cursor() as c:
            c.execute(spec.sql, parts)
            row = c.fetchone()
            if row is None:
                return None
            return dict(zip([d.name for d in c.description], row))

    def _upsert(self, table, row):
        cols = self.sr_columns(table)
        names, vals = [], []
        for name, typ in cols:
            if name == "synced_at":
                continue
            if name in row:
                names.append(name)
                vals.append(coerce(row[name], typ))
        stamp = any(n == "synced_at" for n, _ in cols)  # tabel referensi lama (ref_*) tidak punya synced_at
        cols_sql = ",".join("`" + n + "`" for n in names + (["synced_at"] if stamp else []))
        sql = f"INSERT INTO `{table}` ({cols_sql}) VALUES ({','.join(['%s'] * len(names))}{', NOW()' if stamp else ''})"
        with self.sr.cursor() as c:
            c.execute(sql, vals)

    def _delete(self, table, pk):
        spec = self.specs[table]
        types = dict(self.sr_columns(table))
        where = " AND ".join(f"`{c}` = %s" for c in spec.pk_cols)
        args = [coerce(v, types[c]) for c, v in zip(spec.pk_cols, pk.split("|"))]
        with self.sr.cursor() as c:
            c.execute(f"DELETE FROM `{table}` WHERE {where}", args)

    def apply(self, table, pk, op):
        if table not in self.specs:
            raise KeyError(f"tabel tidak dikenal: {table}")
        row = self._fetch(table, pk) if op == "UPSERT" else None
        if row is None:
            self._delete(table, pk)
        else:
            self._upsert(table, row)

    def run_once(self, batch=200):
        """Proses satu batch outbox. Return jumlah entri outbox yang selesai."""
        done = 0
        with self.pg.transaction():
            with self.pg.cursor() as c:
                c.execute("SELECT id, table_name, row_pk, op FROM lpms3.sync_outbox "
                          "WHERE synced_at IS NULL AND attempts < %s ORDER BY id LIMIT %s FOR UPDATE SKIP LOCKED",
                          (MAX_ATTEMPTS, batch))
                rows = c.fetchall()
            groups = {}
            for oid, table, pk, op in rows:  # gabungkan: operasi terakhir per baris yang menang
                g = groups.setdefault((table, pk), {"ids": [], "op": op})
                g["ids"].append(oid)
                g["op"] = op
            for (table, pk), g in groups.items():
                try:
                    self.apply(table, pk, g["op"])
                    sql, args = ("UPDATE lpms3.sync_outbox SET synced_at = now(), last_error = NULL WHERE id = ANY(%s)", (g["ids"],))
                    done += len(g["ids"])
                except Exception as e:  # noqa: BLE001
                    log.error("gagal %s/%s: %s", table, pk, e)
                    if not isinstance(e, (KeyError, ValueError)):
                        self._reset_sr()
                    sql, args = ("UPDATE lpms3.sync_outbox SET attempts = attempts + 1, last_error = %s WHERE id = ANY(%s)",
                                 (str(e)[:500], g["ids"]))
                with self.pg.cursor() as c:
                    c.execute(sql, args)
        return done

    def reconcile(self):
        """Bandingkan jumlah baris PG vs StarRocks; selisih -> antrikan ulang tabel (sync_backfill) dan kembalikan daftar."""
        with self.pg.cursor() as c:
            c.execute("SELECT count(*) FROM lpms3.sync_outbox WHERE synced_at IS NULL AND attempts < %s", (MAX_ATTEMPTS,))
            if c.fetchone()[0]:
                return {}  # masih ada antrean: selisih sementara, tunda rekonsiliasi
        diff = {}
        for table, q in ((t, s.count_sql) for t, s in self.specs.items()):
            with self.pg.cursor() as c:
                c.execute(q)
                n_pg = c.fetchone()[0]
            with self.sr.cursor() as c:
                c.execute(f"SELECT count(*) FROM `{table}`")
                n_sr = c.fetchone()[0]
            if n_pg != n_sr:
                diff[table] = (n_pg, n_sr)
                log.warning("REKONSILIASI selisih %s: pg=%s sr=%s", table, n_pg, n_sr)
        if diff:
            with self.pg.transaction(), self.pg.cursor() as c:
                c.execute("SELECT lpms3.sync_backfill()")
        return diff

    # ---- registry: mirror semua tabel LPMS3 (db/070) ----
    def _registry(self):
        with self.pg.cursor() as c:
            c.execute("SELECT mirror, src_schema, src_table, pk_cols, aktif FROM lpms3.sync_registry ORDER BY mirror")
            return c.fetchall()

    def _pg_cols(self, sch, tbl):
        with self.pg.cursor() as c:
            c.execute(schema.PG_COLUMNS_SQL, (sch, tbl))
            return c.fetchall()

    def _sr_exists(self, mirror):
        with self.sr.cursor() as c:
            c.execute("SELECT count(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = %s",
                      (mirror,))
            return c.fetchone()[0] > 0

    def _warn_once(self, key, msg, *args):
        if key not in self._warned:
            self._warned.add(key)
            log.warning(msg, *args)

    def ensure_table(self, mirror, sch, tbl, pk_cols, replication="1"):
        """Pastikan tabel StarRocks ada & kolomnya lengkap. False bila belum ada dan tidak bisa dibuat (hak CREATE)."""
        pk = pk_cols.split(",")
        pg_cols = self._pg_cols(sch, tbl)
        try:
            if not self._sr_exists(mirror):
                with self.sr.cursor() as c:
                    c.execute(schema.create_ddl(mirror, pg_cols, pk, replication, f"mirror {sch}.{tbl}"))
                log.info("tabel StarRocks dibuat: %s (dari %s.%s)", mirror, sch, tbl)
                self._cols.pop(mirror, None)
                return True
            alter = schema.add_column_ddl(mirror, pg_cols, pk, [n for n, _ in self.sr_columns(mirror)])
            if alter:
                with self.sr.cursor() as c:
                    c.execute(alter)
                log.info("kolom StarRocks ditambah: %s", alter)
                self._cols.pop(mirror, None)
        except Exception as e:  # noqa: BLE001  (umumnya: lpms3_etl belum punya hak CREATE/ALTER)
            self._warn_once(("ddl", mirror), "DDL StarRocks %s belum bisa dijalankan: %s", mirror, str(e)[:200])
            self._cols.pop(mirror, None)
            return self._sr_exists(mirror)
        return True

    def refresh_registry(self, replication="1"):
        """Daftarkan tabel baru, buat tabel StarRocks, aktifkan mirror. Return daftar mirror yang baru aktif."""
        with self.pg.transaction(), self.pg.cursor() as c:
            c.execute("SELECT lpms3.sync_register_all()")
        activated = []
        for mirror, sch, tbl, pk_cols, aktif in self._registry():
            if mirror in ("project", "app_user"):
                continue
            ok = self.ensure_table(mirror, sch, tbl, pk_cols, replication)
            if not aktif and ok:
                with self.pg.transaction(), self.pg.cursor() as c:
                    c.execute("SELECT lpms3.sync_activate(%s)", (mirror,))
                    n = c.fetchone()[0]
                log.info("mirror aktif: %s.%s -> %s (%s baris diantrikan)", sch, tbl, mirror, n)
                aktif = True
                activated.append(mirror)
            if aktif:
                self.specs[mirror] = registry_spec(sch, tbl, pk_cols)
            else:
                self._warn_once(("wait", mirror), "mirror %s menunggu tabel StarRocks (jalankan db/starrocks/120)", mirror)
        return activated

    def missing_ddl(self, replication="1"):
        """DDL CREATE untuk mirror terdaftar yang tabel StarRocks-nya belum ada (untuk dijalankan admin)."""
        with self.pg.transaction(), self.pg.cursor() as c:
            c.execute("SELECT lpms3.sync_register_all()")
        out = []
        for mirror, sch, tbl, pk_cols, _ in self._registry():
            if mirror in ("project", "app_user"):
                continue
            pg_cols, pk = self._pg_cols(sch, tbl), pk_cols.split(",")
            if not self._sr_exists(mirror):
                out.append(schema.create_ddl(mirror, pg_cols, pk, replication, f"mirror {sch}.{tbl}") + ";")
            else:
                self._cols.pop(mirror, None)
                alter = schema.add_column_ddl(mirror, pg_cols, pk, [n for n, _ in self.sr_columns(mirror)])
                if alter:
                    out.append(alter + ";")
        return out
