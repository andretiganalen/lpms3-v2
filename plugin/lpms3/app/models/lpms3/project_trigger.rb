# frozen_string_literal: true

module Lpms3
  # Pemicu proyek dari LenO (docs/plan/RANCANGAN-PEMICU-LENO.md). Satu baris per kode proyek.
  # 1.35 menerima dan mencatat; 1.37 registrasi (Admin Fungsi Pelaksanaan Proyek), persetujuan (Pejabat Eselon 1
  # Fungsi Pelaksanaan Proyek, bukan pengusul), dan pembuatan proyek dari template. Pembaca LPMS-2 (1.36) menyusul.
  class ProjectTrigger < ::ApplicationRecord
    class Error < StandardError; end

    self.table_name = "lpms3_project_triggers"

    STATUSES = %w[diterima data_siap data_gagal diusulkan dikembalikan disetujui proyek_dibuat selesai dibatalkan].freeze
    FINAL = %w[proyek_dibuat selesai dibatalkan].freeze
    # Klaim pembaca LPMS-2 yang lebih tua dari ini dianggap ditinggal; kiriman ulang LenO melepasnya.
    STALE_AFTER = 10.minutes
    KODE_RE = %r{\A[A-Z0-9][A-Z0-9._/-]{0,39}\z}

    REGISTRABLE = %w[diterima data_siap data_gagal dikembalikan].freeze
    CANCELLABLE = (REGISTRABLE + %w[diusulkan]).freeze
    PERM_REGISTER = :lpms3_register_project_trigger
    PERM_APPROVE = :lpms3_approve_project_trigger
    # Template yang boleh dipilih Admin => nilai "Pendekatan Delivery" (Purnajual tidak punya padanan).
    TEMPLATES = { "lpms3-predik" => "Prediktif", "lpms3-hibrid" => "Hibrid", "lpms3-contoh" => nil }.freeze
    PIMPRO_ROLE = "Pimpro"
    VP_ROLE = "Fungsi Pelaksanaan Proyek (Struktural)"

    belongs_to :project, optional: true
    belongs_to :pimpro, class_name: "User", optional: true
    belongs_to :vp, class_name: "User", optional: true
    belongs_to :diusulkan_oleh, class_name: "User", optional: true
    belongs_to :diputus_oleh, class_name: "User", optional: true
    has_many :events, -> { order(:created_at, :id) }, class_name: "Lpms3::ProjectTriggerEvent", inverse_of: :project_trigger

    validates :kode_proyek, presence: true, format: { with: KODE_RE }
    validates :status, inclusion: { in: STATUSES }
    validates :id_kiriman_terakhir, presence: true, length: { maximum: 100 }

    def self.normalize_kode(value) = value.to_s.strip.upcase

    # Wewenang dari keanggotaan peran global (langsung atau lewat grup). Admin LPMS tidak otomatis lolos.
    def self.holds_global_permission?(user, perm)
      return false unless user.is_a?(::User) && user.active?

      ids = [user.id] + user.group_ids
      ::Member.where(project_id: nil, user_id: ids)
              .joins(member_roles: { role: :role_permissions })
              .where(role_permissions: { permission: perm.to_s }).exists?
    end

    def self.registrar?(user) = holds_global_permission?(user, PERM_REGISTER)
    def self.approver?(user) = holds_global_permission?(user, PERM_APPROVE)

    # Pemicu yang menunggu tindakan user (Tugas & Notifikasi).
    def self.pending_for(user)
      list = []
      list += where(status: REGISTRABLE).or(where(status: "disetujui", project_id: nil)).to_a if registrar?(user)
      list += where(status: "diusulkan").where.not(diusulkan_oleh_id: user.id).to_a if approver?(user)
      list.uniq.sort_by(&:kiriman_terakhir_pada)
    end

    def self.kode_regexp
      re = ::ProjectCustomField.find_by(name: "Kode Proyek")&.regexp.presence
      re && Regexp.new(re)
    end

    def self.user_options = ::User.active.where(type: "User").order(:firstname, :lastname).to_a

    # Mencatat satu kiriman LenO. Mengembalikan [pemicu, hasil]; hasil :baru | :ulang | :final | :konflik.
    # Idempoten: id_kiriman yang sama dengan kiriman terakhir tidak mengubah apa pun.
    def self.receive!(kode_proyek:, id_kiriman:, lpms2_proyek_id: nil, nota: {}, dikirim_pada: nil, alamat: nil)
      kode = normalize_kode(kode_proyek)
      attempts = 0
      begin
        transaction do
          now = Time.current
          trigger = lock.find_by(kode_proyek: kode)
          if trigger.nil?
            trigger = create!(kode_proyek: kode, lpms2_proyek_id:, status: "diterima", id_kiriman_terakhir: id_kiriman,
                              jumlah_kiriman: 1, diterima_pada: now, kiriman_terakhir_pada: now, nota: nota || {}, dikirim_pada:)
            trigger.log!("diterima", to: "diterima", note: "Pemicu pertama dari LenO#{" (#{alamat})" if alamat}.")
            next [trigger, :baru]
          end

          if lpms2_proyek_id && trigger.lpms2_proyek_id && lpms2_proyek_id != trigger.lpms2_proyek_id
            trigger.log!("konflik", note: "Kiriman ditolak: LPMS-2 proyek ID #{lpms2_proyek_id} berbeda dari yang tercatat " \
                                          "(#{trigger.lpms2_proyek_id}).")
            next [trigger, :konflik]
          end
          next [trigger, :final] if FINAL.include?(trigger.status)
          next [trigger, :ulang] if trigger.id_kiriman_terakhir == id_kiriman

          attrs = { id_kiriman_terakhir: id_kiriman, jumlah_kiriman: trigger.jumlah_kiriman + 1, kiriman_terakhir_pada: now }
          attrs[:lpms2_proyek_id] = lpms2_proyek_id if trigger.lpms2_proyek_id.nil? && lpms2_proyek_id
          attrs[:nota] = nota if nota.present?
          attrs[:dikirim_pada] = dikirim_pada if dikirim_pada
          note = "Kiriman ulang ke-#{attrs[:jumlah_kiriman]}."
          if trigger.status == "diterima" && trigger.diklaim_pada && trigger.diklaim_pada < STALE_AFTER.ago
            note += " Klaim pembaca sejak #{trigger.diklaim_pada.iso8601} dianggap ditinggal dan dilepas."
            attrs[:diklaim_pada] = nil
          end
          trigger.update!(attrs)
          trigger.log!("kiriman_ulang", from: trigger.status, to: trigger.status, note:)
          [trigger, :ulang]
        end
      rescue ActiveRecord::RecordNotUnique
        # Dua kiriman pertama datang bersamaan: yang kalah membaca ulang baris pemenang.
        retry if (attempts += 1) < 2
        raise
      end
    end

    def may_view?(user) = user.admin? || self.class.registrar?(user) || self.class.approver?(user)
    def can_register?(user) = REGISTRABLE.include?(status) && self.class.registrar?(user)
    def can_decide?(user) = status == "diusulkan" && diusulkan_oleh_id != user.id && self.class.approver?(user)
    def can_cancel?(user) = CANCELLABLE.include?(status) && self.class.registrar?(user)
    def can_retry_creation?(user) = status == "disetujui" && project_id.nil? && self.class.registrar?(user)

    # Admin Fungsi Pelaksanaan Proyek mengusulkan registrasi: template, nama, Kode Proyek LPMS3, Pimpro, VP.
    def usulkan!(user, template:, nama_proyek:, kode_proyek_lpms3:, pimpro_id:, vp_id:, catatan: nil)
      transaction do
        lock!
        raise Error, "Hanya Admin Fungsi Pelaksanaan Proyek yang dapat meregistrasi proyek dari pemicu LenO." unless self.class.registrar?(user)
        raise Error, "Pemicu berstatus #{status}; registrasi tidak bisa diajukan." unless REGISTRABLE.include?(status)

        template = template.to_s
        raise Error, "Pilih template proyek." unless TEMPLATES.key?(template) && ::Project.templated.exists?(identifier: template)

        nama = nama_proyek.to_s.strip
        raise Error, "Nama proyek wajib diisi (maks. 255 karakter)." if nama.empty? || nama.length > 255

        kode = self.class.normalize_kode(kode_proyek_lpms3)
        re = self.class.kode_regexp
        raise Error, "Kode Proyek LPMS3 \"#{kode}\" tidak sesuai format #{re.source}." if re && !kode.match?(re)
        raise Error, "Kode Proyek LPMS3 #{kode} sudah dipakai proyek lain." if kode_used_by_project?(kode)
        if self.class.where(kode_proyek_lpms3: kode).where.not(id:).where.not(status: "dibatalkan").exists?
          raise Error, "Kode Proyek LPMS3 #{kode} sudah diusulkan pada pemicu lain."
        end

        pimpro = ::User.active.find_by(id: pimpro_id)
        vp = ::User.active.find_by(id: vp_id)
        raise Error, "Pilih Pimpro (pengguna aktif)." unless pimpro
        raise Error, "Pilih VP Fungsi Pelaksanaan Proyek (pengguna aktif)." unless vp

        from = status
        update!(status: "diusulkan", template_identifier: template, nama_proyek: nama, kode_proyek_lpms3: kode,
                pimpro:, vp:, catatan_usulan: catatan.to_s.strip.presence, diusulkan_oleh: user, diusulkan_pada: Time.current,
                diputus_oleh: nil, diputus_pada: nil, catatan_keputusan: nil)
        log!("diusulkan", from:, to: "diusulkan", actor: user,
             note: "Template #{template}, Pimpro #{pimpro.name}, VP #{vp.name}, kode #{kode}.#{" Catatan: #{catatan_usulan}" if catatan_usulan}")
      end
      self
    end

    # Pejabat Eselon 1 Fungsi Pelaksanaan Proyek memutus. Pengusul tidak boleh memutus usulannya sendiri (#678).
    def putuskan!(user, keputusan, catatan = nil)
      catatan = catatan.to_s.strip.presence
      transaction do
        lock!
        raise Error, "Hanya Pejabat Eselon 1 Fungsi Pelaksanaan Proyek yang dapat memutus registrasi." unless self.class.approver?(user)
        raise Error, "Registrasi ini tidak sedang menunggu keputusan." unless status == "diusulkan"
        raise Error, "Anda mengusulkan registrasi ini, jadi tidak dapat memutusnya sendiri." if diusulkan_oleh_id == user.id

        case keputusan.to_s
        when "setujui"
          update!(status: "disetujui", diputus_oleh: user, diputus_pada: Time.current, catatan_keputusan: catatan)
          log!("disetujui", from: "diusulkan", to: "disetujui", actor: user, note: catatan)
        when "kembalikan"
          raise Error, "Catatan wajib diisi saat mengembalikan registrasi." unless catatan

          update!(status: "dikembalikan", diputus_oleh: user, diputus_pada: Time.current, catatan_keputusan: catatan)
          log!("dikembalikan", from: "diusulkan", to: "dikembalikan", actor: user, note: catatan)
        else
          raise Error, "Keputusan tidak dikenal."
        end
      end
      enqueue_creation! if status == "disetujui"
      self
    end

    def batalkan!(user, alasan)
      alasan = alasan.to_s.strip.presence
      transaction do
        lock!
        raise Error, "Hanya Admin Fungsi Pelaksanaan Proyek yang dapat membatalkan pemicu." unless self.class.registrar?(user)
        raise Error, "Pemicu berstatus #{status}; tidak dapat dibatalkan." unless CANCELLABLE.include?(status)
        raise Error, "Alasan pembatalan wajib diisi." unless alasan

        from = status
        update!(status: "dibatalkan")
        log!("dibatalkan", from:, to: "dibatalkan", actor: user, note: alasan)
      end
      self
    end

    def coba_buat_ulang!(user)
      raise Error, "Pembuatan proyek tidak dapat diulang dari status ini." unless can_retry_creation?(user)

      log!("buat_ulang", from: status, to: status, actor: user, note: "Pembuatan proyek diminta ulang.")
      enqueue_creation!
    end

    def enqueue_creation! = ::Lpms3::BuatProyekDariPemicuJob.perform_later(id)

    # Dipanggil job. Idempoten: proyek hanya dibuat sekali; gagal = transaksi dibatalkan, galat dicatat, bisa dicoba ulang.
    def buat_proyek!
      transaction do
        lock!
        return project if project_id
        raise Error, "Pemicu berstatus #{status}, bukan disetujui." unless status == "disetujui"

        update_columns(pembuatan_dicoba_pada: Time.current)
        proj = create_project_from_template!
        update!(status: "proyek_dibuat", project: proj, pembuatan_galat: nil)
        log!("proyek_dibuat", from: "disetujui", to: "proyek_dibuat", sumber: "sistem",
             note: "Proyek #{proj.name} (#{proj.identifier}) dibuat dari #{template_identifier}.")
        proj
      end
    rescue StandardError => e
      msg = "#{e.class}: #{e.message}"[0, 1000]
      reload
      if project_id.nil?
        update_columns(pembuatan_galat: msg, updated_at: Time.current)
        log!("gagal_buat_proyek", from: status, to: status, sumber: "sistem", note: msg)
      end
      raise
    end

    def log!(kind, from: nil, to: nil, note: nil, actor: nil, sumber: actor ? "pengguna" : "leno")
      events.create!(kind:, from_status: from, to_status: to, note:, actor:, sumber:, created_at: Time.current)
    end

    private

    def kode_used_by_project?(kode)
      cf = ::ProjectCustomField.find_by(name: "Kode Proyek")
      cf && ::CustomValue.where(custom_field_id: cf.id, customized_type: "Project").where("upper(value) = ?", kode).exists?
    end

    def unique_identifier
      base = kode_proyek_lpms3.downcase.gsub(/[^a-z0-9\-_]+/, "-").first(90).delete_suffix("-") # = Kode Proyek (1.48)
      candidate = base
      n = 1
      candidate = "#{base}-#{n += 1}" while ::Project.exists?(identifier: candidate)
      candidate
    end

    def create_project_from_template!
      tpl = ::Project.templated.find_by!(identifier: template_identifier)
      res = ::User.execute_as(::User.system) do
        ::Projects::CopyService.new(user: ::User.system, source: tpl)
                               .call(target_project_params: { name: nama_proyek, identifier: unique_identifier },
                                     only: %i[members work_packages wiki_page_content])
      end
      raise Error, "Salin template gagal: #{res.errors.full_messages.join('; ')}" unless res.success?

      proj = res.result
      proj.update_columns(templated: false, public: false)
      assign_member!(proj, pimpro, PIMPRO_ROLE)
      assign_member!(proj, vp, VP_ROLE)
      fill_attributes!(proj)
      # Tim default berjenjang + atasan Eselon 2 Pimpro (1.39). Di dalam transaksi pembuatan: gagal = batal semua.
      ::Lpms3::TimProyek.sync!(proj)
      proj
    end

    def assign_member!(proj, user, role_name)
      role = ::ProjectRole.find_by!(name: role_name)
      member = ::Member.find_or_initialize_by(project: proj, principal: user)
      member.roles = (member.roles.to_a + [role]).uniq
      member.save!
    end

    def fill_attributes!(proj)
      cfs = ::ProjectCustomField.where(name: ["Kode Proyek", "LPMS-2 Proyek ID", "Pimpro", "Fungsi Pelaksanaan Proyek (struktural)",
                                             "Pendekatan Delivery"]).index_by(&:name)
      values = {}
      values[cfs["Kode Proyek"].id] = kode_proyek_lpms3 if cfs["Kode Proyek"]
      values[cfs["LPMS-2 Proyek ID"].id] = lpms2_proyek_id.to_s if cfs["LPMS-2 Proyek ID"] && lpms2_proyek_id
      values[cfs["Pimpro"].id] = pimpro_id.to_s if cfs["Pimpro"]
      values[cfs["Fungsi Pelaksanaan Proyek (struktural)"].id] = vp_id.to_s if cfs["Fungsi Pelaksanaan Proyek (struktural)"]
      if (pendekatan = TEMPLATES[template_identifier]) && (cf = cfs["Pendekatan Delivery"])
        opt = cf.custom_options.find_by(value: pendekatan)
        values[cf.id] = opt.id.to_s if opt
      end
      # LPMS 17: atribut proyek harus diaktifkan per proyek sebelum nilainya bisa disimpan. Aktifkan semua atribut
      # proyek agar Pimpro juga bisa mengisi atribut wajib lain (pelanggan, kontrak, dst.).
      ::ProjectCustomField.find_each do |cf|
        ::ProjectCustomFieldProjectMapping.find_or_create_by!(project_id: proj.id, custom_field_id: cf.id)
      end
      ::Project.find(proj.id).then do |p|
        p.custom_field_values = values
        set = p.custom_field_values.select { |cv| values.key?(cv.custom_field_id) }
        bad = set.reject(&:valid?)
        raise Error, "Atribut proyek tidak sah: #{bad.map { |cv| cv.custom_field.name }.join(', ')}" if bad.any?

        # Atribut wajib lain (pelanggan, kontrak, dst.) diisi Pimpro setelah proyek lahir / dari data LPMS-2 (1.36).
        p.save!(validate: false)
      end
    end

    public

    def api_json
      { id:, kode_proyek:, status:, diterima_pada: diterima_pada&.iso8601, diperbarui_pada: updated_at&.iso8601,
        jumlah_kiriman:, proyek_url: project && "/projects/#{project.identifier}" }
    end
  end
end
