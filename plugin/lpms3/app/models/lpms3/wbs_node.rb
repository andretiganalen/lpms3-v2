module Lpms3
  # Node WBS Template LPMS (lpms3.wbs_node). Weight = weight induk × weigh_factor; setiap kelompok saudara
  # berjumlah 100 %. Node selain Level 0 tertaut ke satu work package (Gantt/Kalender).
  class WbsNode < ::ApplicationRecord
    self.table_name = "lpms3.wbs_node"

    PRIORITIES = %w[Low Medium High].freeze
    COMPLETE_STEPS = [0, 0.25, 0.5, 0.75, 1].freeze
    # Daftar Resources dari sheet Settings template WBS.
    RESOURCES = ["Pimpro", "Deputi Pimpro", "Engineer", "Admin", "Vendor", "Sub-Vendor", "Konsultan", "Keuangan", "Pengadaan",
                 "Sponsor", "Eselon 1", "Eselon 2", "Staff", "K3LH", "Kualitas", "Pengawas", "Developer", "Direksi",
                 "Perencanaan", "Pemasaran", "End User", "Risiko", "Innovation", "Auditor", "Mekanikal", "Elektrikal",
                 "Plumbing", "Sipil", "Perangkat Lunak", "Perangkat Keras", "Jaringan", "Bowheer", "Lainnya"].freeze
    MAX_DEPTH = 7

    belongs_to :project, class_name: "::Project"
    belongs_to :parent, class_name: "Lpms3::WbsNode", optional: true
    has_many :children, -> { order(:sort_order, :id) }, class_name: "Lpms3::WbsNode", foreign_key: :parent_id
    belongs_to :work_package, class_name: "::WorkPackage", optional: true
    belongs_to :pic_user, class_name: "::User", optional: true
    belongs_to :pic_unit, class_name: "Lpms3::OrgUnit", optional: true

    # Level 0-3 selalu ringkasan; mulai Level 4, node tanpa anak adalah aktivitas ("Level n Activity").
    def self.level_label(depth, leaf)
      leaf && depth >= 4 ? "Level #{depth} Activity" : "Level #{depth}"
    end

    def depth = level[/\d+/].to_i
    def root? = parent_id.nil?
    def leaf?(child_map) = child_map[id].blank?
    def pct = pct_complete.to_f
    def done? = pct >= 1
  end
end
