# Data deklaratif seed LPMS3 (Spesifikasi Teknis §5.3, §5.5, §5.6). Dimuat oleh seed lain.
module Lpms3Data
  # Tipe WP => [status berurutan, warna, milestone?]
  TYPES = {
    "Deliverable"      => [%w[Baru Dikerjakan Verifikasi\ Internal Validasi\ Pelanggan Diterima\ Pelanggan Ditolak], "#1D6FA5"],
    "Task"             => [%w[Baru Dikerjakan Selesai Batal], "#5B6770"],
    "Milestone"        => [%w[Rencana Tercapai Tergeser], "#E2A800", true],
    "Dokumen Rencana"  => [%w[Draft Reviu Revisi Disahkan Diganti], "#6C4AB6"],
    "Change Request"   => [%w[Draft Diajukan Analisis\ Dampak Sidang\ CCM Disetujui Ditolak Ditunda Implementasi Verifikasi Ditutup], "#C0392B"],
    "Risiko"           => [%w[Teridentifikasi Dianalisis Respons\ Direncanakan Dipantau Terjadi Ditutup], "#D35400"],
    "Bahaya K3L"       => [%w[Teridentifikasi Dinilai Pengendalian\ Diterapkan Ditinjau Ditutup], "#E67E22"],
    "Isu"              => [%w[Baru Analisis Tindak\ Lanjut Selesai], "#B03A2E"],
    "Action Item"      => [%w[Baru Dikerjakan Selesai], "#2E8B57"],
    "Lesson Learned"   => [%w[Draft Ditinjau Dipublikasikan], "#16A085"],
    "Inspeksi Mutu"    => [%w[Direncanakan Dilaksanakan Lulus Gagal], "#2874A6"],
    "NCR"              => [%w[Terbuka Analisis\ Akar\ Masalah Koreksi Verifikasi Ditutup], "#922B21"],
    "Item Pengadaan"   => [%w[Rencana PR Proses\ Pengadaan PO/Kontrak Pengiriman GR/SES Selesai], "#7D6608"],
    "Stakeholder"      => [%w[Aktif Tidak\ aktif], "#117A65"],
    "Top Up Anggaran"  => [%w[Diajukan Diverifikasi\ Pengendali\ Anggaran Disetujui Diinput\ ERP Ditolak], "#1F618D"],
    "Dokumen Proyek"   => [%w[Belum Terkumpul Diverifikasi Diarsipkan], "#4D5656"],
  }.freeze

  CLOSED = ["Ditolak", "Ditutup", "Selesai", "Batal", "Diarsipkan", "Diganti", "Tercapai", "Diterima Pelanggan",
            "Dipublikasikan", "Lulus", "Gagal", "Tidak aktif", "Diinput ERP", "Tergeser"].freeze

  # Peran proyek (§5.6). Izin diambil dari daftar dasar dan disaring terhadap yang tersedia.
  VIEW  = %i[view_project view_work_packages view_calendar view_wiki_pages view_news view_documents
             view_members view_work_package_watchers view_time_entries view_meetings].freeze
  EDIT  = %i[add_work_packages edit_work_packages add_work_package_comments add_work_package_attachments
             manage_work_package_relations log_time view_own_time_entries edit_own_time_entries
             create_meetings edit_meetings manage_public_queries save_queries
             edit_wiki_pages add_work_package_watchers].freeze
  MANAGE = %i[edit_project manage_members manage_versions manage_categories select_project_modules
              move_work_packages delete_work_packages manage_subtasks view_budgets edit_budgets
              manage_documents manage_news].freeze

  ROLES = {
    "Project Sponsor"                     => VIEW + %i[add_work_package_comments view_budgets],
    "Pimpro"                              => VIEW + EDIT + MANAGE,
    "Tim Proyek"                          => VIEW + EDIT,
    "Fungsi Pelaksanaan Proyek (Struktural)" => VIEW + %i[add_work_package_comments edit_work_packages view_budgets],
    "Fungsi Pengawasan Proyek"            => VIEW + EDIT + %i[view_budgets manage_public_queries],
    "Approver CCM"                        => VIEW + %i[add_work_package_comments edit_work_packages],
    "Fungsi Perencanaan Proyek"           => VIEW + EDIT,
    "Fungsi Pengendali Anggaran/Keuangan/Akuntansi" => VIEW + EDIT + %i[view_budgets edit_budgets],
    "Fungsi Penjaminan Mutu"              => VIEW + EDIT,
    "Fungsi Manajemen Risiko"             => VIEW + EDIT,
    "Fungsi K3 & Lingkungan Hidup"        => VIEW + EDIT,
    "Fungsi Pengadaan & Pengelola Gudang" => VIEW + EDIT,
    "Fungsi Pemasaran"                    => VIEW + EDIT,
    "Fungsi Rekayasa Solusi Teknis"       => VIEW + EDIT,
    "Fungsi Rekrutmen & Pembelajaran SDM" => VIEW + %i[add_work_package_comments],
    "Pembaca (Informed)"                  => VIEW,
  }.freeze

  # Workflow Change Request per peran (§5.5): peran => [[dari, ke], ...]
  CR_FLOW = {
    "Pimpro"                   => [%w[Draft Diajukan], %w[Disetujui Implementasi], %w[Implementasi Verifikasi]],
    "Fungsi Pengawasan Proyek" => [%w[Diajukan Analisis\ Dampak], %w[Analisis\ Dampak Sidang\ CCM], %w[Verifikasi Ditutup]],
    "Approver CCM"             => [%w[Sidang\ CCM Disetujui], %w[Sidang\ CCM Ditolak], %w[Sidang\ CCM Ditunda], %w[Ditunda Sidang\ CCM]],
  }.freeze
  # Peran umum untuk transisi bebas maju pada tipe non-CR
  GENERAL_ROLES = ["Pimpro", "Tim Proyek", "Fungsi Pengawasan Proyek"].freeze
end
