-- LPMS3 · StarRocks · tabel mirror otomatis (db/070 lpms3.sync_registry). DIBANGKITKAN — jangan diedit manual.
-- Bangkitkan ulang: docker exec lpms3v2-lpms3-data-1 python -m lpms3_data ddl > db/starrocks/120_lpms3_auto_mirror.sql (lalu tambahkan header ini)
-- Dijalankan admin lewat ops/starrocks_apply.sh (root), lalu 990_grants.sql.
SET CATALOG default_catalog;
USE ${STARROCKS_DATABASE};

ALTER TABLE `baseline` ADD COLUMN (`created_at` DATETIME, `status` STRING, `created_by` INT, `change_summary` STRING, `updated_at` DATETIME);

ALTER TABLE `baseline_item` ADD COLUMN (`parent_wbs_node_id` BIGINT, `weigh_factor` DECIMAL(9,6), `sort_order` INT, `is_frozen` BOOLEAN);

CREATE TABLE IF NOT EXISTS `capability` (
  `code` VARCHAR(128) NOT NULL,
  `name` STRING,
  `module` STRING,
  `description` STRING,
  `synced_at` DATETIME
) PRIMARY KEY(`code`) COMMENT "mirror lpms3.capability"
DISTRIBUTED BY HASH(`code`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `capability_exception` (
  `id` INT NOT NULL,
  `user_id` INT,
  `capability_code` STRING,
  `project_id` INT,
  `unit_id` INT,
  `allow` BOOLEAN,
  `reason` STRING,
  `valid_until` DATE,
  `approved_by` INT,
  `created_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror lpms3.capability_exception"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `capability_rule` (
  `id` INT NOT NULL,
  `fungsi_id` INT,
  `position_grade` STRING,
  `project_role` STRING,
  `scope` STRING,
  `capability_code` STRING,
  `allow` BOOLEAN,
  `info_access` STRING,
  `updated_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror lpms3.capability_rule"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

ALTER TABLE `form_definition` ADD COLUMN (`synced_at` DATETIME);

ALTER TABLE `fungsi_generik` ADD COLUMN (`definition` STRING, `updated_at` DATETIME, `induk_id` INT, `sumber_dok` STRING);

ALTER TABLE `fungsi_unit_map` ADD COLUMN (`updated_at` DATETIME, `fungsi_lama_id` INT, `lingkup` STRING, `catatan` STRING);

CREATE TABLE IF NOT EXISTS `kontrak` (
  `project_id` INT NOT NULL,
  `nilai_awal` DECIMAL(20,2),
  `tanggal_selesai_awal` DATE,
  `tanggal_mulai` DATE,
  `posisi_len` STRING,
  `term_of_payment` STRING,
  `go_nogo` STRING,
  `go_nogo_tanggal` DATE,
  `go_nogo_nomor` STRING,
  `catatan` STRING,
  `updated_by` INT,
  `updated_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`project_id`) COMMENT "mirror lpms3.kontrak"
DISTRIBUTED BY HASH(`project_id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `kontrak_adendum` (
  `id` BIGINT NOT NULL,
  `project_id` INT,
  `urutan` INT,
  `nomor_dokumen` STRING,
  `tanggal` DATE,
  `uraian` STRING,
  `nilai_baru` DECIMAL(20,2),
  `tanggal_selesai_baru` DATE,
  `lingkup` BOOLEAN,
  `sfr025_nomor` STRING,
  `change_request_id` INT,
  `nilai_sebelum` DECIMAL(20,2),
  `tanggal_selesai_sebelum` DATE,
  `status` STRING,
  `created_by` INT,
  `disahkan_by` INT,
  `disahkan_at` DATETIME,
  `updated_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror lpms3.kontrak_adendum"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `kontrak_jaminan` (
  `id` BIGINT NOT NULL,
  `project_id` INT,
  `jenis` STRING,
  `nomor` STRING,
  `penerbit` STRING,
  `nilai` DECIMAL(20,2),
  `persen` DECIMAL(5,2),
  `berlaku_dari` DATE,
  `berlaku_sampai` DATE,
  `status` STRING,
  `catatan` STRING,
  `created_by` INT,
  `updated_by` INT,
  `updated_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror lpms3.kontrak_jaminan"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `kontrak_termin` (
  `id` BIGINT NOT NULL,
  `project_id` INT,
  `urutan` INT,
  `uraian` STRING,
  `persen` DECIMAL(6,3),
  `syarat` STRING,
  `syarat_progres` DECIMAL(6,3),
  `syarat_wbs_node_id` BIGINT,
  `rencana_tanggal` DATE,
  `status` STRING,
  `tanggal_tagih` DATE,
  `nomor_tagihan` STRING,
  `tanggal_bayar` DATE,
  `nilai_bayar` DECIMAL(20,2),
  `catatan` STRING,
  `created_by` INT,
  `updated_by` INT,
  `updated_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror lpms3.kontrak_termin"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `lpms3_approval_tasks` (
  `id` BIGINT NOT NULL,
  `work_package_id` BIGINT,
  `project_id` BIGINT,
  `stage` STRING,
  `state` STRING,
  `requested_by_id` BIGINT,
  `requested_at` DATETIME,
  `requester_note` STRING,
  `decided_by_id` BIGINT,
  `decided_at` DATETIME,
  `decision_note` STRING,
  `bypassed` BOOLEAN,
  `lock_version` INT,
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `tembusan_at` DATETIME,
  `tembusan_by_id` BIGINT,
  `jalur` VARCHAR(40),
  `unit_es2_id` INT,
  `unit_es1_id` INT,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.lpms3_approval_tasks"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `lpms3_auto_members` (
  `id` BIGINT NOT NULL,
  `project_id` BIGINT,
  `user_id` BIGINT,
  `role_name` STRING,
  `alasan` STRING,
  `created_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.lpms3_auto_members"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `lpms3_currencies` (
  `id` BIGINT NOT NULL,
  `code` VARCHAR(12),
  `name` STRING,
  `symbol` STRING,
  `minor_units` INT,
  `active` BOOLEAN,
  `is_base` BOOLEAN,
  `position` INT,
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.lpms3_currencies"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `lpms3_daily_reports` (
  `id` BIGINT NOT NULL,
  `work_package_id` BIGINT,
  `report_date` DATE,
  `progress` DECIMAL(5,1),
  `prev_progress` DECIMAL(5,1),
  `execution` STRING,
  `keterangan` STRING,
  `kendala` STRING,
  `status` STRING,
  `sent_at` DATETIME,
  `author_id` BIGINT,
  `photo_ids` JSON,
  `lock_version` INT,
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.lpms3_daily_reports"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `lpms3_exchange_rates` (
  `id` BIGINT NOT NULL,
  `currency_code` VARCHAR(12),
  `rate` DECIMAL(24,8),
  `valid_on` DATE,
  `source` STRING,
  `note` STRING,
  `created_by_id` BIGINT,
  `created_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.lpms3_exchange_rates"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `lpms3_feedbacks` (
  `id` BIGINT NOT NULL,
  `work_package_id` BIGINT,
  `project_id` BIGINT,
  `given_by_id` BIGINT,
  `author_id` BIGINT,
  `body` STRING,
  `state` STRING,
  `given_at` DATETIME,
  `resolved_by_id` BIGINT,
  `resolved_at` DATETIME,
  `resolution_note` STRING,
  `lock_version` INT,
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.lpms3_feedbacks"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `lpms3_kickoffs` (
  `id` BIGINT NOT NULL,
  `project_id` BIGINT,
  `state` STRING,
  `assigned_by_id` BIGINT,
  `assigned_at` DATETIME,
  `analis_id` BIGINT,
  `invited_by_id` BIGINT,
  `invited_at` DATETIME,
  `scheduled_at` DATETIME,
  `agenda` STRING,
  `invitees` JSON,
  `lock_version` INT,
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.lpms3_kickoffs"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `lpms3_member_requests` (
  `id` BIGINT NOT NULL,
  `project_id` INT,
  `user_id` INT,
  `role_ids` JSON,
  `requested_by` INT,
  `requested_at` DATETIME,
  `state` VARCHAR(48),
  `decided_by` INT,
  `decided_at` DATETIME,
  `note` STRING,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.lpms3_member_requests"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `lpms3_project_trigger_events` (
  `id` BIGINT NOT NULL,
  `project_trigger_id` BIGINT,
  `kind` STRING,
  `from_status` STRING,
  `to_status` STRING,
  `actor_id` BIGINT,
  `sumber` STRING,
  `note` STRING,
  `created_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.lpms3_project_trigger_events"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `lpms3_project_triggers` (
  `id` BIGINT NOT NULL,
  `kode_proyek` STRING,
  `lpms2_proyek_id` BIGINT,
  `status` STRING,
  `id_kiriman_terakhir` STRING,
  `jumlah_kiriman` INT,
  `diterima_pada` DATETIME,
  `kiriman_terakhir_pada` DATETIME,
  `dikirim_pada` DATETIME,
  `nota` JSON,
  `diklaim_pada` DATETIME,
  `snapshot` JSON,
  `snapshot_pada` DATETIME,
  `snapshot_galat` STRING,
  `template_identifier` STRING,
  `pimpro_id` BIGINT,
  `vp_id` BIGINT,
  `diusulkan_oleh_id` BIGINT,
  `diusulkan_pada` DATETIME,
  `diputus_oleh_id` BIGINT,
  `diputus_pada` DATETIME,
  `catatan_keputusan` STRING,
  `project_id` BIGINT,
  `lock_version` INT,
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `nama_proyek` STRING,
  `kode_proyek_lpms3` STRING,
  `catatan_usulan` STRING,
  `pembuatan_galat` STRING,
  `pembuatan_dicoba_pada` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.lpms3_project_triggers"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `lpms3_wo_reviews` (
  `id` BIGINT NOT NULL,
  `work_package_id` BIGINT,
  `state` STRING,
  `submitted_at` DATETIME,
  `decided_at` DATETIME,
  `decided_by_id` BIGINT,
  `reject_reason` STRING,
  `lock_version` INT,
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.lpms3_wo_reviews"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `op_attachments` (
  `id` BIGINT NOT NULL,
  `container_id` BIGINT,
  `container_type` VARCHAR(120),
  `filename` STRING,
  `disk_filename` STRING,
  `filesize` BIGINT,
  `content_type` STRING,
  `digest` VARCHAR(160),
  `downloads` INT,
  `author_id` BIGINT,
  `created_at` DATETIME,
  `description` STRING,
  `file` STRING,
  `fulltext` STRING,
  `updated_at` DATETIME,
  `status` INT,
  `charset` STRING,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.attachments"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `op_categories` (
  `id` BIGINT NOT NULL,
  `project_id` BIGINT,
  `name` STRING,
  `assigned_to_id` BIGINT,
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.categories"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `op_custom_fields` (
  `id` BIGINT NOT NULL,
  `type` VARCHAR(120),
  `field_format` VARCHAR(120),
  `regexp` STRING,
  `min_length` INT,
  `max_length` INT,
  `is_required` BOOLEAN,
  `is_for_all` BOOLEAN,
  `is_filter` BOOLEAN,
  `position` INT,
  `searchable` BOOLEAN,
  `editable` BOOLEAN,
  `admin_only` BOOLEAN,
  `multi_value` BOOLEAN,
  `default_value` STRING,
  `name` STRING,
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `content_right_to_left` BOOLEAN,
  `allow_non_open_versions` BOOLEAN,
  `custom_field_section_id` BIGINT,
  `formula` JSON,
  `has_comment` BOOLEAN,
  `visible_on_user_card` BOOLEAN,
  `semantic_key` STRING,
  `min_value` DOUBLE,
  `max_value` DOUBLE,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.custom_fields"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `op_custom_options` (
  `id` BIGINT NOT NULL,
  `custom_field_id` BIGINT,
  `position` INT,
  `default_value` BOOLEAN,
  `value` STRING,
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.custom_options"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `op_custom_values` (
  `id` BIGINT NOT NULL,
  `customized_type` VARCHAR(120),
  `customized_id` BIGINT,
  `custom_field_id` BIGINT,
  `value` STRING,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.custom_values"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `op_enumerations` (
  `id` BIGINT NOT NULL,
  `name` STRING,
  `position` INT,
  `is_default` BOOLEAN,
  `type` STRING,
  `active` BOOLEAN,
  `project_id` BIGINT,
  `parent_id` BIGINT,
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `color_id` BIGINT,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.enumerations"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `op_member_roles` (
  `id` BIGINT NOT NULL,
  `member_id` BIGINT,
  `role_id` BIGINT,
  `inherited_from` BIGINT,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.member_roles"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `op_members` (
  `id` BIGINT NOT NULL,
  `user_id` BIGINT,
  `project_id` BIGINT,
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `entity_type` STRING,
  `entity_id` BIGINT,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.members"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `op_project_phase_definitions` (
  `id` BIGINT NOT NULL,
  `name` STRING,
  `position` INT,
  `color_id` BIGINT,
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `start_gate` BOOLEAN,
  `start_gate_name` STRING,
  `finish_gate` BOOLEAN,
  `finish_gate_name` STRING,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.project_phase_definitions"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `op_project_phases` (
  `id` BIGINT NOT NULL,
  `start_date` DATE,
  `finish_date` DATE,
  `active` BOOLEAN,
  `project_id` BIGINT,
  `definition_id` BIGINT,
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `duration` INT,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.project_phases"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `op_roles` (
  `id` BIGINT NOT NULL,
  `name` STRING,
  `position` INT,
  `builtin` INT,
  `type` VARCHAR(120),
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.roles"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `op_statuses` (
  `id` BIGINT NOT NULL,
  `name` STRING,
  `is_closed` BOOLEAN,
  `is_default` BOOLEAN,
  `position` INT,
  `default_done_ratio` INT,
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `color_id` BIGINT,
  `is_readonly` BOOLEAN,
  `excluded_from_totals` BOOLEAN,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.statuses"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `op_types` (
  `id` BIGINT NOT NULL,
  `name` STRING,
  `position` INT,
  `is_in_roadmap` BOOLEAN,
  `is_milestone` BOOLEAN,
  `color_id` BIGINT,
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `allow_project_variants` BOOLEAN,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.types"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `op_versions` (
  `id` BIGINT NOT NULL,
  `project_id` BIGINT,
  `name` STRING,
  `description` STRING,
  `effective_date` DATE,
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `wiki_page_title` STRING,
  `status` STRING,
  `sharing` STRING,
  `start_date` DATE,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.versions"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `op_work_packages` (
  `id` BIGINT NOT NULL,
  `type_id` BIGINT,
  `project_id` BIGINT,
  `subject` STRING,
  `description` STRING,
  `due_date` DATE,
  `category_id` BIGINT,
  `status_id` BIGINT,
  `assigned_to_id` BIGINT,
  `priority_id` BIGINT,
  `version_id` BIGINT,
  `author_id` BIGINT,
  `lock_version` INT,
  `done_ratio` INT,
  `estimated_hours` DOUBLE,
  `created_at` DATETIME,
  `updated_at` DATETIME,
  `start_date` DATE,
  `responsible_id` BIGINT,
  `derived_estimated_hours` DOUBLE,
  `schedule_manually` BOOLEAN,
  `parent_id` BIGINT,
  `duration` INT,
  `ignore_non_working_days` BOOLEAN,
  `derived_remaining_hours` DOUBLE,
  `derived_done_ratio` INT,
  `position` INT,
  `story_points` INT,
  `remaining_hours` DOUBLE,
  `budget_id` INT,
  `project_phase_definition_id` BIGINT,
  `sprint_id` BIGINT,
  `sequence_number` INT,
  `identifier` STRING,
  `backlog_bucket_id` BIGINT,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror public.work_packages"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

ALTER TABLE `org_structure` ADD COLUMN (`basis_doc_attachment_id` BIGINT, `created_by` INT, `created_at` DATETIME, `updated_at` DATETIME);

ALTER TABLE `org_unit` ADD COLUMN (`updated_at` DATETIME);

CREATE TABLE IF NOT EXISTS `pengadaan_wbs` (
  `work_package_id` INT NOT NULL,
  `wbs_node_id` BIGINT,
  `updated_by` INT,
  `updated_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`work_package_id`) COMMENT "mirror lpms3.pengadaan_wbs"
DISTRIBUTED BY HASH(`work_package_id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

ALTER TABLE `position` ADD COLUMN (`updated_at` DATETIME);

ALTER TABLE `project_unit` ADD COLUMN (`updated_at` DATETIME);

CREATE TABLE IF NOT EXISTS `ref_dokumen_taxonomy` (
  `id` INT NOT NULL,
  `bagian` STRING,
  `no` STRING,
  `parent_id` INT,
  `uraian` STRING,
  `form_code` STRING,
  `wajib_untuk` JSON,
  `fase` STRING,
  `keterangan` STRING,
  `retensi_tahun` INT,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror lpms3.ref_dokumen_taxonomy"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

ALTER TABLE `ref_jenis_kode` ADD COLUMN (`tujuan` STRING, `output` STRING, `synced_at` DATETIME);

ALTER TABLE `ref_kelas_kontrak` ADD COLUMN (`synced_at` DATETIME);

ALTER TABLE `ref_level_risiko` ADD COLUMN (`synced_at` DATETIME);

ALTER TABLE `ref_matriks_kewenangan` ADD COLUMN (`synced_at` DATETIME);

CREATE TABLE IF NOT EXISTS `ref_peserta_rapat` (
  `id` INT NOT NULL,
  `jenis_rapat` STRING,
  `kelas` STRING,
  `urutan` INT,
  `peran` STRING,
  `peserta` STRING,
  `fungsi_code` STRING,
  `grade` STRING,
  `sumber_sop` STRING,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror lpms3.ref_peserta_rapat"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `ref_rasci` (
  `id` INT NOT NULL,
  `tabel` STRING,
  `aktivitas_no` INT,
  `aktivitas` STRING,
  `fase` STRING,
  `peran` STRING,
  `pihak` STRING,
  `fungsi_code` STRING,
  `grade` STRING,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror lpms3.ref_rasci"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `rekanan` (
  `id` BIGINT NOT NULL,
  `nama` STRING,
  `npwp` STRING,
  `alamat` STRING,
  `kontak` STRING,
  `kategori` STRING,
  `status` STRING,
  `alasan_hitam` STRING,
  `tanggal_hitam` DATE,
  `dihitamkan_by` INT,
  `created_by` INT,
  `updated_by` INT,
  `updated_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror lpms3.rekanan"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

CREATE TABLE IF NOT EXISTS `rekanan_evaluasi` (
  `id` BIGINT NOT NULL,
  `rekanan_id` BIGINT,
  `work_package_id` INT,
  `project_id` INT,
  `skor_mutu` SMALLINT,
  `skor_waktu` SMALLINT,
  `skor_harga` SMALLINT,
  `skor_k3l` SMALLINT,
  `catatan` STRING,
  `evaluator_id` INT,
  `tanggal` DATE,
  `created_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`id`) COMMENT "mirror lpms3.rekanan_evaluasi"
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

ALTER TABLE `user_position` ADD COLUMN (`basis_doc` STRING, `updated_at` DATETIME);

CREATE TABLE IF NOT EXISTS `wbs_done_snapshot` (
  `wbs_node_id` BIGINT NOT NULL,
  `project_id` INT,
  `work_package_id` INT,
  `wbs_code` STRING,
  `tasks` STRING,
  `level` STRING,
  `weigh_factor` DECIMAL(9,6),
  `weight` DECIMAL(12,9),
  `date_plan_start` DATE,
  `date_plan_finish` DATE,
  `date_actual_start` DATE,
  `date_actual_finish` DATE,
  `harga_pekerjaan` DECIMAL(20,2),
  `pic_user_id` INT,
  `frozen_by` INT,
  `frozen_at` DATETIME,
  `synced_at` DATETIME
) PRIMARY KEY(`wbs_node_id`) COMMENT "mirror lpms3.wbs_done_snapshot"
DISTRIBUTED BY HASH(`wbs_node_id`)
PROPERTIES ("replication_num" = "${STARROCKS_REPLICATION_NUM}", "enable_persistent_index" = "true");

ALTER TABLE `wbs_node` ADD COLUMN (`sow_boq_ref` STRING, `updated_by` INT, `pic_user_id` INT, `pic_unit_id` INT, `pic_assigned_by` INT, `pic_assigned_at` DATETIME);

ALTER TABLE `wbs_progress` ADD COLUMN (`evidence_attachment_ids` JSON);
