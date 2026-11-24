# frozen_string_literal: true

module Lpms3
  # Draft privat (1.44): work package berstatus Draft/New hanya terlihat oleh pembuat dan penerima tugasnya sampai
  # diajukan (punya tugas persetujuan) atau statusnya maju. Atasan belum dapat melihat atau memberi masukan atas draft.
  # Hanya isian buatan pengguna; item buatan Sistem (WBS, CR baseline, struktur BOP-001) bukan draft.
  # Admin sistem tetap melihat semuanya. Dipasang pada WorkPackage.visible (engine.rb).
  module DraftVisibility
    STATUSES = %w[Draft New].freeze

    module_function

    def status_ids = ::Status.where(name: STATUSES).pluck(:id)
    def draft?(wp) = STATUSES.include?(wp.status&.name)

    def restrict(scope, user)
      return scope if user.nil? || !user.respond_to?(:admin?) || user.admin?

      ids = status_ids
      return scope if ids.empty?

      uid = user.id.to_i
      scope.where(<<~SQL.squish, ids)
        NOT (work_packages.status_id IN (?) AND COALESCE(work_packages.author_id, 0) <> #{uid}
             AND COALESCE(work_packages.assigned_to_id, 0) <> #{uid}
             AND NOT EXISTS (SELECT 1 FROM lpms3_approval_tasks lat WHERE lat.work_package_id = work_packages.id)
             AND EXISTS (SELECT 1 FROM users dau WHERE dau.id = work_packages.author_id AND dau.type = 'User'))
      SQL
    end
  end
end
