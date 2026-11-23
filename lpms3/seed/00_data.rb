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

  # Fungsi keuangan/biaya: anggaran, biaya, tarif. Dipakai peran Keuangan & turunannya (termasuk tim proyek yang mengurus biaya).
  COST_VIEW = %i[view_budgets view_cost_entries view_own_cost_entries view_cost_rates view_hourly_rates view_own_hourly_rate].freeze
  COST_EDIT = %i[edit_budgets log_costs log_own_costs edit_cost_entries edit_own_cost_entries edit_hourly_rates
                 edit_own_hourly_rate view_time_entries edit_time_entries].freeze

  ROLES = {
    "Project Sponsor"                     => VIEW + %i[add_work_package_comments view_budgets],
    "Pimpro"                              => VIEW + EDIT + MANAGE + COST_VIEW + COST_EDIT,
    "Tim Proyek"                          => VIEW + EDIT,
    "Fungsi Pelaksanaan Proyek (Struktural)" => VIEW + %i[add_work_package_comments edit_work_packages view_budgets],
    "Fungsi Pengawasan Proyek"            => VIEW + EDIT + %i[view_budgets manage_public_queries],
    "Approver CCM"                        => VIEW + %i[add_work_package_comments edit_work_packages],
    "Fungsi Perencanaan Proyek"           => VIEW + EDIT,
    "Fungsi Pengendali Anggaran/Keuangan/Akuntansi" => VIEW + EDIT + COST_VIEW + COST_EDIT,
    "Pengelola Biaya Proyek"              => VIEW + EDIT + COST_VIEW + COST_EDIT,
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

  # Tipe dengan status keputusan: workflow form OpenProject TIDAK boleh mencapai status keputusan secara langsung
  # (temuan audit P0 #2, ditutup 20-23 Nov 2026). Daftar ini = satu-satunya transisi form yang diizinkan; seed
  # 50_workflows menghapus transisi lain untuk tipe ini. Peran => [[dari, ke], ...]
  DECISION_FLOWS = {
    # Reviu, Revisi, dan Disahkan hanya lewat rantai persetujuan di Tugas (Lpms3::ApprovalTask), yang menulis status
    # tanpa workflow. Dokumen Disahkan terkunci; hanya Pimpro yang dapat menandainya Diganti (versi baru).
    "Dokumen Rencana" => {
      "Tim Proyek"               => [%w[New Draft], %w[Revisi Draft]],
      "Fungsi Pengawasan Proyek" => [%w[New Draft], %w[Revisi Draft]],
      "Pimpro"                   => [%w[New Draft], %w[Revisi Draft], %w[Draft Diganti], %w[Revisi Diganti], %w[Disahkan Diganti]],
    },
    "Top Up Anggaran" => {
      "Tim Proyek"               => [%w[New Diajukan], %w[Ditolak Diajukan]],
      "Fungsi Pengawasan Proyek" => [%w[New Diajukan]],
      "Pimpro"                   => [%w[New Diajukan], %w[Ditolak Diajukan],
                                     %w[Diverifikasi\ Pengendali\ Anggaran Disetujui], %w[Diverifikasi\ Pengendali\ Anggaran Ditolak]],
      "Fungsi Pengendali Anggaran/Keuangan/Akuntansi" => [%w[Diajukan Diverifikasi\ Pengendali\ Anggaran], %w[Diajukan Ditolak],
                                                          %w[Disetujui Diinput\ ERP]],
    },
    "Deliverable" => {
      "Tim Proyek"               => [%w[New Baru], %w[Baru Dikerjakan], %w[Dikerjakan Baru], %w[Dikerjakan Verifikasi\ Internal], %w[Ditolak Dikerjakan]],
      "Fungsi Pengawasan Proyek" => [%w[New Baru]],
      "Pimpro"                   => [%w[New Baru], %w[Baru Dikerjakan], %w[Dikerjakan Baru], %w[Dikerjakan Verifikasi\ Internal], %w[Ditolak Dikerjakan],
                                     %w[Validasi\ Pelanggan Diterima\ Pelanggan], %w[Validasi\ Pelanggan Ditolak]],
      "Fungsi Penjaminan Mutu"   => [%w[Verifikasi\ Internal Validasi\ Pelanggan], %w[Verifikasi\ Internal Dikerjakan], %w[Verifikasi\ Internal Ditolak]],
    },
  }.freeze
end
