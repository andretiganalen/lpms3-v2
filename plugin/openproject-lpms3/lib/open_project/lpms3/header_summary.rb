# frozen_string_literal: true

module OpenProject::Lpms3
  # Ringkasan header gaya LenO untuk satu pengguna: Tasklist (Notifikasi Task), Reminder, Notifikasi (Notifikasi User),
  # serta nama dan jabatan untuk blok profil. Dipakai saat render halaman (hook head) dan endpoint penyegaran JSON.
  module HeaderSummary
    LIMIT = 8
    DUE_DAYS = 3

    module_function

    def build(user)
      tasks = tasklist(user)
      rem = reminders(user)
      unread = ::Notification.where(recipient_id: user.id, read_ian: false)
      { tasklist: { count: tasks.size, items: tasks.first(LIMIT) },
        reminder: { count: rem.size, items: rem.first(LIMIT) },
        notifikasi: { count: unread.count, items: notifications(unread.order(created_at: :desc).limit(LIMIT), user) } }
    end

    # Jabatan untuk blok profil: grup Fungsi pengguna, lalu peran global; kosong bila tidak ada.
    def jabatan(user)
      user.groups.order(:lastname).first&.name.presence ||
        ::Member.where(project_id: nil, user_id: user.id).joins(:roles).order("roles.name").pick("roles.name")
    end

    def routes = Rails.application.routes.url_helpers

    def item(title:, from: nil, text: nil, at: nil, href: nil, tone: nil, label: nil)
      { title:, from:, text:, at: at&.iso8601, waktu: label || (at && waktu(at)), href:, tone: }.compact
    end

    # Waktu relatif seperti LenO: "kemarin, 10:57", "2 hari lalu, 16:44", "baru saja".
    def waktu(time)
      t = time.in_time_zone(User.current.time_zone || Time.zone)
      days = (Date.current - t.to_date).to_i
      jam = t.strftime("%H:%M")
      return "#{(-days)} hari lagi, #{jam}" if days.negative?
      return (Time.current - time < 60 ? "baru saja" : "hari ini, #{jam}") if days.zero?
      return "kemarin, #{jam}" if days == 1

      "#{days} hari lalu, #{jam}"
    end

    def tasklist(user)
      inbox = ::Lpms3::Inbox
      list = []
      inbox.persetujuan(user).each do |t|
        list << item(title: t.work_package.subject, from: t.requested_by&.name, at: t.requested_at,
                     text: "Menunggu keputusan Anda (#{::Lpms3::KodeProyek.judul(t.project)})", href: routes.lpms3_tugas_path)
      end
      inbox.kickoff(user).each do |k|
        list << item(title: "Kick-Off #{::Lpms3::KodeProyek.judul(k.project)}", from: k.assigned_by&.name || "Sistem", at: k.updated_at,
                     text: k.state == "menunggu_analis" ? "Tunjuk Project Analis" : "Kirim undangan Kick-Off", href: routes.lpms3_tugas_path)
      end
      inbox.masukan(user).each do |f|
        list << item(title: f.work_package.subject, from: f.given_by&.name, at: f.given_at, text: "Masukan: #{f.body.to_s.truncate(80)}",
                     href: routes.lpms3_tugas_path)
      end
      inbox.tembusan(user).each do |t|
        list << item(title: t.work_package.subject, from: "Sistem", at: t.decided_at, text: "Dapat ditembuskan ke Direksi", href: routes.lpms3_tugas_path)
      end
      inbox.pemicu(user).each do |tr|
        list << item(title: tr.nama_proyek.presence || "Proyek baru #{tr.kode_proyek}",
                     from: tr.status == "diusulkan" ? tr.diusulkan_oleh&.name : "LenO",
                     at: tr.status == "diusulkan" ? tr.diusulkan_pada : tr.kiriman_terakhir_pada,
                     text: tr.status == "diusulkan" ? "Menunggu persetujuan registrasi" : "Menunggu registrasi proyek",
                     href: routes.lpms3_pemicu_path(tr))
      end
      inbox.wbs_pic(user).each do |n|
        list << item(title: "#{n.wbs_code} #{n.tasks}", from: ::Lpms3::KodeProyek.judul(n.project), at: n.updated_at,
                     text: "Tugaskan tim #{n.pic_unit&.name} sebagai PIC WBS", href: routes.lpms3_tugas_path)
      end
      inbox.anggota(user).each do |r|
        list << item(title: "#{r.user.name} — #{::Lpms3::KodeProyek.judul(r.project)}", from: r.requester.name, at: r.requested_at,
                     text: "Setujui anggota proyek baru", href: routes.lpms3_tugas_path)
      end
      inbox.kode_proyek(user).each do |pj|
        list << item(title: pj.name, from: "Sistem", at: pj.updated_at, text: "Isi Kode Proyek (XXX-XXXXXXXX); sementara #{::Lpms3::KodeProyek.prefix(pj)}",
                     href: "/projects/#{pj.identifier}/settings/general")
      end
      inbox.kontrak(user).each do |k|
        list << item(title: k[:finding].text, from: k[:project].name, at: Time.current,
                     text: "Peringatan kontrak", href: routes.lpms3_project_kontrak_path(k[:project]))
      end
      inbox.baseline_cr(user).each do |b|
        list << item(title: "#{b.label} — #{::Lpms3::KodeProyek.judul(b.project)}", from: "Editor WBS", at: b.updated_at,
                     text: "Ajukan Change Request ##{b.change_request_form_id} (BFR-001)", href: routes.work_package_path(b.change_request_form_id))
      end
      list.sort_by { |i| i[:at].to_s }.reverse
    end

    # Pengingat work package OpenProject buatan pengguna yang belum selesai, ditambah WP miliknya yang jatuh tempo <= 3 hari
    # atau sudah lewat (status belum tertutup).
    def reminders(user)
      list = ::Reminder.where(creator_id: user.id, completed_at: nil).where(remindable_type: "WorkPackage")
                       .order(:remind_at).limit(LIMIT).filter_map do |r|
        wp = ::WorkPackage.visible(user).find_by(id: r.remindable_id)
        next unless wp

        item(title: wp.subject, text: r.note.presence || "Pengingat work package ##{wp.id}", at: r.remind_at,
             href: routes.work_package_path(wp), tone: r.remind_at.past? ? "danger" : nil)
      end
      due = ::WorkPackage.visible(user).where(assigned_to_id: user.id).where.not(due_date: nil)
                         .where(due_date: ..(Date.current + DUE_DAYS)).joins(:status).where(statuses: { is_closed: false })
                         .order(:due_date).limit(LIMIT)
      due.each do |wp|
        late = wp.due_date < Date.current
        list << item(title: wp.subject, text: "#{::Lpms3::KodeProyek.judul(wp.project)} · #{late ? 'terlambat' : 'jatuh tempo'} #{I18n.l(wp.due_date, format: '%d %b %Y')}",
                     at: wp.due_date.in_time_zone, href: routes.work_package_path(wp), tone: late ? "danger" : "warning",
                     label: due_label(wp.due_date))
      end
      list
    end

    # Alasan notifikasi OpenProject dalam bahasa Indonesia (kunci tak dikenal: terjemahan OpenProject, lalu nama mentah).
    REASONS = { "mentioned" => "menyebut Anda", "assigned" => "menugaskan kepada Anda", "responsible" => "menjadikan Anda penanggung jawab",
                "watched" => "pembaruan yang Anda pantau", "commented" => "komentar baru", "created" => "dibuat", "processed" => "diproses",
                "prioritized" => "diprioritaskan", "scheduled" => "dijadwalkan", "subscribed" => "pembaruan langganan",
                "date_alert_start_date" => "tanggal mulai mendekat", "date_alert_due_date" => "tenggat mendekat",
                "shared" => "dibagikan kepada Anda", "reminder" => "pengingat" }.freeze

    def due_label(date)
      d = (date - Date.current).to_i
      return "hari ini" if d.zero?
      return "besok" if d == 1
      return "#{d} hari lagi" if d.positive?

      "terlambat #{-d} hari"
    end

    def notifications(scope, _user)
      reasons = I18n.t("js.notifications.reasons", default: {})
      scope.includes(:actor).map do |n|
        wp = n.resource_type == "WorkPackage" ? ::WorkPackage.find_by(id: n.resource_id) : nil
        op = reasons.is_a?(Hash) ? reasons[n.reason.to_s.to_sym] : nil
        reason = REASONS[n.reason.to_s] || (op.is_a?(String) ? op : n.reason.to_s.humanize)
        item(title: n.actor&.name || "Sistem", text: [wp && "#{wp.subject} (##{wp.id})", reason.to_s.downcase].compact.join(" · "),
             at: n.created_at, href: wp ? routes.work_package_path(wp) : routes.notifications_path)
      end
    end
  end
end
