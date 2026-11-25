# frozen_string_literal: true

# LPMS3: tahap Eselon 1 (setelah Eselon 2) dan tembusan "untuk diketahui" ke Direksi.
class AddEselon1TembusanToApprovalTasks < ActiveRecord::Migration[7.1]
  def change
    add_column :lpms3_approval_tasks, :tembusan_at, :datetime
    add_column :lpms3_approval_tasks, :tembusan_by_id, :bigint
  end
end
