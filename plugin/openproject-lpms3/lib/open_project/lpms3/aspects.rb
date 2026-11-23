# frozen_string_literal: true

# LPMS3: Penetapan 9 Aspek PMP (BOP-001 §5.1), langkah Inisiasi sebelum Penetapan Project Charter.
# Sembilan aspek adalah WP tipe "Dokumen Rencana" berjudul "Dokumen Rencana — <aspek>". PIC/Pimpro mengisi isi dan lampiran
# langsung di tabel, lalu mengajukan reviu (Draft/Revisi → Reviu); atasan menyetujui (→ Disahkan) atau meminta revisi (→ Revisi).
module OpenProject::Lpms3
  module Aspects
    PREFIX = "Dokumen Rencana — "
    # Peran proyek yang boleh menyetujui atau meminta revisi (atasan Pimpro).
    APPROVER_ROLES = ["Pimpro", "Project Sponsor"].freeze
    # Langkah -> status tujuan dan status awal yang diizinkan.
    STEPS = {
      "submit" => { to: "Reviu", from: %w[Draft Revisi], by: :editor },
      "approve" => { to: "Disahkan", from: %w[Reviu], by: :approver },
      "revision" => { to: "Revisi", from: %w[Reviu], by: :approver }
    }.freeze

    module_function

    def scope(project, user)
      type = ::Type.find_by(name: "Dokumen Rencana")
      return ::WorkPackage.none unless type

      ::WorkPackage.visible(user).where(project_id: project.id, type_id: type.id)
                   .where("work_packages.subject LIKE ?", "#{PREFIX}%")
    end

    def name(wp) = wp.subject.delete_prefix(PREFIX)

    def approver?(user, project)
      user.admin? || user.roles_for_project(project).any? { |r| APPROVER_ROLES.include?(r.name) }
    end

    def editor?(user, project) = user.allowed_in_project?(:edit_work_packages, project)

    # Terkunci setelah Disahkan: isi tidak lagi bisa diubah kecuali lewat revisi.
    def locked?(wp) = wp.status.name == "Disahkan"

    # Perbaikan kecil (mis. typo) oleh pembuat dokumen yang punya masukan terbuka: boleh mengedit tanpa reviu ulang.
    def feedback_unlocked?(wp, user)
      ::Lpms3::Feedback.open.where(work_package_id: wp.id, author_id: user.id).exists?
    end

    # Bisa mengisi/mengedit isi aspek: belum terkunci, atau terkunci tetapi pembuat punya masukan terbuka.
    def content_editable?(wp, user, project)
      editor?(user, project) && (!locked?(wp) || feedback_unlocked?(wp, user))
    end

    # Persetujuan/revisi aspek hanya lewat rantai berjenjang di Tugas (Lpms3::ApprovalTask), bukan langkah langsung
    # di halaman fase: langkah "approve" satu orang ke Disahkan melewati Eselon 2/1 (ditutup 20 Nov 2026).
    CHAIN_ONLY_STEPS = %w[approve].freeze

    def can_step?(step, wp, user, project)
      return false if CHAIN_ONLY_STEPS.include?(step)

      cfg = STEPS[step] or return false
      return false unless cfg[:from].include?(wp.status.name)

      # Revisi: kewenangan ditentukan oleh tugas rantai yang menunggu (ApprovalTask#actions_for), dicek di controller.
      return true if step == "revision"

      editor?(user, project) && !locked?(wp)
    end
  end
end
