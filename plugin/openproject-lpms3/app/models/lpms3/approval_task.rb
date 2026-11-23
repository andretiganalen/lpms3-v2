# frozen_string_literal: true

module Lpms3
  # Tugas persetujuan berjenjang:
  #  - Staff mengajukan → tahap "pimpro" (Pimpro meninjau; Pejabat Eselon 2 boleh memutuskan langsung = bypass).
  #  - Pimpro meneruskan → tahap "eselon2" (Pejabat Eselon 2 memutuskan).
  #  - Pejabat Eselon 2 menyetujui → tahap "eselon1" (Fungsi Manajemen Proyek, Pejabat Eselon 1 memutuskan).
  #  - Pejabat Eselon 1 menyetujui → disetujui final. Setelah itu Eselon 1 dapat menembuskan ke Direksi (untuk diketahui).
  #  - Revisi di tahap mana pun mengembalikan dokumen ke pengaju.
  class ApprovalTask < ::ApplicationRecord
    self.table_name = "lpms3_approval_tasks"

    class Error < StandardError; end

    PIMPRO_ROLE = "Pimpro"
    ESELON2_ROLE = "Pejabat Eselon 2"
    ESELON1_ROLE = "Pejabat Eselon 1"
    DIREKSI_ROLE = "Direksi"
    ADMIN_PWP_ROLE = "Fungsi Pengawasan Proyek"
    STAGES = %w[pimpro eselon2 eselon1].freeze
    STATES = %w[menunggu diteruskan disetujui revisi].freeze
    ACTIONS = %w[teruskan setujui revisi].freeze

    belongs_to :work_package
    belongs_to :project
    belongs_to :requested_by, class_name: "User"
    belongs_to :decided_by, class_name: "User", optional: true
    belongs_to :tembusan_by, class_name: "User", optional: true

    scope :pending, -> { where(state: "menunggu") }
    scope :final_approved, -> { where(stage: "eselon1", state: "disetujui") }

    validates :stage, inclusion: { in: STAGES }
    validates :state, inclusion: { in: STATES }

    class << self
      def roles_of(user, project)
        user.roles_for_project(project).map(&:name)
      end

      def pimpro?(user, project) = roles_of(user, project).include?(PIMPRO_ROLE)
      def eselon2?(user, project) = user.admin? || roles_of(user, project).include?(ESELON2_ROLE)
      def eselon1?(user, project) = user.admin? || roles_of(user, project).include?(ESELON1_ROLE)
      def direksi?(user, project) = roles_of(user, project).include?(DIREKSI_ROLE)

      # Pengaju: Pimpro atau Pejabat Eselon 2 mengirim langsung ke Pejabat Eselon 2; selain itu ke Pimpro.
      def ajukan!(work_package, user, note: nil)
        project = work_package.project
        raise Error, "Anda bukan anggota proyek ini." unless user.admin? || user.allowed_in_project?(:view_work_packages, project)

        stage = (pimpro?(user, project) || eselon2?(user, project)) ? "eselon2" : "pimpro"
        transaction do
          work_package.lock!
          raise Error, "Dokumen ini masih menunggu keputusan." if pending.exists?(work_package_id: work_package.id)

          task = create!(work_package:, project:, stage:, state: "menunggu", requested_by: user,
                         requested_at: Time.current, requester_note: note.to_s.strip.presence)
          set_status!(work_package, "Reviu", "Diajukan untuk persetujuan oleh #{user.name}")
          task
        end
      rescue ActiveRecord::RecordNotUnique
        raise Error, "Dokumen ini masih menunggu keputusan."
      end

      # Tugas aktif yang bisa ditindaklanjuti user, lintas proyek. Diurutkan dari yang paling lama.
      def aspek?(work_package) = work_package.subject.start_with?(::OpenProject::Lpms3::Aspects::PREFIX)

      def set_status!(work_package, name, note)
        return unless aspek?(work_package)

        status = ::Status.find_by(name:)
        return unless status

        work_package.status = status
        work_package.journal_notes = note
        work_package.save!(validate: false)
      end

      def pending_for(user)
        pending.includes(:work_package, :project, :requested_by).order(:requested_at).select { |t| t.actable_by?(user) }
      end

      # Dokumen final yang belum ditembuskan dan bisa ditembuskan user (Pejabat Eselon 1).
      def tembusan_candidates(user)
        final_approved.where(tembusan_at: nil).includes(:work_package, :project, :requested_by)
                      .order(:decided_at).select { |t| eselon1?(user, t.project) }
      end

      # Tembusan yang diterima user sebagai Direksi (untuk diketahui).
      def tembusan_for(user)
        final_approved.where.not(tembusan_at: nil).includes(:work_package, :project, :requested_by, :decided_by)
                      .order(tembusan_at: :desc).select { |t| direksi?(user, t.project) || user.admin? }
      end
    end

    def actable_by?(user)
      return false unless state == "menunggu"
      # Pemisahan tugas (#678): pengaju dan siapa pun yang sudah bertindak pada siklus ini (termasuk admin)
      # tidak boleh memutus tahap berikutnya. Satu orang, satu tindakan per siklus persetujuan.
      return false if cycle_actor_ids.include?(user.id)

      case stage
      when "pimpro" then self.class.pimpro?(user, project) || self.class.eselon2?(user, project)
      when "eselon2" then self.class.eselon2?(user, project)
      when "eselon1" then self.class.eselon1?(user, project)
      else false
      end
    end

    # Pengaju dan pemutus pada siklus persetujuan yang sedang berjalan untuk dokumen ini.
    # Siklus dimulai sesudah revisi atau persetujuan final terakhir sebelum tugas ini.
    def cycle_actor_ids
      @cycle_actor_ids ||= begin
        scope = self.class.where(work_package_id:).where("id <= ?", id)
        cut = scope.where("id < ?", id)
                   .where("state = 'revisi' OR (stage = 'eselon1' AND state = 'disetujui')").maximum(:id)
        scope = scope.where("id > ?", cut) if cut
        scope.pluck(:requested_by_id, :decided_by_id).flatten.compact.uniq
      end
    end

    # Tindakan yang tersedia untuk user pada tugas ini.
    def actions_for(user)
      return [] unless actable_by?(user)

      case stage
      when "pimpro" then self.class.eselon2?(user, project) && !self.class.pimpro?(user, project) ? %w[setujui revisi] : %w[teruskan revisi]
      else %w[setujui revisi]
      end
    end

    # Teks "harus apa" untuk ditampilkan ke user.
    def required_action_for(user)
      case stage
      when "pimpro" then actions_for(user).include?("setujui") ? "Setujui langsung (bypass Pimpro) atau minta revisi" : "Tinjau dokumen, lalu teruskan ke Pejabat Eselon 2 atau minta revisi"
      when "eselon2" then "Setujui lalu teruskan ke Fungsi Manajemen Proyek (Eselon 1), atau minta revisi"
      when "eselon1" then "Setujui (final) atau minta revisi"
      else "Tidak ada tindakan"
      end
    end

    def act!(user, action, note = nil)
      raise Error, "Tindakan tidak dikenal." unless ACTIONS.include?(action)

      text = note.to_s.strip
      raise Error, "Catatan wajib untuk permintaan revisi." if action == "revisi" && text.empty?

      self.class.transaction do
        lock!
        raise Error, "Tugas ini sudah diputuskan." unless state == "menunggu"
        raise Error, "Anda tidak berwenang untuk tindakan ini." unless actions_for(user).include?(action)

        bypass = stage == "pimpro" && action == "setujui"
        # "setujui" di tahap pimpro/eselon2 meneruskan ke Eselon 1; di tahap eselon1 menjadi final.
        forward = %w[pimpro eselon2].include?(stage) && (action == "teruskan" || action == "setujui")
        new_state = if forward then "diteruskan"
                    elsif action == "setujui" then "disetujui"
                    else "revisi"
                    end
        update!(state: new_state, decided_by: user, decided_at: Time.current, decision_note: text.presence, bypassed: bypass)

        if forward
          next_stage = action == "teruskan" ? "eselon2" : "eselon1"
          self.class.create!(work_package:, project:, stage: next_stage, state: "menunggu", requested_by: user,
                             requested_at: Time.current, requester_note: text.presence)
        elsif new_state == "revisi"
          self.class.set_status!(work_package, "Revisi", "Diminta revisi oleh #{user.name}: #{text}")
        elsif new_state == "disetujui"
          self.class.set_status!(work_package, "Disahkan", "Disetujui final oleh #{user.name}")
          Kickoff.ensure_for!(project)
        end
      end
      self
    end

    # Pejabat Eselon 1 menembuskan dokumen final ke Direksi (untuk diketahui; tanpa persetujuan).
    def tembusan!(user)
      self.class.transaction do
        lock!
        raise Error, "Hanya dokumen final yang bisa ditembuskan." unless stage == "eselon1" && state == "disetujui"
        raise Error, "Dokumen ini sudah ditembuskan." if tembusan_at
        raise Error, "Anda tidak berwenang menembuskan dokumen ini." unless self.class.eselon1?(user, project)

        update!(tembusan_at: Time.current, tembusan_by: user)
      end
      self
    end
  end
end
