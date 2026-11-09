-- LPMS3 · StarRocks · hak akses (dijalankan setelah semua tabel/view dibuat)
SET CATALOG default_catalog;
USE lpms3;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN DATABASE lpms3 TO ROLE lpms3_writer;
GRANT SELECT ON ALL VIEWS IN DATABASE lpms3 TO ROLE lpms3_writer;
GRANT SELECT ON ALL TABLES IN DATABASE lpms3 TO ROLE lpms3_reader;
GRANT SELECT ON ALL VIEWS IN DATABASE lpms3 TO ROLE lpms3_reader;
-- BI hanya view mart_* (tambahkan per view baru)
GRANT SELECT ON VIEW lpms3.mart_project_health TO ROLE lpms3_bi;
GRANT SELECT ON VIEW lpms3.mart_scurve_monthly TO ROLE lpms3_bi;
GRANT SELECT ON VIEW lpms3.mart_lkp_published TO ROLE lpms3_bi;
