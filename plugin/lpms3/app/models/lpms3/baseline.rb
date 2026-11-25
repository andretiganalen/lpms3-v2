# frozen_string_literal: true

module Lpms3
  # Versi baseline WBS (lpms3.baseline). Baseline 0 = Kick-Off; versi > 0 aktif setelah Change Request (BFR-001)
  # disetujui. Satu DRAFT dan satu ACTIVE per proyek (indeks unik parsial).
  class Baseline < ::ApplicationRecord
    self.table_name = "lpms3.baseline"

    STATUSES = %w[DRAFT ACTIVE SUPERSEDED REJECTED].freeze

    belongs_to :project, class_name: "::Project"
    belongs_to :change_request, class_name: "::WorkPackage", foreign_key: :change_request_form_id, optional: true
    belongs_to :approver, class_name: "::User", foreign_key: :approved_by, optional: true
    has_many :items, class_name: "Lpms3::BaselineItem", foreign_key: :baseline_id

    scope :draft, -> { where(status: "DRAFT") }
    scope :active, -> { where(is_active: true) }

    def self.draft_for(project) = draft.find_by(project_id: project.id)
    def self.active_for(project) = active.find_by(project_id: project.id)
    def self.history(project) = where(project_id: project.id).order(version: :desc)

    def draft? = status == "DRAFT"
    def cr_status = change_request&.status&.name
  end
end
