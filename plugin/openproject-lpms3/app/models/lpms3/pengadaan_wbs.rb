# frozen_string_literal: true

module Lpms3
  # Tautan Item Pengadaan → aktivitas WBS. Tahap pengadaan memberi usulan % Complete aktivitas:
  # PO/Kontrak 25 %, Pengiriman 50 %, GR/SES 75 %, Selesai 100 % (aktivitas = tahap terendah dari item tertautnya).
  class PengadaanWbs < ::ApplicationRecord
    self.table_name = "lpms3.pengadaan_wbs"
    self.primary_key = :work_package_id

    STAGE_PCT = { "PO/Kontrak" => 25, "Pengiriman" => 50, "GR/SES" => 75, "Selesai" => 100 }.freeze

    belongs_to :work_package, class_name: "::WorkPackage"
    belongs_to :wbs_node, class_name: "Lpms3::WbsNode"

    def self.stage_pct(wp) = STAGE_PCT.fetch(wp.status&.name, 0)

    # { wbs_node_id => { count:, usulan:, nilai: } } untuk proyek.
    def self.summary(project)
      links = where(wbs_node_id: WbsNode.where(project_id: project.id).select(:id)).includes(work_package: :status).to_a
      return {} if links.empty?

      vals = ::OpenProject::Lpms3::Procurement.items(::WorkPackage.where(id: links.map(&:work_package_id))).to_h { |it| [it.wp.id, it.value_base] }
      links.group_by(&:wbs_node_id).transform_values do |ls|
        { count: ls.size, usulan: ls.map { |l| stage_pct(l.work_package) }.min, nilai: ls.sum { |l| vals[l.work_package_id] || 0 } }
      end
    end

    def self.link!(project, user, wp_id, node_id)
      wp = ::WorkPackage.find_by!(project_id: project.id, id: wp_id)
      raise ::Lpms3::Wbs::Error, "Bukan Item Pengadaan." unless wp.type&.name == ::OpenProject::Lpms3::Procurement::TYPE
      raise ::Lpms3::Wbs::Error, "Anda tidak berwenang menautkan pengadaan." unless ::Lpms3::Rekanan.pengadaan?(user, project)

      if node_id.blank?
        where(work_package_id: wp.id).delete_all
        return nil
      end
      node = WbsNode.find_by!(project_id: project.id, id: node_id)
      raise ::Lpms3::Wbs::Error, "Pilih aktivitas WBS (baris tanpa sub-tugas)." if node.children.exists? || node.root?

      rec = find_or_initialize_by(work_package_id: wp.id)
      rec.update!(wbs_node_id: node.id, updated_by: user.id, updated_at: Time.current)
      sync_activity!(node)
      rec
    end

    # Naikkan % Complete aktivitas ke usulan tahap pengadaan bila bukti sudah ada di work package aktivitas.
    # Tidak pernah menurunkan, tidak menyentuh aktivitas beku. Mengembalikan :applied, :need_evidence, atau nil.
    def self.sync_activity!(node)
      node.reload
      links = where(wbs_node_id: node.id).includes(work_package: :status).to_a
      return nil if links.empty?

      usulan = links.map { |l| stage_pct(l.work_package) }.min
      return nil if usulan <= (node.pct * 100).round || ::Lpms3::Wbs.frozen?(node)
      return :need_evidence if node.work_package.nil? || node.work_package.attachments.none?

      ::Lpms3::Wbs.update_field!(node.project, ::User.system, node.id, "pct_complete", usulan.to_s)
      :applied
    end
  end
end
