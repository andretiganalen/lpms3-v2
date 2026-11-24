"""Bangkitkan DDL StarRocks dari katalog PostgreSQL untuk tabel di lpms3.sync_registry."""
import re

# tipe yang tidak dimirror (tidak bermakna di analitik / tidak didukung)
SKIP_TYPES = ("tsvector", "bytea", "oid")

PG_COLUMNS_SQL = """
SELECT a.attname, format_type(a.atttypid, a.atttypmod)
  FROM pg_attribute a
 WHERE a.attrelid = format('%%I.%%I', %s::text, %s::text)::regclass AND a.attnum > 0 AND NOT a.attisdropped
 ORDER BY a.attnum
"""


def sr_type(pg_type, is_pk=False):
    """Peta tipe PostgreSQL -> tipe kolom StarRocks. None = kolom dilewati."""
    t = pg_type.lower()
    if t.startswith(SKIP_TYPES):
        return None
    if t.endswith("[]"):
        return "JSON"
    if t == "smallint":
        return "SMALLINT"
    if t == "integer":
        return "INT"
    if t == "bigint":
        return "BIGINT"
    m = re.fullmatch(r"numeric\((\d+),(\d+)\)", t)
    if m:
        p, s = int(m[1]), int(m[2])
        return f"DECIMAL({min(p, 38)},{min(s, 38)})"
    if t == "numeric":
        return "DECIMAL(38,9)"
    if t in ("double precision", "real"):
        return "DOUBLE"
    if t == "boolean":
        return "BOOLEAN"
    if t == "date":
        return "DATE"
    if t.startswith("timestamp"):
        return "DATETIME"
    if t in ("json", "jsonb"):
        return "VARCHAR(64)" if is_pk else "JSON"
    m = re.fullmatch(r"(?:character varying|character)\((\d+)\)", t)
    if m:  # panjang StarRocks dalam byte; UTF-8 sampai 4 byte/karakter
        return f"VARCHAR({min(int(m[1]) * 4, 128 if is_pk else 65533)})"
    return "VARCHAR(128)" if is_pk else "STRING"


def columns(pg_cols, pk_cols):
    """[(nama, tipe_sr)] dengan kolom PK di depan (syarat tabel Primary Key StarRocks) + synced_at."""
    types = dict(pg_cols)
    out = [(c, sr_type(types[c], True)) for c in pk_cols]
    out += [(c, s) for c, t in pg_cols if c not in pk_cols and c != "synced_at" and (s := sr_type(t)) is not None]
    return out + [("synced_at", "DATETIME")]


def create_ddl(mirror, pg_cols, pk_cols, replication="1", comment=""):
    cols = columns(pg_cols, pk_cols)
    body = ",\n".join(f"  `{c}` {t}{' NOT NULL' if c in pk_cols else ''}" for c, t in cols)
    pk = ", ".join(f"`{c}`" for c in pk_cols)
    cmt = f" COMMENT \"{comment}\"" if comment else ""
    return (f"CREATE TABLE IF NOT EXISTS `{mirror}` (\n{body}\n) PRIMARY KEY({pk}){cmt}\n"
            f"DISTRIBUTED BY HASH(`{pk_cols[0]}`)\n"
            f"PROPERTIES (\"replication_num\" = \"{replication}\", \"enable_persistent_index\" = \"true\")")


def add_column_ddl(mirror, pg_cols, pk_cols, existing):
    """Satu ALTER (StarRocks menolak schema change paralel) untuk kolom PG yang belum ada; None bila lengkap."""
    have = {c.lower() for c in existing}
    add = [f"`{c}` {t}" for c, t in columns(pg_cols, pk_cols) if c.lower() not in have and c not in pk_cols]
    return f"ALTER TABLE `{mirror}` ADD COLUMN ({', '.join(add)})" if add else None
