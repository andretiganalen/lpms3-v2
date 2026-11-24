# frozen_string_literal: true

module Lpms3
  # Editor WBS Template LPMS (1.40, docs/plan/RANCANGAN-WBS-BOBOT-MEMBER.md §4):
  #  - Bobot cascading: weight = weight induk × weigh_factor; Σ weigh_factor saudara = 100 %.
  #  - Default weigh_factor = kurva normal atas urutan anak; diatur ulang saat anak ditambah/dihapus.
  #  - PIC = anggota proyek, atau unit Eselon 1 Fungsi yang lalu menugaskan timnya.
  #  - Setiap node (kecuali Level 0) tertaut ke satu work package: Gantt dan Kalender ikut berubah.
  # Semua perubahan lewat mutate!: satu transaksi + kunci per proyek; nomor WBS, bobot, progres, dan WP disegarkan.
  module Wbs
    class Error < StandardError; end

    EDITOR_ROLES = ["Pimpro", "Project Analis", "Project admin"].freeze
    TOLERANCE = 0.0001
    TEXT_FIELDS = %w[tasks notes resource priority].freeze
    LEAF_FIELDS = %w[date_plan_start date_plan_finish date_actual_start date_actual_finish pct_complete].freeze
    FIELDS = (TEXT_FIELDS + LEAF_FIELDS + %w[pic]).freeze
    # Aktivitas selesai (100 %) dibekukan (1.41): kolom rekam ini tidak dapat diubah lagi.
    FROZEN_FIELDS = (%w[tasks] + LEAF_FIELDS).freeze

    module_function

    # Kurva normal atas posisi anak (x di [-2, 2]); dibulatkan 4 desimal, sisa ke anak tengah agar Σ = 1 tepat.
    def bell_curve(n)
      return [] if n <= 0
      return [1.0] if n == 1

      g = (0...n).map do |i|
        x = -2.0 + (4.0 * (i + 0.5) / n)
        Math.exp(-x * x / 2)
      end
      total = g.sum
      w = g.map { |v| (v / total).round(4) }
      mid = (n - 1) / 2
      w[mid] = (w[mid] + (1.0 - w.sum)).round(4)
      w
    end

    def can_view?(user, project) = user.admin? || user.allowed_in_project?(:view_work_packages, project)

    def can_edit?(user, project)
      return false unless user&.logged?
      return true if user.admin?

      user.roles_for_project(project).map(&:name).intersect?(EDITOR_ROLES)
    end

    def kode_proyek(project)
      cf = ::ProjectCustomField.find_by(name: "Kode Proyek")
      v = cf && ::CustomValue.find_by(customized_type: "Project", customized_id: project.id, custom_field_id: cf.id)&.value
      v.presence || project.identifier
    end

    def nodes(project) = WbsNode.where(project_id: project.id).order(:sort_order, :id).to_a

    # Baris tabel urut kedalaman (DFS): [{ node:, leaf:, depth: }].
    def rows(project)
      all = nodes(project)
      by_parent = all.group_by(&:parent_id)
      out = []
      walk = lambda do |n, depth|
        kids = by_parent[n.id] || []
        out << { node: n, leaf: kids.empty?, depth:, children: kids }
        kids.each { |k| walk.(k, depth + 1) }
      end
      (by_parent[nil] || []).each { |r| walk.(r, 0) }
      out
    end

    def ensure_root!(project)
      WbsNode.find_by(project_id: project.id, parent_id: nil) || mutate!(project, ::User.system) do
        WbsNode.find_by(project_id: project.id, parent_id: nil) || create_node!(project, parent: nil, tasks: project.name, sort: 0, wf: 1)
      end.reload
    end

    # ---------- Operasi ----------

    def add_child!(project, actor, parent_id:, after_id: nil)
      mutate!(project, actor) do
        parent = find!(project, parent_id)
        raise Error, "Kedalaman maksimum Level #{WbsNode::MAX_DEPTH}." if depth_of(parent) >= WbsNode::MAX_DEPTH
        if parent.children.empty? && !parent.root? && parent.pct.positive?
          raise Error, "Aktivitas #{parent.wbs_code} sudah berprogres; tidak dapat dipecah menjadi sub-tugas."
        end

        kids = parent.children.to_a
        pos = after_id ? (kids.index { |k| k.id == after_id.to_i } || (kids.size - 1)) + 1 : kids.size
        kids.each_with_index { |k, i| k.update_columns(sort_order: i >= pos ? i + 1 : i) }
        node = create_node!(project, parent:, tasks: "Tugas baru", sort: pos, wf: 0)
        redistribute!(parent.reload)
        node
      end
    end

    def delete!(project, actor, node_id)
      mutate!(project, actor) do
        node = find!(project, node_id)
        raise Error, "Level 0 tidak dapat dihapus." if node.root?
        raise Error, "Hapus sub-tugas #{node.wbs_code} terlebih dahulu." if node.children.any?
        raise Error, "#{node.wbs_code} sudah berprogres; tidak dapat dihapus." if node.pct.positive?
        raise Error, "#{node.wbs_code} punya riwayat progres; tidak dapat dihapus." if progress_history?(node)

        parent = node.parent
        destroy_node!(node)
        redistribute!(parent.reload)
        nil
      end
    end

    def move!(project, actor, node_id, dir)
      mutate!(project, actor) do
        node = find!(project, node_id)
        raise Error, "Level 0 tidak dapat dipindah." if node.root?

        kids = node.parent.children.to_a
        i = kids.index(node)
        j = dir.to_s == "up" ? i - 1 : i + 1
        if j.between?(0, kids.size - 1)
          kids[i], kids[j] = kids[j], kids[i]
          kids.each_with_index { |k, idx| k.update_columns(sort_order: idx) }
        end
        node
      end
    end

    # Ubah satu sel. Mengembalikan node.
    def update_field!(project, actor, node_id, field, value)
      field = field.to_s
      raise Error, "Kolom #{field} tidak dapat diubah." unless FIELDS.include?(field)

      mutate!(project, actor) do
        node = find!(project, node_id)
        leaf = node.children.empty?
        raise Error, "#{label(field)} diisi pada aktivitas (baris tanpa sub-tugas); induk dihitung dari anaknya." if LEAF_FIELDS.include?(field) && !leaf
        raise Error, "Level 0 mengikuti nama proyek." if node.root? && field != "notes"
        if FROZEN_FIELDS.include?(field) && frozen?(node)
          raise Error, "#{node.wbs_code} sudah selesai (100 %) dan dibekukan; #{label(field)} tidak dapat diubah."
        end

        case field
        when "tasks"
          v = value.to_s.strip
          raise Error, "Nama tugas wajib diisi." if v.empty?
          raise Error, "Nama tugas maksimal 200 karakter." if v.length > 200

          node.tasks = v
        when "notes" then node.notes = value.to_s.strip.presence
        when "resource"
          v = value.to_s.strip.presence
          raise Error, "Resource tidak dikenal." if v && !WbsNode::RESOURCES.include?(v)

          node.resource = v
        when "priority"
          v = value.to_s.strip.presence
          raise Error, "Prioritas harus Low, Medium, atau High." if v && !WbsNode::PRIORITIES.include?(v)

          node.priority = v
        when "date_plan_start", "date_plan_finish", "date_actual_start", "date_actual_finish"
          node[field] = parse_date(value)
          check_dates!(node)
        when "pct_complete" then set_complete!(node, value)
        when "pic" then set_pic!(project, node, value.to_s)
        end
        node.updated_by = actor.id
        node.save!
        node
      end
    end

    # Bobot anak satu induk sekaligus: { child_id => persen }. Σ wajib 100 %.
    def set_weights!(project, actor, parent_id, percents)
      mutate!(project, actor) do
        parent = find!(project, parent_id)
        kids = parent.children.to_a
        raise Error, "#{parent.wbs_code} tidak punya sub-tugas." if kids.empty?

        values = kids.to_h do |k|
          raw = percents[k.id.to_s] || percents[k.id]
          raise Error, "Bobot #{k.wbs_code} belum diisi." if raw.blank?

          v = Float(raw.to_s.tr(",", ".")) / 100.0
          raise Error, "Bobot #{k.wbs_code} harus 0–100 %." unless v.between?(0, 1)

          [k, v]
        rescue ArgumentError
          raise Error, "Bobot #{k.wbs_code} bukan angka."
        end
        total = values.values.sum
        raise Error, format("Jumlah bobot sub-tugas %s harus 100 %% (sekarang %.2f %%).", parent.wbs_code, total * 100) if (total - 1).abs > TOLERANCE

        frozen_ids = frozen_ids(kids)
        values.each do |k, v|
          if frozen_ids.include?(k.id) && (v - k.weigh_factor.to_f).abs > 0.000001
            raise Error, "Bobot #{k.wbs_code} dibekukan karena aktivitas sudah selesai (100 %)."
          end
        end

        values.each { |k, v| k.update_columns(weigh_factor: v.round(6), updated_by: actor.id, updated_at: Time.current) }
        parent
      end
    end

    def bell_curve!(project, actor, parent_id)
      mutate!(project, actor) do
        parent = find!(project, parent_id)
        redistribute!(parent)
        parent
      end
    end

    # ---------- PIC dari unit Eselon 1 ----------

    # Aktivitas yang menunggu penugasan tim oleh Kepala/Admin unit Eselon 1 (user).
    def pic_pending_for(user)
      return [] unless user&.logged?

      pos_ids = ::Lpms3::UserPosition.active_on.where(user_id: user.id).pluck(:position_id)
      unit_ids = ::Lpms3::Position.where(id: pos_ids, grade: %w[STRUKTURAL_ES1 ADMIN_TEKNIS]).pluck(:unit_id)
      unit_ids = ::Lpms3::OrgUnit.where(id: unit_ids, grade: "ES1").pluck(:id)
      return [] if unit_ids.empty?
      WbsNode.where(pic_unit_id: unit_ids, pic_user_id: nil).includes(:project, :pic_unit).order(:project_id, :wbs_code).to_a
    end

    def can_assign_from_unit?(user, node)
      node.pic_unit_id.present? && pic_pending_for(user).any? { |n| n.id == node.id }
    end

    # Tim yang dapat ditugaskan: pemegang jabatan aktif di unit Eselon 1 dan seluruh unit di bawahnya.
    def unit_team(unit)
      ids = subtree_ids(unit)
      ::User.active.where(id: ::Lpms3::UserPosition.active_on.where(position_id: ::Lpms3::Position.where(unit_id: ids).select(:id))
                                                   .select(:user_id))
            .order(:firstname, :lastname).to_a
    end

    def assign_from_unit!(actor, node_id, user_id)
      node = WbsNode.find(node_id)
      raise Error, "Anda bukan Kepala/Admin unit #{node.pic_unit&.name}." unless can_assign_from_unit?(actor, node)

      user = unit_team(node.pic_unit).find { |u| u.id == user_id.to_i }
      raise Error, "Pengguna bukan anggota tim #{node.pic_unit.name}." unless user

      mutate!(node.project, actor) do
        role = ::ProjectRole.find_by!(name: "Tim Proyek")
        member = ::Member.find_or_initialize_by(project: node.project, principal: user)
        member.roles = (member.roles.to_a + [role]).uniq
        member.save!
        node.reload.update!(pic_user_id: user.id, pic_assigned_by: actor.id, pic_assigned_at: Time.current, updated_by: actor.id)
        node
      end
    end

    # PIC wajib anggota proyek dan harus dapat menjadi assignee WP. Peran kerja LPMS3 yang dapat melihat WP diberi izin
    # work_package_assigned (tidak menambah akses). Peran baca-saja tidak. Idempoten; dipanggil seed 80_tim_proyek.
    READ_ONLY_ROLES = ["Reader", "Pembaca (Informed)", "Non member", "Anonymous", "Work package viewer"].freeze

    def ensure_assignable_roles!
      ::ProjectRole.where.not(name: READ_ONLY_ROLES).find_each.filter_map do |role|
        perms = role.permissions.map(&:to_sym)
        next unless perms.include?(:view_work_packages) && !perms.include?(:work_package_assigned)

        role.add_permission!(:work_package_assigned)
        role.name
      end
    end

    # ---------- Pilihan kolom ----------

    def member_options(project)
      ::User.active.where(id: ::Member.where(project_id: project.id).select(:user_id)).where(type: "User")
            .order(:firstname, :lastname).to_a
    end

    def eselon1_units
      st = ::Lpms3::OrgStructure.active.first
      st ? st.units.where(grade: "ES1").order(:code).to_a : []
    end

    def warnings(rows)
      acts = rows.select { |r| r[:leaf] && !r[:node].root? }
      w = []
      no_pic = acts.count { |r| r[:node].pic_user_id.nil? && r[:node].pic_unit_id.nil? }
      w << "#{no_pic} aktivitas belum punya PIC." if no_pic.positive?
      no_date = acts.count { |r| r[:node].date_plan_start.nil? || r[:node].date_plan_finish.nil? }
      w << "#{no_date} aktivitas belum punya tanggal rencana." if no_date.positive?
      rows.reject { |r| r[:leaf] }.each do |r|
        total = r[:children].sum { |k| k.weigh_factor.to_f }
        w << format("Bobot sub-tugas %s berjumlah %.2f %%.", r[:node].wbs_code, total * 100) if (total - 1).abs > TOLERANCE
      end
      w
    end

    # ---------- Internal ----------

    def mutate!(project, actor)
      result = nil
      WbsNode.transaction do
        WbsNode.connection.execute("SELECT pg_advisory_xact_lock(#{lock_key(project)})")
        result = yield
        refresh!(project, actor)
        WbsBaseline.sync_draft!(project, actor)
      end
      result
    end

    def lock_key(project) = 7_340_000_000 + project.id

    def find!(project, id)
      WbsNode.find_by(project_id: project.id, id:) || raise(Error, "Baris WBS tidak ditemukan.")
    end

    def depth_of(node)
      d = 0
      n = node
      while n.parent_id
        d += 1
        n = n.parent
      end
      d
    end

    def create_node!(project, parent:, tasks:, sort:, wf:)
      WbsNode.create!(project_id: project.id, parent_id: parent&.id, wbs_code: "~new-#{SecureRandom.hex(6)}",
                      level: parent ? "Level 1" : "Level 0", tasks:, weigh_factor: wf, weight: parent ? 0 : 1,
                      sort_order: sort, evidence_folder: "/", updated_by: ::User.current&.id)
    end

    # Kurva normal atas anak yang belum beku; anak beku mempertahankan bobotnya dan sisanya dibagi ke yang lain.
    def redistribute!(parent)
      kids = parent.children.to_a
      frozen = frozen_ids(kids)
      free = kids.reject { |k| frozen.include?(k.id) }
      return if free.empty?

      if frozen.empty?
        bell_curve(kids.size).each_with_index { |w, i| kids[i].update_columns(weigh_factor: w) }
        return
      end

      rest = [1.0 - kids.select { |k| frozen.include?(k.id) }.sum { |k| k.weigh_factor.to_f }, 0.0].max
      w = bell_curve(free.size).map { |x| (x * rest).round(6) }
      mid = (free.size - 1) / 2
      w[mid] = [(w[mid] + (rest - w.sum)).round(6), 0].max
      free.each_with_index { |k, i| k.update_columns(weigh_factor: w[i]) }
    end

    def frozen?(node) = WbsDoneSnapshot.exists?(wbs_node_id: node.id)
    def frozen_ids(nodes) = WbsDoneSnapshot.where(wbs_node_id: nodes.map(&:id)).pluck(:wbs_node_id).to_set

    # Hapus node beserta work package-nya (dipakai delete! dan pemulihan baseline).
    def destroy_node!(node)
      wp = node.work_package
      node.destroy!
      return unless wp

      res = ::WorkPackages::DeleteService.new(user: ::User.system, model: wp).call
      raise Error, "Work package #{wp.id} gagal dihapus: #{res.errors.full_messages.join('; ')}" unless res.success?
    end

    # Rekam aktivitas yang baru mencapai 100 % (sekali; tidak ikut berubah oleh baseline berikutnya).
    def snapshot_done!(project, rows, actor)
      done = rows.select { |r| r[:leaf] && !r[:node].root? && r[:node].done? }.map { |r| r[:node] }
      return if done.empty?

      have = frozen_ids(done)
      fresh = done.reject { |n| have.include?(n.id) }.map do |n|
        { wbs_node_id: n.id, project_id: project.id, work_package_id: n.work_package_id, wbs_code: n.wbs_code, tasks: n.tasks,
          level: n.level, weigh_factor: n.weigh_factor, weight: n.weight, date_plan_start: n.date_plan_start,
          date_plan_finish: n.date_plan_finish, date_actual_start: n.date_actual_start, date_actual_finish: n.date_actual_finish,
          harga_pekerjaan: n.harga_pekerjaan, pic_user_id: n.pic_user_id, frozen_by: actor&.id, frozen_at: Time.current }
      end
      WbsDoneSnapshot.insert_all!(fresh) if fresh.any?
    end

    def progress_history?(node)
      WbsNode.connection.select_value("SELECT 1 FROM lpms3.wbs_progress WHERE wbs_node_id = #{node.id.to_i} LIMIT 1").present?
    end

    def parse_date(value)
      value.present? ? Date.iso8601(value.to_s.strip) : nil
    rescue Date::Error
      raise Error, "Tanggal tidak valid (format YYYY-MM-DD)."
    end

    def check_dates!(node)
      if node.date_plan_start && node.date_plan_finish && node.date_plan_finish < node.date_plan_start
        raise Error, "Date Plan Finish tidak boleh sebelum Date Plan Start."
      end
      if node.date_actual_start && node.date_actual_finish && node.date_actual_finish < node.date_actual_start
        raise Error, "Date Actual Finish tidak boleh sebelum Date Actual Start."
      end
      raise Error, "Date Actual Start tidak boleh di masa depan." if node.date_actual_start&.future?
      raise Error, "Date Actual Finish tidak boleh di masa depan." if node.date_actual_finish&.future?
    end

    # % Complete hanya 0/25/50/75/100 (sheet Settings). Di atas 0 wajib ada bukti (lampiran pada work package).
    def set_complete!(node, value)
      v = Float(value.to_s.delete("%").tr(",", ".")) rescue raise(Error, "% Complete tidak valid.")
      v /= 100.0 if v > 1
      step = WbsNode::COMPLETE_STEPS.find { |s| (s - v).abs < 0.001 }
      raise Error, "% Complete harus 0, 25, 50, 75, atau 100." unless step
      if step.positive? && (node.work_package.nil? || node.work_package.attachments.none?)
        raise Error, "Unggah bukti (Evidence Files) pada work package #{node.wbs_code} sebelum mengisi % Complete."
      end

      node.pct_complete = step
      node.date_actual_start ||= Date.current if step.positive?
      node.date_actual_finish = step >= 1 ? (node.date_actual_finish || Date.current) : nil
    end

    # "u:<user_id>" anggota proyek, "f:<unit_id>" unit Eselon 1, atau kosong.
    def set_pic!(project, node, value)
      kind, id = value.split(":", 2)
      case kind
      when "u"
        user = member_options(project).find { |u| u.id == id.to_i }
        raise Error, "PIC harus anggota proyek." unless user

        node.pic_user_id = user.id
        node.pic_unit_id = nil
        node.pic_assigned_by = ::User.current&.id
        node.pic_assigned_at = Time.current
      when "f"
        unit = eselon1_units.find { |u| u.id == id.to_i }
        raise Error, "Fungsi induk harus unit Eselon 1 struktur aktif." unless unit

        node.pic_unit_id = unit.id
        node.pic_user_id = nil
        node.pic_assigned_by = nil
        node.pic_assigned_at = nil
      when nil, ""
        node.pic_user_id = nil
        node.pic_unit_id = nil
      else
        raise Error, "Pilihan PIC tidak dikenal."
      end
    end

    def subtree_ids(unit)
      ids = [unit.id]
      frontier = [unit.id]
      7.times do
        frontier = ::Lpms3::OrgUnit.where(parent_id: frontier).pluck(:id)
        break if frontier.empty?

        ids += frontier
      end
      ids
    end

    def label(field) = { "date_plan_start" => "Date Plan Start", "date_plan_finish" => "Date Plan Finish",
                         "date_actual_start" => "Date Actual Start", "date_actual_finish" => "Date Actual Finish",
                         "pct_complete" => "% Complete" }.fetch(field, field)

    # Nomor WBS, level, bobot, progres, tanggal induk, folder bukti, lalu work package.
    def refresh!(project, actor)
      rows = rows(project)
      return if rows.empty?

      kode = kode_proyek(project)
      codes = {}
      by_id = rows.to_h { |r| [r[:node].id, r] }
      rows.each do |r|
        n = r[:node]
        codes[n.id] = if n.root? then "0"
                      else
                        idx = by_id[n.parent_id][:children].index { |k| k.id == n.id } + 1
                        by_id[n.parent_id][:node].root? ? idx.to_s : "#{codes[n.parent_id]}.#{idx}"
                      end
      end
      # Dua tahap agar unik (project_id, wbs_code) tidak bentrok saat penomoran bergeser.
      changed = rows.select { |r| r[:node].wbs_code != codes[r[:node].id] }
      changed.each { |r| r[:node].update_columns(wbs_code: "~#{r[:node].id}") }
      changed.each { |r| r[:node].wbs_code = codes[r[:node].id] }

      rows.reverse_each do |r| # anak dulu: tanggal & progres induk dari anak
        n = r[:node]
        next if r[:leaf]

        kids = r[:children].map { |k| by_id[k.id][:node] }
        n.date_plan_start = kids.filter_map(&:date_plan_start).min
        n.date_plan_finish = kids.filter_map(&:date_plan_finish).max
        n.date_actual_start = kids.filter_map(&:date_actual_start).min
        n.date_actual_finish = kids.all?(&:date_actual_finish) ? kids.map(&:date_actual_finish).max : nil
        n.pct_complete = nil
      end
      rows.each do |r| # induk dulu: weight cascading
        n = r[:node]
        n.weight = n.root? ? 1 : (by_id[n.parent_id][:node].weight.to_f * n.weigh_factor.to_f).round(9)
        n.weigh_factor = 1 if n.root?
        n.level = WbsNode.level_label(r[:depth], r[:leaf])
      end
      rows.reverse_each do |r|
        n = r[:node]
        n.pct_progress = if r[:leaf]
                           n.root? ? 0 : (n.weight.to_f * n.pct).round(9)
                         else
                           r[:children].sum { |k| by_id[k.id][:node].pct_progress.to_f }.round(9)
                         end
        n.evidence_folder = "/#{kode}/#{n.wbs_code} #{n.tasks}".first(500)
      end
      rows.each do |r|
        n = r[:node]
        n.save!(touch: false) if n.changed?
      end
      snapshot_done!(project, rows, actor)
      sync_work_packages!(project, rows, by_id, actor)
    end

    def sync_work_packages!(project, rows, by_id, actor)
      raise Error, "Modul Work packages belum aktif di proyek ini." unless project.module_enabled?("work_package_tracking")

      types = project.enabled_types.to_a
      type = types.find { |t| t.name == "Task" } || types.first
      raise Error, "Proyek belum mengaktifkan tipe work package." unless type
      note = "Editor WBS LPMS3 oleh #{actor&.name || 'Sistem'}"
      # Induk dulu agar parent_id anak sudah ada.
      rows.each do |r|
        n = r[:node]
        next if n.root?

        parent_node = by_id[n.parent_id][:node]
        attrs = { subject: "#{n.wbs_code} #{n.tasks}".first(255), description: n.notes.to_s,
                  assigned_to_id: n.pic_user_id, parent_id: parent_node.root? ? nil : parent_node.work_package_id }
        if r[:leaf]
          # Tanggal WBS = tanggal kalender (template); tanpa ignore_non_working_days OpenProject menggeser tanggal akhir pekan
          # sehingga selalu berbeda dan setiap refresh menulis jurnal + notifikasi baru ke PIC (temuan 1.41).
          attrs.merge!(start_date: n.date_plan_start, due_date: n.date_plan_finish, schedule_manually: true,
                       ignore_non_working_days: true, done_ratio: (n.pct * 100).round)
        else
          attrs[:schedule_manually] = false
        end
        wp = n.work_package
        if wp.nil?
          res = ::WorkPackages::CreateService.new(user: ::User.system)
                                             .call(project:, type:, journal_notes: note, **attrs.compact)
          raise Error, "Work package #{n.wbs_code} gagal dibuat: #{res.errors.full_messages.join('; ')}" unless res.success?

          n.update_columns(work_package_id: res.result.id)
        else
          diff = attrs.reject { |k, v| wp.public_send(k) == v || (k == :description && wp.description.to_s == v) }
          next if diff.empty?

          res = ::WorkPackages::UpdateService.new(user: ::User.system, model: wp).call(**diff, journal_notes: note)
          raise Error, "Work package #{n.wbs_code} gagal diperbarui: #{res.errors.full_messages.join('; ')}" unless res.success?
        end
      end
    end
  end
end
