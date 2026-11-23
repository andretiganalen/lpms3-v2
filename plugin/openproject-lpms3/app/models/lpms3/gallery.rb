# frozen_string_literal: true

module Lpms3
  # Galeri proyek: foto bukti dari laporan harian yang sudah TERKIRIM (bukan draft), dalam jendela waktu tertentu.
  # Hanya WP yang bisa dilihat pengguna, dan hanya lampiran bertipe gambar.
  module Gallery
    WINDOW_DAYS = 30

    module_function

    def photos(project, user, days: WINDOW_DAYS, today: Time.zone.today)
      wp_ids = ::WorkPackage.visible(user).where(project_id: project.id).pluck(:id)
      return [] if wp_ids.empty?

      reports = DailyReport.where(work_package_id: wp_ids, status: "terkirim")
                           .where(report_date: (today - days)..today)
                           .where("jsonb_array_length(photo_ids) > 0")
                           .order(report_date: :desc, id: :desc).includes(:work_package).to_a
      ids = reports.flat_map { |r| r.photo_ids.map(&:to_i) }.uniq
      attachments = ::Attachment.where(id: ids, content_type: %w[image/jpeg image/png image/gif image/webp]).index_by(&:id)

      reports.flat_map do |r|
        r.photo_ids.filter_map do |pid|
          a = attachments[pid.to_i] or next
          { id: a.id, filename: a.filename, date: r.report_date, progress: r.progress.to_f,
            wp_subject: r.work_package.subject, work_package_id: r.work_package_id }
        end
      end
    end

    def available?(project, user, **opts) = photos(project, user, **opts).any?
  end
end
