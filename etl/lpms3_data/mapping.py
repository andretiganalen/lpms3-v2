"""Pemetaan tabel mirror StarRocks -> sumber PostgreSQL.

Tabel skema lpms3 yang namanya sama dipetakan generik (SELECT * lalu irisan kolom dengan StarRocks).
`project` dan `app_user` berasal dari tabel inti OpenProject sehingga memakai SQL khusus.
Urutan pk_cols HARUS sama dengan argumen trigger di db/060_lpms3_sync_triggers.sql.
"""
from dataclasses import dataclass


@dataclass(frozen=True)
class Spec:
    pk_cols: tuple
    sql: str  # SELECT ... WHERE <pk expr>; parameter = list nilai pk (teks)


def _cv(name, alias):
    return (f"(SELECT cv.value FROM custom_values cv JOIN custom_fields cf ON cf.id = cv.custom_field_id "
            f"WHERE cv.customized_type='Project' AND cv.customized_id=p.id AND cf.type='ProjectCustomField' "
            f"AND cf.name='{name}' LIMIT 1) AS {alias}")


PROJECT_SQL = f"""
SELECT p.id, p.identifier, p.name,
  {_cv('Kode Proyek', 'kode_proyek')},
  NULL::text AS jenis_kode,
  {_cv('Nomor Kontrak', 'nomor_kontrak')},
  {_cv('Nilai Kontrak (IDR)', 'nilai_kontrak')},
  NULL::text AS kelas_kontrak,
  {_cv('Nama Pelanggan', 'pelanggan')},
  NULL::text AS lini_bisnis,
  {_cv('Tanggal Kick-Off (Baseline 0)', 'tgl_mulai')},
  {_cv('Tanggal Selesai Kontrak', 'tgl_selesai')},
  {_cv('Pimpro', 'pimpro_user_id')},
  {_cv('Project Sponsor', 'sponsor_user_id')},
  NULL::text AS current_phase,
  p.active, NOT p.active AS archived,
  NULL::text AS lpms2_project_id
FROM projects p WHERE p.id::text = %s
"""

APP_USER_SQL = """
SELECT u.id, u.login, u.firstname, u.lastname, u.mail, NULL::text AS nik, u.status, NULL::text AS sr_login
FROM users u WHERE u.type = 'User' AND u.id::text = %s
"""

SPECS = {
    "project": Spec(("id",), PROJECT_SQL),
    "app_user": Spec(("id",), APP_USER_SQL),
}

# tabel skema lpms3: nama sama di PG (lpms3.<t>) dan StarRocks
GENERIC = {
    "org_structure": ("id",), "org_unit": ("id",), "fungsi_generik": ("id",), "fungsi_unit_map": ("id",),
    "position": ("id",), "user_position": ("id",), "project_unit": ("project_id", "unit_id", "role"),
    "wbs_node": ("id",), "wbs_progress": ("id",), "baseline": ("id",),
    "baseline_item": ("baseline_id", "wbs_node_id"),
    "scurve_plan": ("baseline_id", "wbs_node_id", "period_start", "granularity"),
}
for _t, _pk in GENERIC.items():
    _where = " AND ".join(f"{c}::text = %s" for c in _pk)
    SPECS[_t] = Spec(_pk, f'SELECT * FROM lpms3."{_t}" WHERE {_where}')

# sumber hitung baris untuk rekonsiliasi (PG)
COUNT_SQL = {
    "project": "SELECT count(*) FROM projects",
    "app_user": "SELECT count(*) FROM users WHERE type = 'User'",
    **{t: f'SELECT count(*) FROM lpms3."{t}"' for t in GENERIC},
}
