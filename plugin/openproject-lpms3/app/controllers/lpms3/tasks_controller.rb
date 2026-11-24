# frozen_string_literal: true

module Lpms3
  # Tugas persetujuan berjenjang: daftar tugas (jumlah + dari siapa, kapan, harus apa) dan langkah keputusan.
  class TasksController < ::ApplicationController
    layout "global" # sidebar global seperti LenO
    AT = ::Lpms3::ApprovalTask

    before_action :require_login
    no_authorization_required! :index, :ajukan, :langkah, :masukan, :selesai_masukan, :ajukan_semua, :tembusan, :kickoff_tunjuk, :kickoff_undang, :anggota

    def index
      @tasks = AT.pending_for(User.current)
      @count = ::Lpms3::Inbox.count(User.current)
      @masukan = ::Lpms3::Feedback.open_for(User.current)
      @tembusan_candidates = AT.tembusan_candidates(User.current)
      @tembusan_list = AT.tembusan_for(User.current)
      @kickoff_tunjuk = ::Lpms3::Kickoff.pending_for(User.current).select { |k| k.state == "menunggu_analis" }
      @kickoff_undang = ::Lpms3::Kickoff.pending_for(User.current).select { |k| k.state == "menunggu_undangan" }
      @pemicu = ::Lpms3::Inbox.pemicu(User.current)
      @wbs_pic = ::Lpms3::Inbox.wbs_pic(User.current)
      @baseline_cr = ::Lpms3::Inbox.baseline_cr(User.current)
      @kontrak = ::Lpms3::Inbox.kontrak(User.current)
      @anggota = ::Lpms3::Inbox.anggota(User.current)
      @isian = isian_saya(User.current)
    end

    # Permintaan anggota proyek (1.44): Pimpro menyetujui atau menolak.
    def anggota
      req = ::Lpms3::MemberRequest.pending.find(params[:id])
      req.decide!(User.current, params[:keputusan] == "setujui", params[:catatan])
      flash[:notice] = "#{req.user.name} #{req.state == 'disetujui' ? 'menjadi anggota' : 'ditolak sebagai anggota'} #{req.project.name}."
      redirect_to lpms3_tugas_path
    rescue ::Lpms3::MemberRequest::Error, ActiveRecord::RecordNotFound => e
      flash[:error] = e.is_a?(ActiveRecord::RecordNotFound) ? "Permintaan tidak ditemukan." : e.message
      redirect_to lpms3_tugas_path
    end

    # Pengaju mengirim dokumen (WP) untuk persetujuan. Hanya dokumen yang bisa dilihat pengguna.
    # Isian milik user (pembuat/penerima tugas) yang belum tertutup dan belum menunggu keputusan: siap diajukan.
    private def isian_saya(user)
      return [] unless user.logged?

      pending_ids = AT.pending.select(:work_package_id)
      ::WorkPackage.visible(user).joins(:status).where(statuses: { is_closed: false })
                   .where("work_packages.author_id = :u OR work_packages.assigned_to_id = :u", u: user.id)
                   .where.not(id: pending_ids).where.not("work_packages.subject LIKE ?", "[T%")
                   .includes(:project, :type, :status).order(updated_at: :desc).limit(25).to_a
    end

    def ajukan
      wp = ::WorkPackage.visible(User.current).find_by(id: params[:wp_id])
      return render_404 unless wp
      return deny_access unless User.current.allowed_in_project?(:edit_work_packages, wp.project)

      AT.ajukan!(wp, User.current, note: params[:catatan])
      flash[:notice] = "Dokumen diajukan. Menunggu peninjauan."
      redirect_to lpms3_tugas_path
    rescue AT::Error => e
      flash[:error] = e.message
      redirect_to lpms3_tugas_path
    end

    def langkah
      task = AT.pending.find_by(id: params[:id])
      return render_404 unless task

      task.act!(User.current, params[:tindakan].to_s, params[:catatan])
      flash[:notice] = "Keputusan tersimpan."
      redirect_to lpms3_tugas_path
    rescue AT::Error => e
      flash[:error] = e.message
      redirect_to lpms3_tugas_path
    rescue ActiveRecord::StaleObjectError
      flash[:error] = "Data sudah berubah. Muat ulang lalu coba lagi."
      redirect_to lpms3_tugas_path
    end
    # Pembaca (termasuk Baca Saja) memberi masukan ke pembuat dokumen. Tanpa reviu ulang.
    def masukan
      wp = ::WorkPackage.find_by(id: params[:wp_id])
      return render_404 unless wp

      ::Lpms3::Feedback.give!(wp, User.current, params[:masukan])
      flash[:notice] = "Masukan terkirim ke pembuat dokumen."
      redirect_back fallback_location: lpms3_tugas_path
    rescue ::Lpms3::Feedback::Error => e
      flash[:error] = e.message
      redirect_back fallback_location: lpms3_tugas_path
    end

    # Pembuat menandai masukan sudah diperbaiki.
    def selesai_masukan
      fb = ::Lpms3::Feedback.open.find_by(id: params[:id])
      return render_404 unless fb

      fb.resolve!(User.current, params[:catatan])
      flash[:notice] = "Masukan ditandai sudah diperbaiki."
      redirect_to lpms3_tugas_path
    rescue ::Lpms3::Feedback::Error => e
      flash[:error] = e.message
      redirect_to lpms3_tugas_path
    end
    # Ajukan sekaligus semua aspek PMP proyek yang siap (belum diajukan dan belum dikunci).
    def ajukan_semua
      project = ::Project.find_by(identifier: params[:project_id]) || ::Project.find_by(id: params[:project_id])
      return render_404 unless project
      return deny_access unless User.current.allowed_in_project?(:edit_work_packages, project)

      ap = ::OpenProject::Lpms3::Aspects
      pending = AT.pending.where(project_id: project.id).pluck(:work_package_id)
      targets = ap.scope(project, User.current).to_a.reject { |wp| pending.include?(wp.id) || ap.locked?(wp) }
      done = 0
      targets.each do |wp|
        AT.ajukan!(wp, User.current)
        done += 1
      rescue AT::Error
        next
      end
      flash[:notice] = "#{done} aspek diajukan. Menunggu peninjauan Pimpro."
      redirect_to lpms3_project_phase_path(project, "inisiasi", "aspek")
    end
    # Pejabat Eselon 1 menembuskan dokumen final ke Direksi (untuk diketahui).
    def tembusan
      task = AT.final_approved.find_by(id: params[:id])
      return render_404 unless task

      task.tembusan!(User.current)
      flash[:notice] = "Dokumen ditembuskan ke Direksi untuk diketahui."
      redirect_to lpms3_tugas_path
    rescue AT::Error => e
      flash[:error] = e.message
      redirect_to lpms3_tugas_path
    end
    def kickoff_tunjuk
      k = ::Lpms3::Kickoff.find_by(id: params[:id])
      return render_404 unless k

      analis = ::User.find_by(id: params[:analis_id])
      return render_404 unless analis

      k.assign!(User.current, analis)
      flash[:notice] = "#{analis.name} ditunjuk sebagai Project Analis. Menunggu undangan Kick-Off."
      redirect_to lpms3_tugas_path
    rescue ::Lpms3::Kickoff::Error => e
      flash[:error] = e.message
      redirect_to lpms3_tugas_path
    end

    def kickoff_undang
      k = ::Lpms3::Kickoff.find_by(id: params[:id])
      return render_404 unless k

      waktu = params[:waktu].present? ? Time.zone.parse(params[:waktu].to_s) : nil
      k.undang!(User.current, scheduled_at: waktu, agenda: params[:agenda])
      flash[:notice] = "Undangan Kick-Off terkirim."
      redirect_to lpms3_tugas_path
    rescue ::Lpms3::Kickoff::Error => e
      flash[:error] = e.message
      redirect_to lpms3_tugas_path
    end
  end
end
