-- =====================================================================
-- LPMS3 · StarRocks · inisialisasi database utama default_catalog.lpms3
-- Target  : 192.168.125.29:9030 (FE MySQL protocol). JDBC: jdbc:mysql://192.168.125.29:9030/lpms3
-- Jalankan: ops/starrocks_apply.sh (mengganti ${...} dari .env — JANGAN commit password)
-- =====================================================================
SET CATALOG default_catalog;
CREATE DATABASE IF NOT EXISTS lpms3 COMMENT 'LPMS3 main data store (BOP-001)';
USE lpms3;

-- Role dengan hak minimum ------------------------------------------------
CREATE ROLE IF NOT EXISTS lpms3_writer;   -- aplikasi & layanan sinkron/ETL
CREATE ROLE IF NOT EXISTS lpms3_reader;   -- dashboard aplikasi
CREATE ROLE IF NOT EXISTS lpms3_bi;       -- alat BI: hanya view mart_* (terfilter visibilitas)

-- Pengguna (password dari .env, bukan root untuk aplikasi) ---------------
CREATE USER IF NOT EXISTS 'lpms3_app'@'%' IDENTIFIED BY '${STARROCKS_APP_PASSWORD}' DEFAULT ROLE 'lpms3_writer';
CREATE USER IF NOT EXISTS 'lpms3_etl'@'%' IDENTIFIED BY '${STARROCKS_ETL_PASSWORD}' DEFAULT ROLE 'lpms3_writer';
CREATE USER IF NOT EXISTS 'lpms3_bi'@'%'  IDENTIFIED BY '${STARROCKS_BI_PASSWORD}'  DEFAULT ROLE 'lpms3_bi';

GRANT USAGE ON CATALOG default_catalog TO ROLE lpms3_writer;
GRANT USAGE ON CATALOG default_catalog TO ROLE lpms3_reader;
GRANT USAGE ON CATALOG default_catalog TO ROLE lpms3_bi;
-- Hak tabel diberikan oleh 990_grants.sql setelah seluruh tabel & view dibuat.
