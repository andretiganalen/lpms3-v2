# frozen_string_literal: true

module Lpms3
  # Permintaan anggota proyek (1.44): orang yang dimasukkan selain oleh Pimpro (mis. Admin Eselon 2 Fungsi Proyek) baru
  # mendapat akses View/Edit setelah Pimpro menyetujui. Penambahan oleh Pimpro, admin, dan alur sistem langsung berlaku.
  class MemberRequest < ::ApplicationRecord
    self.table_name = "lpms3_member_requests"

    class Error < StandardError; end

    belongs_to :project, class_name: "::Project"
    belongs_to :user, class_name: "::User"
    belongs_to :requester, class_name: "::User", foreign_key: :requested_by

    scope :pending, -> { where(state: "menunggu") }

    class << self
      def bypass
        prev = Thread.current[:lpms3_member_gate_bypass]
        Thread.current[:lpms3_member_gate_bypass] = true
        yield
      ensure
        Thread.current[:lpms3_member_gate_bypass] = prev
      end

      def pimpro?(user, project) = user.roles_for_project(project).map(&:name).include?("Pimpro")

      # Penambahan oleh user ini harus menunggu Pimpro?
      def gated?(actor, project, principal)
        return false if Thread.current[:lpms3_member_gate_bypass] || Thread.current[:lpms3_tim_proyek_sync]
        return false unless actor&.logged? && project.is_a?(::Project) && principal.is_a?(::User)
        return false if actor.admin? || pimpro?(actor, project)

        ::Member.where(project_id: project.id).joins(:member_roles).where(member_roles: { role_id: ::ProjectRole.where(name: "Pimpro").select(:id) }).exists?
      end

      def request!(actor, project, principal, role_ids)
        r = pending.find_or_initialize_by(project_id: project.id, user_id: principal.id)
        r.assign_attributes(role_ids: (Array(r.role_ids) + Array(role_ids).map(&:to_i)).uniq.reject(&:zero?), requested_by: actor.id,
                            requested_at: Time.current)
        r.save!
        r
      end

      def pending_for(user)
        return [] unless user&.logged?

        pids = ::Member.joins(:member_roles).where(user_id: user.id, member_roles: { role_id: ::ProjectRole.where(name: "Pimpro").select(:id) })
                       .pluck(:project_id)
        pending.where(project_id: pids).includes(:project, :user, :requester).order(:requested_at).to_a
      end
    end

    def roles = ::ProjectRole.where(id: role_ids).to_a

    def decide!(actor, approve, note = nil)
      raise Error, "Hanya Pimpro proyek ini yang memutus permintaan anggota." unless actor.admin? || self.class.pimpro?(actor, project)
      raise Error, "Permintaan sudah diputus." unless state == "menunggu"

      transaction do
        if approve
          self.class.bypass do
            m = ::Member.find_or_initialize_by(project:, principal: user)
            m.roles = (m.roles.to_a + roles).uniq
            m.roles = [::ProjectRole.find_by!(name: "Tim Proyek")] if m.roles.empty?
            m.save!
          end
        end
        update!(state: approve ? "disetujui" : "ditolak", decided_by: actor.id, decided_at: Time.current, note: note.to_s.strip.presence)
      end
      self
    end
  end
end
