# frozen_string_literal: true

module Lpms3
  # Monitoring Kontrak awal (1.42, docs/plan/RANCANGAN-KONTRAK-PENGADAAN.md).
  #  - Data dasar = atribut proyek (sumber yang juga dipakai Portfolio/LenO); adendum yang disahkan memperbaruinya.
  #  - Kelas kontrak SOP-004 dari nilai awal (lpms3.ref_kelas_kontrak).
  #  - Jaminan dengan masa berlaku, termin dengan syarat tagih, adendum SFR-025.
  #  - Temuan (findings) dipakai halaman proyek, monitoring lintas proyek, dan Tugas & Notifikasi.
  module Kontrak
    class Error < StandardError; end

    CF = { nomor: "Nomor Kontrak", tanggal: "Tanggal Kontrak", nilai: "Nilai Kontrak (IDR)", selesai: "Tanggal Selesai Kontrak",
           adendum: "Nomor Adendum Terakhir", pelanggan: "Nama Pelanggan", kode: "Kode Proyek", judul: "Judul Proyek Lengkap" }.freeze
    EDITOR_ROLES = ["Pimpro", "Project Analis", "Project admin", "Fungsi Pengawasan Proyek",
                    "Fungsi Pengendali Anggaran/Keuangan/Akuntansi", "Pengelola Biaya Proyek"].freeze
    KEUANGAN_ROLES = ["Fungsi Pengendali Anggaran/Keuangan/Akuntansi", "Pengelola Biaya Proyek"].freeze
    PENGESAH_ROLES = ["Pejabat Eselon 1", "Pejabat Eselon 2"].freeze
    JAMINAN_WARN_DAYS = 30
    KONTRAK_WARN_DAYS = 60
    TAGIH_SLA_DAYS = 30
    LAG_PP = 10
    KELAS_DEFAULT = [["Kecil", 0, 25_000_000_000], ["Sedang", 25_000_000_000, 100_000_000_000], ["Besar", 100_000_000_000, nil]].freeze
    SEVERITY = { kontrak_data: :high, kontrak_lewat: :high, jaminan_kadaluarsa: :high, termin_tertunda_bayar: :high,
                 go_nogo: :medium, kontrak_akan_berakhir: :medium, progres_tertinggal: :medium, jaminan_akan_berakhir: :medium,
                 jaminan_pelaksanaan: :medium, termin_layak_tagih: :medium, termin_total: :medium, termin_terlambat: :medium,
                 wbs_lewat_kontrak: :medium, adendum_draft: :medium, kelas_berubah: :medium }.freeze
    # Temuan yang menjadi tugas di Tugas & Notifikasi, dan peran penerimanya.
    TASK_FINDINGS = {
      jaminan_kadaluarsa: %w[Pimpro keuangan], jaminan_akan_berakhir: %w[Pimpro keuangan],
      termin_layak_tagih: %w[Pimpro keuangan], termin_tertunda_bayar: %w[keuangan Pimpro],
      kontrak_lewat: %w[Pimpro], kontrak_akan_berakhir: %w[Pimpro], adendum_draft: %w[pengesah]
    }.freeze

    Finding = Struct.new(:code, :severity, :text, :ref, keyword_init: true)

    module_function

    # ---------- Hak ----------

    def roles(user, project) = user.roles_for_project(project).map(&:name)
    def can_view?(user, project) = user.admin? || user.allowed_in_project?(:view_work_packages, project)
    def can_edit?(user, project) = user.logged? && (user.admin? || roles(user, project).intersect?(EDITOR_ROLES))
    def keuangan?(user, project) = user.admin? || roles(user, project).intersect?(KEUANGAN_ROLES + ["Pimpro"])
    def pengesah?(user, project) = user.admin? || roles(user, project).intersect?(PENGESAH_ROLES)

    # ---------- Data dasar ----------

    def cf_id(key) = ::ProjectCustomField.find_by(name: CF.fetch(key))&.id

    def cf(project, key)
      id = cf_id(key)
      id && ::CustomValue.where(customized_type: "Project", customized_id: project.id, custom_field_id: id).pick(:value).presence
    end

    def set_cf!(project, key, value)
      id = cf_id(key) or return
      cv = ::CustomValue.find_or_initialize_by(customized_type: "Project", customized_id: project.id, custom_field_id: id)
      cv.value = value.to_s
      cv.save!(validate: false)
    end

    def num(v) = v.blank? ? nil : BigDecimal(v.to_s.tr(",", "."))
    def date(v) = (v.present? ? Date.iso8601(v.to_s) : nil) rescue nil

    def info(project) = KontrakInfo.find_by(project_id: project.id)

    # Rekam nilai & tanggal selesai awal saat pertama kali kontrak dikelola (sebelum adendum mengubah atribut proyek).
    def ensure_info!(project)
      KontrakInfo.find_by(project_id: project.id) ||
        KontrakInfo.create!(project_id: project.id, nilai_awal: num(cf(project, :nilai)), tanggal_selesai_awal: date(cf(project, :selesai)),
                            tanggal_mulai: date(cf(project, :tanggal)), updated_at: Time.current)
    end

    def kelas_rows
      rows = ::ActiveRecord::Base.connection.select_rows("SELECT kelas, nilai_min, nilai_max FROM lpms3.ref_kelas_kontrak ORDER BY nilai_min")
      rows.any? ? rows.map { |k, a, b| [k, a.to_d, b&.to_d] } : KELAS_DEFAULT.map { |k, a, b| [k, a.to_d, b&.to_d] }
    rescue ActiveRecord::StatementInvalid
      KELAS_DEFAULT.map { |k, a, b| [k, a.to_d, b&.to_d] }
    end

    def kelas(nilai)
      return nil if nilai.nil?

      kelas_rows.find { |_, a, b| nilai >= a && (b.nil? || nilai < b) }&.first
    end

    # ---------- Ringkasan ----------

    def summary(project, today: Time.zone.today)
      inf = info(project)
      nilai_efektif = num(cf(project, :nilai))
      nilai_awal = inf&.nilai_awal || nilai_efektif
      selesai = date(cf(project, :selesai))
      mulai = inf&.tanggal_mulai || date(cf(project, :tanggal))
      jaminan = KontrakJaminan.where(project_id: project.id).order(:berlaku_sampai).to_a
      termin = KontrakTermin.where(project_id: project.id).order(:urutan).to_a
      adendum = KontrakAdendum.where(project_id: project.id).order(:urutan).to_a
      actual = WbsBaseline.actual_pct(project)
      wbs_root = WbsNode.find_by(project_id: project.id, parent_id: nil)
      g3 = gate_closed?(project, "G3")
      g4 = gate_closed?(project, "G4")
      elapsed = mulai && selesai && selesai > mulai ? (((today - mulai).to_f / (selesai - mulai)) * 100).clamp(0, 100).round(1) : nil
      ctx = { project:, today:, nilai: nilai_efektif, actual:, g3:, jaminan: }
      termin_rows = termin.map { |t| termin_row(t, ctx) }
      s = {
        project:, info: inf, nomor: cf(project, :nomor), tanggal: date(cf(project, :tanggal)), pelanggan: cf(project, :pelanggan),
        kode: cf(project, :kode) || project.identifier, judul: cf(project, :judul) || project.name,
        nilai_awal:, nilai_efektif:, kelas_awal: kelas(nilai_awal), kelas_efektif: kelas(nilai_efektif),
        mulai:, selesai_awal: inf&.tanggal_selesai_awal || selesai, selesai:, sisa_hari: selesai && (selesai - today).to_i,
        elapsed:, actual:, g3:, g4:, wbs_selesai: wbs_root&.date_plan_finish,
        jaminan:, termin: termin_rows, adendum:,
        termin_total_pct: termin.sum { |t| t.persen.to_f }.round(3),
        terbayar: termin_rows.select { |r| r[:t].status == "DIBAYAR" }.sum { |r| r[:t].nilai_bayar || r[:nilai] || 0 },
        tertagih: termin_rows.select { |r| r[:t].status == "DITAGIH" }.sum { |r| r[:nilai] || 0 }
      }
      s[:findings] = findings(s, today)
      s
    end

    def gate_closed?(project, code)
      ::WorkPackage.joins(:type, :status).where(project_id: project.id, types: { is_milestone: true }, statuses: { is_closed: true })
                   .where("work_packages.subject LIKE ?", "#{code} %").exists?
    end

    # Satu termin + nilai rupiah + kelayakan tagih menurut syaratnya.
    def termin_row(t, ctx)
      nilai = ctx[:nilai] && (ctx[:nilai] * t.persen.to_d / 100).round(2)
      layak, alasan = case t.syarat
                      when "UANG_MUKA"
                        ok = ctx[:jaminan].any? { |j| j.jenis == "UANG_MUKA" && j.aktif? && j.berlaku_sampai >= ctx[:today] }
                        [ok, ok ? "Jaminan uang muka aktif" : "Menunggu jaminan uang muka"]
                      when "PROGRES"
                        need = t.syarat_progres.to_f
                        ok = ctx[:actual] && ctx[:actual] >= need
                        [ok, "Progres #{ctx[:actual] || '—'} % dari syarat #{need.round(2)} %"]
                      when "AKTIVITAS"
                        n = t.wbs_node
                        ok = n&.done?
                        [ok, n ? "#{n.wbs_code} #{n.tasks}: #{(n.pct * 100).round} %" : "Aktivitas WBS belum dipilih"]
                      when "BAST" then [ctx[:g3], ctx[:g3] ? "G3 Serah terima tercapai" : "Menunggu G3 Serah terima"]
                      else [false, "Ditandai manual oleh Keuangan/Pimpro"]
                      end
      { t:, nilai:, layak: !!layak, alasan: }
    end

    def findings(s, today)
      f = []
      add = ->(code, text, ref = nil) { f << Finding.new(code:, severity: SEVERITY.fetch(code), text:, ref:) }
      missing = { "Nomor Kontrak" => s[:nomor], "Tanggal Kontrak" => s[:tanggal], "Nilai Kontrak" => s[:nilai_efektif],
                  "Tanggal Selesai Kontrak" => s[:selesai] }.select { |_, v| v.blank? }.keys
      add.(:kontrak_data, "Data kontrak belum lengkap: #{missing.join(', ')}.") if missing.any?
      inf = s[:info]
      if s[:kelas_awal] && (inf.nil? || inf.go_nogo == "BELUM")
        add.(:go_nogo, s[:kelas_awal] == "Kecil" ? "Persetujuan Kontrak Kecil (SFR-024) belum dicatat." : "Tinjauan Kontrak Go/No-Go kelas #{s[:kelas_awal]} (SFR-028) belum dicatat.")
      end
      if s[:kelas_awal] && s[:kelas_efektif] && s[:kelas_awal] != s[:kelas_efektif]
        add.(:kelas_berubah, "Adendum mengubah kelas kontrak #{s[:kelas_awal]} → #{s[:kelas_efektif]}; tinjauan adendum SOP-009 sesuai kelas baru.")
      end
      if s[:selesai]
        if s[:selesai] < today && !s[:g4]
          add.(:kontrak_lewat, "Masa kontrak berakhir #{s[:selesai]} (#{(today - s[:selesai]).to_i} hari lalu) dan proyek belum ditutup (G4).")
        elsif s[:sisa_hari] && s[:sisa_hari] <= KONTRAK_WARN_DAYS && s[:sisa_hari] >= 0 && (s[:actual] || 0) < 100
          add.(:kontrak_akan_berakhir, "Kontrak berakhir dalam #{s[:sisa_hari]} hari; progres #{s[:actual] || '—'} %. Pertimbangkan adendum waktu.")
        end
      end
      if s[:actual] && s[:elapsed] && s[:actual] + LAG_PP < s[:elapsed]
        add.(:progres_tertinggal, "Progres fisik #{s[:actual]} % tertinggal dari waktu kontrak berjalan #{s[:elapsed]} %.")
      end
      if s[:wbs_selesai] && s[:selesai] && s[:wbs_selesai] > s[:selesai]
        add.(:wbs_lewat_kontrak, "WBS selesai #{s[:wbs_selesai]} melewati tanggal selesai kontrak #{s[:selesai]}.")
      end
      s[:jaminan].select(&:aktif?).each do |j|
        if j.berlaku_sampai < today
          add.(:jaminan_kadaluarsa, "#{j.label} #{j.nomor} kedaluwarsa #{j.berlaku_sampai}; perpanjang atau tandai dikembalikan.", j)
        elsif j.sisa_hari(today) <= JAMINAN_WARN_DAYS
          add.(:jaminan_akan_berakhir, "#{j.label} #{j.nomor} berakhir dalam #{j.sisa_hari(today)} hari (#{j.berlaku_sampai}).", j)
        end
      end
      if s[:nomor].present? && !s[:g4] && s[:jaminan].none? { |j| j.jenis == "PELAKSANAAN" && j.aktif? }
        add.(:jaminan_pelaksanaan, "Belum ada Jaminan Pelaksanaan aktif.")
      end
      if s[:termin].any? && (s[:termin_total_pct] - 100).abs > 0.001
        add.(:termin_total, "Jumlah termin #{s[:termin_total_pct]} % (seharusnya 100 %).")
      end
      s[:termin].each do |r|
        t = r[:t]
        if t.status == "RENCANA" && r[:layak]
          add.(:termin_layak_tagih, "Termin #{t.urutan} (#{t.uraian}) layak ditagih: #{r[:alasan]}.", t)
        elsif t.status == "RENCANA" && t.rencana_tanggal && t.rencana_tanggal < today
          add.(:termin_terlambat, "Termin #{t.urutan} (#{t.uraian}) melewati rencana #{t.rencana_tanggal}; #{r[:alasan]}.", t)
        elsif t.status == "DITAGIH" && t.tanggal_tagih && t.tanggal_tagih + TAGIH_SLA_DAYS < today
          add.(:termin_tertunda_bayar, "Termin #{t.urutan} ditagih #{t.tanggal_tagih} (#{(today - t.tanggal_tagih).to_i} hari) belum dibayar.", t)
        end
      end
      s[:adendum].reject(&:disahkan?).each do |a|
        add.(:adendum_draft, "Adendum #{a.urutan} (#{a.nomor_dokumen}) menunggu pengesahan Pejabat Eselon 2/1.", a)
      end
      f.sort_by { |x| [x.severity == :high ? 0 : 1, x.code.to_s] }
    end

    # ---------- Lintas proyek ----------

    # Proyek yang boleh dilihat dan punya data kontrak (atribut Nomor/Nilai Kontrak atau catatan kontrak LPMS3).
    def projects(user)
      ids = KontrakInfo.pluck(:project_id) + KontrakJaminan.distinct.pluck(:project_id) + KontrakTermin.distinct.pluck(:project_id)
      [cf_id(:nomor), cf_id(:nilai)].compact.each do |id|
        ids += ::CustomValue.where(customized_type: "Project", custom_field_id: id).where.not(value: [nil, ""]).pluck(:customized_id)
      end
      ::Project.active.visible(user).where(id: ids.uniq).where(templated: false).to_a.select { |p| can_view?(user, p) }
    end

    def rows(user, today: Time.zone.today) = projects(user).map { |p| summary(p, today:) }.sort_by { |s| [s[:findings].any? { _1.severity == :high } ? 0 : 1, s[:kode].to_s] }

    # ---------- Tugas & Notifikasi ----------

    # Peringatan kontrak yang harus ditindaklanjuti user: [{ project:, finding: }].
    def tasks_for(user, today: Time.zone.today)
      return [] unless user&.logged?

      pids = ::Member.where(user_id: user.id).pluck(:project_id)
      return [] if pids.empty?

      out = []
      ::Project.active.where(id: pids).find_each do |p|
        next unless KontrakInfo.exists?(project_id: p.id) || KontrakJaminan.exists?(project_id: p.id) || KontrakTermin.exists?(project_id: p.id) ||
                    KontrakAdendum.exists?(project_id: p.id)

        r = roles(user, p)
        tags = []
        tags << "Pimpro" if r.include?("Pimpro")
        tags << "keuangan" if r.intersect?(KEUANGAN_ROLES)
        tags << "pengesah" if r.intersect?(PENGESAH_ROLES)
        next if tags.empty?

        summary(p, today:)[:findings].each do |f|
          who = TASK_FINDINGS[f.code] or next
          out << { project: p, finding: f } if who.intersect?(tags)
        end
      end
      out
    end

    # ---------- Perubahan ----------

    def save_info!(project, user, attrs)
      raise Error, "Anda tidak berwenang mengubah data kontrak." unless can_edit?(user, project)

      inf = ensure_info!(project)
      go = attrs[:go_nogo].presence || inf.go_nogo
      raise Error, "Status Go/No-Go tidak dikenal." unless KontrakInfo::GO_NOGO.include?(go)
      raise Error, "Posisi Len tidak dikenal." if attrs[:posisi_len].present? && !KontrakInfo::POSISI.include?(attrs[:posisi_len])
      raise Error, "Isi tanggal dan nomor tinjauan Go/No-Go." if go != "BELUM" && (date(attrs[:go_nogo_tanggal]).nil? || attrs[:go_nogo_nomor].blank?)

      inf.update!(tanggal_mulai: date(attrs[:tanggal_mulai]) || inf.tanggal_mulai, posisi_len: attrs[:posisi_len].presence,
                  term_of_payment: attrs[:term_of_payment].to_s.strip.presence, go_nogo: go,
                  go_nogo_tanggal: go == "BELUM" ? nil : date(attrs[:go_nogo_tanggal]), go_nogo_nomor: go == "BELUM" ? nil : attrs[:go_nogo_nomor].to_s.strip,
                  catatan: attrs[:catatan].to_s.strip.presence, updated_by: user.id, updated_at: Time.current)
      inf
    end

    def save_jaminan!(project, user, attrs, id: nil)
      raise Error, "Anda tidak berwenang mengubah jaminan." unless can_edit?(user, project)

      ensure_info!(project)
      j = id ? KontrakJaminan.find_by!(project_id: project.id, id:) : KontrakJaminan.new(project_id: project.id, created_by: user.id)
      raise Error, "Jenis jaminan tidak dikenal." unless KontrakJaminan::JENIS.key?(attrs[:jenis].to_s)
      raise Error, "Nomor jaminan wajib diisi." if attrs[:nomor].blank?
      sampai = date(attrs[:berlaku_sampai]) or raise(Error, "Tanggal berlaku sampai wajib diisi (YYYY-MM-DD).")
      dari = date(attrs[:berlaku_dari])
      raise Error, "Berlaku sampai tidak boleh sebelum berlaku dari." if dari && sampai < dari

      j.assign_attributes(jenis: attrs[:jenis], nomor: attrs[:nomor].to_s.strip, penerbit: attrs[:penerbit].to_s.strip.presence,
                          nilai: num(attrs[:nilai]), persen: num(attrs[:persen]), berlaku_dari: dari, berlaku_sampai: sampai,
                          catatan: attrs[:catatan].to_s.strip.presence, updated_by: user.id, updated_at: Time.current)
      j.save!
      j
    rescue ArgumentError
      raise Error, "Nilai atau persen jaminan bukan angka."
    end

    def set_jaminan_status!(project, user, id, status)
      raise Error, "Anda tidak berwenang mengubah jaminan." unless can_edit?(user, project)
      raise Error, "Status jaminan tidak dikenal." unless KontrakJaminan::STATUS.key?(status.to_s)

      KontrakJaminan.find_by!(project_id: project.id, id:).tap { |j| j.update!(status:, updated_by: user.id, updated_at: Time.current) }
    end

    def save_termin!(project, user, attrs, id: nil)
      raise Error, "Anda tidak berwenang mengubah termin." unless can_edit?(user, project)

      ensure_info!(project)
      t = id ? KontrakTermin.find_by!(project_id: project.id, id:) : KontrakTermin.new(project_id: project.id, created_by: user.id)
      raise Error, "Termin yang sudah ditagih tidak dapat diubah." if t.persisted? && t.status != "RENCANA"

      persen = num(attrs[:persen])
      raise Error, "Persen termin harus 0–100." unless persen&.positive? && persen <= 100
      raise Error, "Uraian termin wajib diisi." if attrs[:uraian].blank?
      syarat = attrs[:syarat].to_s
      raise Error, "Syarat tagih tidak dikenal." unless KontrakTermin::SYARAT.key?(syarat)

      sp = num(attrs[:syarat_progres])
      raise Error, "Isi syarat progres (0–100 %)." if syarat == "PROGRES" && !(sp && sp >= 0 && sp <= 100)

      node = nil
      if syarat == "AKTIVITAS"
        node = WbsNode.find_by(project_id: project.id, id: attrs[:syarat_wbs_node_id])
        raise Error, "Pilih aktivitas WBS untuk syarat tagih." unless node
      end
      others = KontrakTermin.where(project_id: project.id).where.not(id: t.id).sum(:persen)
      raise Error, format("Jumlah termin menjadi %.2f %% (maks. 100 %%).", others + persen) if others + persen > 100.0001

      t.assign_attributes(urutan: t.urutan || (KontrakTermin.where(project_id: project.id).maximum(:urutan).to_i + 1),
                          uraian: attrs[:uraian].to_s.strip, persen:, syarat:, syarat_progres: syarat == "PROGRES" ? sp : nil,
                          syarat_wbs_node_id: node&.id, rencana_tanggal: date(attrs[:rencana_tanggal]),
                          catatan: attrs[:catatan].to_s.strip.presence, updated_by: user.id, updated_at: Time.current)
      t.save!
      t
    rescue ArgumentError
      raise Error, "Persen atau syarat progres bukan angka."
    end

    # Rencana → Ditagih → Dibayar. Ditagih mewajibkan syarat terpenuhi (kecuali MANUAL).
    def tagih!(project, user, id, nomor:, tanggal: nil)
      raise Error, "Hanya Keuangan atau Pimpro yang mencatat penagihan." unless keuangan?(user, project)

      s = summary(project)
      r = s[:termin].find { |x| x[:t].id == id.to_i } or raise(Error, "Termin tidak ditemukan.")
      t = r[:t]
      raise Error, "Termin #{t.urutan} sudah #{KontrakTermin::STATUS[t.status].downcase}." unless t.status == "RENCANA"
      raise Error, "Syarat tagih termin #{t.urutan} belum terpenuhi: #{r[:alasan]}." unless r[:layak] || t.syarat == "MANUAL"
      raise Error, "Nomor tagihan/invoice wajib diisi." if nomor.blank?

      t.update!(status: "DITAGIH", nomor_tagihan: nomor.to_s.strip, tanggal_tagih: date(tanggal) || Date.current,
                updated_by: user.id, updated_at: Time.current)
      t
    end

    def bayar!(project, user, id, nilai: nil, tanggal: nil)
      raise Error, "Hanya Keuangan atau Pimpro yang mencatat pembayaran." unless keuangan?(user, project)

      t = KontrakTermin.find_by!(project_id: project.id, id:)
      raise Error, "Termin #{t.urutan} belum ditagih." unless t.status == "DITAGIH"

      nilai_t = (num(cf(project, :nilai)) || 0) * t.persen.to_d / 100
      t.update!(status: "DIBAYAR", tanggal_bayar: date(tanggal) || Date.current, nilai_bayar: num(nilai) || nilai_t.round(2),
                updated_by: user.id, updated_at: Time.current)
      t
    rescue ArgumentError
      raise Error, "Nilai bayar bukan angka."
    end

    def destroy_draft!(project, user, kind, id)
      raise Error, "Anda tidak berwenang." unless can_edit?(user, project)

      case kind
      when "termin"
        t = KontrakTermin.find_by!(project_id: project.id, id:)
        raise Error, "Termin yang sudah ditagih tidak dapat dihapus." unless t.status == "RENCANA"

        t.destroy!
      when "adendum"
        a = KontrakAdendum.find_by!(project_id: project.id, id:)
        raise Error, "Adendum yang sudah disahkan tidak dapat dihapus." if a.disahkan?

        a.destroy!
      when "jaminan" then KontrakJaminan.find_by!(project_id: project.id, id:).destroy!
      else raise Error, "Jenis data tidak dikenal."
      end
    end

    def save_adendum!(project, user, attrs, id: nil)
      raise Error, "Anda tidak berwenang mencatat adendum." unless can_edit?(user, project)

      ensure_info!(project)
      a = id ? KontrakAdendum.find_by!(project_id: project.id, id:) : KontrakAdendum.new(project_id: project.id, created_by: user.id)
      raise Error, "Adendum yang sudah disahkan tidak dapat diubah." if a.disahkan?
      raise Error, "Nomor dokumen adendum wajib diisi." if attrs[:nomor_dokumen].blank?
      tgl = date(attrs[:tanggal]) or raise(Error, "Tanggal adendum wajib diisi (YYYY-MM-DD).")
      raise Error, "Uraian perubahan wajib diisi." if attrs[:uraian].blank?

      nilai = num(attrs[:nilai_baru])
      selesai = date(attrs[:tanggal_selesai_baru])
      lingkup = ActiveModel::Type::Boolean.new.cast(attrs[:lingkup]) || false
      raise Error, "Adendum harus mengubah nilai, tanggal selesai, atau lingkup." if nilai.nil? && selesai.nil? && !lingkup
      raise Error, "Nilai kontrak baru harus lebih dari 0." if nilai && !nilai.positive?

      cr = attrs[:change_request_id].present? ? ::WorkPackage.find_by(project_id: project.id, id: attrs[:change_request_id]) : nil
      raise Error, "Change Request tidak ditemukan di proyek ini." if attrs[:change_request_id].present? && cr.nil?

      a.assign_attributes(urutan: a.urutan || (KontrakAdendum.where(project_id: project.id).maximum(:urutan).to_i + 1),
                          nomor_dokumen: attrs[:nomor_dokumen].to_s.strip, tanggal: tgl, uraian: attrs[:uraian].to_s.strip,
                          nilai_baru: nilai, tanggal_selesai_baru: selesai, lingkup:, sfr025_nomor: attrs[:sfr025_nomor].to_s.strip.presence,
                          change_request_id: cr&.id, updated_at: Time.current)
      a.save!
      a
    rescue ArgumentError
      raise Error, "Nilai kontrak baru bukan angka."
    end

    # Pengesahan oleh Pejabat Eselon 2/1 (bukan pencatat): atribut proyek Nilai/Tanggal Selesai/Nomor Adendum diperbarui.
    def sahkan_adendum!(project, user, id)
      raise Error, "Hanya Pejabat Eselon 2/1 yang mengesahkan adendum." unless pengesah?(user, project)

      KontrakAdendum.transaction do
        a = KontrakAdendum.lock.find_by!(project_id: project.id, id:)
        raise Error, "Adendum sudah disahkan." if a.disahkan?
        raise Error, "Pencatat adendum tidak boleh mengesahkannya sendiri." if a.created_by == user.id
        raise Error, "Sahkan adendum sebelumnya terlebih dahulu." if KontrakAdendum.where(project_id: project.id, status: "DRAFT").where("urutan < ?", a.urutan).exists?

        ensure_info!(project)
        a.update!(nilai_sebelum: num(cf(project, :nilai)), tanggal_selesai_sebelum: date(cf(project, :selesai)),
                  status: "DISAHKAN", disahkan_by: user.id, disahkan_at: Time.current, updated_at: Time.current)
        set_cf!(project, :nilai, a.nilai_baru.to_s("F")) if a.nilai_baru
        set_cf!(project, :selesai, a.tanggal_selesai_baru.iso8601) if a.tanggal_selesai_baru
        set_cf!(project, :adendum, a.nomor_dokumen)
        a
      end
    end
  end
end
