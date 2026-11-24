"""Pemetaan tabel mirror StarRocks -> sumber PostgreSQL.

`project` dan `app_user` berasal dari tabel inti OpenProject sehingga memakai SQL khusus (SPECS statis).
Semua tabel lain dibaca dari lpms3.sync_registry (db/070) lewat `registry_spec()`; GENERIC di bawah
hanya cadangan bila registry belum dipasang.
Urutan pk_cols HARUS sama dengan argumen trigger fn_outbox (db/060, db/070).
"""
from dataclasses import dataclass


@dataclass(frozen=True)
class Spec:
    pk_cols: tuple
    sql: str  # SELECT ... WHERE <pk expr>; parameter = list nilai pk (teks)
    count_sql: str = ""
    src: tuple = ()  # (schema, table) sumber PG; kosong untuk SQL khusus


def _cvx(name):
    """Ekspresi nilai custom field proyek (teks)."""
    return (f"(SELECT cv.value FROM custom_values cv JOIN custom_fields cf ON cf.id = cv.custom_field_id "
            f"WHERE cv.customized_type='Project' AND cv.customized_id=p.id AND cf.type='ProjectCustomField' "
            f"AND cf.name='{name}' AND cv.value <> '' LIMIT 1)")


def _cv(name, alias):
    return f"{_cvx(name)} AS {alias}"


PROJECT_SQL = f"""
SELECT p.id, p.identifier, p.name,
  {_cv('Kode Proyek', 'kode_proyek')},
  (SELECT j.code FROM lpms3.ref_jenis_kode j WHERE j.code = upper(split_part({_cvx('Kode Proyek')}, '-', 1))) AS jenis_kode,
  {_cv('Nomor Kontrak', 'nomor_kontrak')},
  {_cv('Nilai Kontrak (IDR)', 'nilai_kontrak')},
  NULL::text AS kelas_kontrak,
  {_cv('Nama Pelanggan', 'pelanggan')},
  (SELECT co.value FROM custom_options co WHERE co.id::text = {_cvx('Jenis/Klasifikasi Proyek')}) AS lini_bisnis,
  {_cv('Tanggal Kick-Off (Baseline 0)', 'tgl_mulai')},
  {_cv('Tanggal Selesai Kontrak', 'tgl_selesai')},
  {_cv('Pimpro', 'pimpro_user_id')},
  {_cv('Project Sponsor', 'sponsor_user_id')},
  (SELECT left(d.name, 20) FROM project_phases ph JOIN project_phase_definitions d ON d.id = ph.definition_id
    WHERE ph.project_id = p.id AND ph.active AND ph.start_date <= current_date
    ORDER BY d.position DESC LIMIT 1) AS current_phase,
  p.active, NOT p.active AS archived,
  {_cv('LPMS-2 Proyek ID', 'lpms2_project_id')}
FROM projects p WHERE p.id::text = %s
"""

APP_USER_SQL = """
SELECT u.id, u.login, u.firstname, u.lastname, u.mail, NULL::text AS nik, u.status, NULL::text AS sr_login
FROM users u WHERE u.type = 'User' AND u.id::text = %s
"""

SPECS = {
    "project": Spec(("id",), PROJECT_SQL, "SELECT count(*) FROM projects"),
    "app_user": Spec(("id",), APP_USER_SQL, "SELECT count(*) FROM users WHERE type = 'User'"),
}


def registry_spec(schema, table, pk_cols):
    pk = tuple(pk_cols.split(",")) if isinstance(pk_cols, str) else tuple(pk_cols)
    where = " AND ".join(f'"{c}"::text = %s' for c in pk)
    return Spec(pk, f'SELECT * FROM "{schema}"."{table}" WHERE {where}',
                f'SELECT count(*) FROM "{schema}"."{table}"', (schema, table))


# cadangan bila lpms3.sync_registry belum ada (nama sama di PG lpms3.<t> dan StarRocks)
GENERIC = {
    "org_structure": ("id",), "org_unit": ("id",), "fungsi_generik": ("id",), "fungsi_unit_map": ("id",),
    "position": ("id",), "user_position": ("id",), "project_unit": ("project_id", "unit_id", "role"),
    "wbs_node": ("id",), "wbs_progress": ("id",), "baseline": ("id",),
    "baseline_item": ("baseline_id", "wbs_node_id"),
    "scurve_plan": ("baseline_id", "wbs_node_id", "period_start", "granularity"),
}
for _t, _pk in GENERIC.items():
    SPECS[_t] = registry_spec("lpms3", _t, _pk)

# sumber hitung baris untuk rekonsiliasi (PG) — versi statis; Syncer memakai spec.count_sql
COUNT_SQL = {t: s.count_sql for t, s in SPECS.items()}
