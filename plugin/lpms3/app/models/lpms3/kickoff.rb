# frozen_string_literal: true

module Lpms3
  # Kick-Off proyek: penunjukan Project Analis oleh Admin Fungsi Pengawasan Proyek, lalu undangan oleh Project Analis.
  class Kickoff < ::ApplicationRecord
    self.table_name = "lpms3_kickoffs"

    class Error < StandardError; end

    ADMIN_ROLE = "Fungsi Pengawasan Proyek"
    ANALIS_ROLE = "Project Analis"
    # Roster wajib BOP-001 Tabel 2 (ref_peserta_rapat, jenis "Kick-Off Meeting"), dipetakan ke peran proyek:
    #  - Pemimpin & penyelenggara: Eselon I/II Fungsi Pengawasan Proyek
    #  - Pemapar: Eselon I/II Fungsi Pelaksanaan Proyek / Pimpro
    ROSTER = {
      "pemimpin" => { label: "Pemimpin & Penyelenggara (Eselon I/II F. Pengawasan Proyek)",
                      roles: ["Fungsi Pengawasan Proyek", "Pejabat Eselon 1", "Pejabat Eselon 2"] },
      "pemapar" => { label: "Pemapar (Eselon I/II F. Pelaksanaan Proyek / Pimpro)",
                     roles: ["Pimpro", "Project Sponsor"] }
    }.freeze
    STATES = %w[menunggu_analis menunggu_undangan terkirim].freeze

    belongs_to :project
    belongs_to :analis, class_name: "User", optional: true
    belongs_to :assigned_by, class_name: "User", optional: true
    belongs_to :invited_by, class_name: "User", optional: true

    validates :state, inclusion: { in: STATES }

    class << self
      # Dipanggil saat dokumen Inisiasi mencapai persetujuan final.
      def ensure_for!(project)
        find_or_create_by!(project:)
      end

      def pending_for(user)
        includes(:project).select do |k|
          case k.state
          when "menunggu_analis" then k.admin_pwp?(user)
          when "menunggu_undangan" then k.analis_id == user.id
          else false
          end
        end
      end

      def admin_pwp_roles_ok?(user, project) = user.admin? || ApprovalTask.roles_of(user, project).include?(ADMIN_ROLE)
    end

    def admin_pwp?(user) = self.class.admin_pwp_roles_ok?(user, project)

    # Kandidat analis: anggota proyek yang memegang peran Project Analis.
    def analis_candidates
      project.members.includes(:principal, :roles).select { |m| m.roles.any? { |r| r.name == ANALIS_ROLE } }
                     .map(&:principal).select { |p| p.is_a?(User) }.uniq
    end

    def assign!(user, analis_user)
      transaction do
        lock!
        raise Error, "Hanya Admin Fungsi Pengawasan Proyek yang bisa menunjuk Project Analis." unless admin_pwp?(user)
        raise Error, "Penunjukan hanya bisa dilakukan saat menunggu Project Analis." unless state == "menunggu_analis"
        raise Error, "Pengguna yang dipilih belum berperan sebagai Project Analis di proyek ini." unless analis_candidates.include?(analis_user)

        update!(state: "menunggu_undangan", analis: analis_user, assigned_by: user, assigned_at: Time.current)
      end
      self
    end

    # Roster BOP-001 per peran: anggota proyek yang memegang salah satu peran yang dipetakan.
    def roster
      members = project.members.includes(:principal, :roles).select { |m| m.principal.is_a?(User) }
      ROSTER.to_h do |key, cfg|
        matched = members.select { |m| m.roles.any? { |r| cfg[:roles].include?(r.name) } }.map(&:principal).uniq
        [key, { label: cfg[:label], users: matched }]
      end
    end

    # Undangan: roster BOP-001 (wajib) + seluruh stakeholder proyek. Gerbang: Pemimpin dan Pemapar harus terisi.
    def invitee_list
      members = project.members.includes(:principal, :roles).select { |m| m.principal.is_a?(User) }
      roster_ids = roster.values.flat_map { |r| r[:users].map(&:id) }
      members.map do |m|
        u = m.principal
        kategori = roster_ids.include?(u.id) ? "BOP-001 Tabel 2" : "Stakeholder"
        { "user_id" => u.id, "name" => u.name, "roles" => m.roles.map(&:name), "kategori" => kategori }
      end.uniq { |i| i["user_id"] }
    end

    # Project Analis mengundang seluruh stakeholder proyek ke rapat Kick-Off (roster BOP-001 wajib terisi).
    def undang!(user, scheduled_at:, agenda: nil)
      transaction do
        lock!
        raise Error, "Hanya Project Analis yang ditunjuk yang bisa mengundang." unless analis_id == user.id && state == "menunggu_undangan"
        raise Error, "Tentukan tanggal dan waktu rapat Kick-Off." if scheduled_at.blank?

        r = roster
        kurang = %w[pemimpin pemapar].reject { |k| r[k][:users].any? }.map { |k| r[k][:label] }
        raise Error, "Roster BOP-001 belum lengkap: #{kurang.join('; ')}. Lengkapi peran proyek sebelum mengundang." if kurang.any?

        invitees = invitee_list
        update!(state: "terkirim", invited_by: user, invited_at: Time.current,
                scheduled_at:, agenda: agenda.to_s.strip.presence, invitees:)
      end
      self
    end
  end
end
