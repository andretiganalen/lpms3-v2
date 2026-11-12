-- =====================================================================
-- LPMS3 · StarRocks · mart untuk Dashboard, Project Health, Kurva-S
-- Aplikasi membaca mart_* dengan filter visibilitas di layanan (user_id).
-- Alat BI (role lpms3_bi) hanya diberi view agregat mart_* tanpa data mentah.
-- =====================================================================
SET CATALOG default_catalog;
USE ${STARROCKS_DATABASE};

-- Kurva-S rencana (dari baseline aktif) vs realisasi (wbs_progress) per proyek per bulan
CREATE VIEW IF NOT EXISTS mart_scurve_monthly AS
WITH plan AS (
  SELECT b.project_id, sp.period_start, SUM(sp.planned_weight) AS planned
  FROM scurve_plan sp JOIN baseline b ON b.id = sp.baseline_id AND b.is_active
  WHERE sp.granularity = 'MONTH' GROUP BY b.project_id, sp.period_start),
act AS (
  SELECT n.project_id, p.period_month AS period_start, SUM(n.weight * p.pct_complete) AS actual_cum
  FROM wbs_progress p JOIN wbs_node n ON n.id = p.wbs_node_id AND n.is_activity
  WHERE p.verified_at IS NOT NULL
  GROUP BY n.project_id, p.period_month)
SELECT pl.project_id, pl.period_start,
       SUM(pl.planned) OVER (PARTITION BY pl.project_id ORDER BY pl.period_start) * 100 AS rencana_kum_pct,
       a.actual_cum * 100 AS realisasi_kum_pct
FROM plan pl LEFT JOIN act a ON a.project_id = pl.project_id AND a.period_start = pl.period_start;

-- LKP terbaru yang sudah PUBLISHED pada level tertentu (dipakai untuk visibilitas berjenjang)
CREATE VIEW IF NOT EXISTS mart_lkp_published AS
SELECT st.submission_id, st.project_id, st.period_month, st.published_level, t.rep_rencana_kum, t.rep_prestasi_kum, t.rep_deviasi,
       CASE WHEN t.rep_rencana_kum > 0 THEN t.rep_prestasi_kum / t.rep_rencana_kum END AS spi_progress
FROM v_lkp_status st JOIN lkp_total t ON t.submission_id = st.submission_id
WHERE st.is_current;

-- Ringkasan kesehatan proyek (jadwal dari LKP published + risiko tinggi + ketidaksesuaian terbuka)
CREATE VIEW IF NOT EXISTS mart_project_health AS
SELECT p.id AS project_id, p.kode_proyek, p.name, p.current_phase, p.tgl_selesai,
       l.period_month AS lkp_period, l.published_level, l.rep_rencana_kum, l.rep_prestasi_kum, l.rep_deviasi, l.spi_progress,
       CASE WHEN l.spi_progress IS NULL THEN 'GREY' WHEN l.spi_progress >= 0.95 THEN 'GREEN'
            WHEN l.spi_progress >= 0.90 THEN 'AMBER' ELSE 'RED' END AS rag_jadwal,
       COALESCE(r.n, 0) AS risiko_tinggi_terbuka,
       COALESCE(c.n, 0) AS ketidaksesuaian_terbuka
FROM project p
LEFT JOIN (SELECT * FROM (SELECT m.*, ROW_NUMBER() OVER (PARTITION BY m.project_id ORDER BY m.period_month DESC) AS rn
                          FROM mart_lkp_published m) x WHERE x.rn = 1) l ON l.project_id = p.id
LEFT JOIN (SELECT fi.project_id, COUNT(*) AS n FROM form_rfr002_risiko rr JOIN form_instance fi ON fi.id = rr.form_instance_id
           WHERE fi.is_current AND rr.inheren_level IN ('Menengah-Tinggi (16-19)', 'Tinggi (20-25)')
             AND (rr.kejadian_risiko IS NULL OR rr.kejadian_risiko <> 'Terjadi')
           GROUP BY fi.project_id) r ON r.project_id = p.id
LEFT JOIN (SELECT fi.project_id, COUNT(*) AS n FROM form_cfr027_ketidaksesuaian cc JOIN form_instance fi ON fi.id = cc.form_instance_id
           WHERE cc.status <> 'OK' GROUP BY fi.project_id) c ON c.project_id = p.id
WHERE p.active;
