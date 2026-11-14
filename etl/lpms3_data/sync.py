"""Sinkron outbox lpms3.sync_outbox (PG) -> StarRocks (upsert tabel Primary Key; idempoten)."""
import datetime as dt
import decimal
import json
import logging
import re

from .mapping import COUNT_SQL, SPECS

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
        return str(value)
    except (ValueError, decimal.InvalidOperation, TypeError):
        log.warning("cast gagal %r -> %s", value, sr_type)
        return None


class Syncer:
    def __init__(self, pg, sr_factory):
        self.pg, self.sr_factory, self._sr, self._cols = pg, sr_factory, None, {}

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
        spec = SPECS[table]
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
        names.append("synced_at")
        sql = f"INSERT INTO `{table}` ({','.join('`'+n+'`' for n in names)}) VALUES ({','.join(['%s']*(len(names)-1))}, NOW())"
        with self.sr.cursor() as c:
            c.execute(sql, vals)

    def _delete(self, table, pk):
        spec = SPECS[table]
        types = dict(self.sr_columns(table))
        where = " AND ".join(f"`{c}` = %s" for c in spec.pk_cols)
        args = [coerce(v, types[c]) for c, v in zip(spec.pk_cols, pk.split("|"))]
        with self.sr.cursor() as c:
            c.execute(f"DELETE FROM `{table}` WHERE {where}", args)

    def apply(self, table, pk, op):
        if table not in SPECS:
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
        for table, q in COUNT_SQL.items():
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
