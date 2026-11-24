# Struktur BOP-001 untuk setiap proyek aktif (idempoten). Proyek lama/dummy yang masih kosong mendapat struktur end-to-end
# dalam keadaan BELUM MULAI, sehingga semua menu fase, Langkah BOP-001, WBS, Kontrak, dan Pengadaan terisi:
#  - modul dan tipe work package mengikuti template (Hibrid bila "Pendekatan Delivery" = Hibrid, selain itu Prediktif);
#  - langkah [Tn-m], gerbang G1–G4, dan 9 aspek "Dokumen Rencana — …" dari template, berstatus awal (tanpa tanggal);
#  - WBS Level 0 (draft Baseline 0), catatan kontrak dari atribut proyek, dan tim default berjenjang (Lpms3::TimProyek).
# Ruang informasi tanpa modul Work packages (mis. wiki "info-umum") dilewati. Item yang sudah ada (subjek sama) tidak diubah.
admin = User.where(admin: true, status: User.statuses[:active], type: "User").where.not(login: "lpms3-bridge").order(:id).first || User.system
User.current = admin
tpls = { "Prediktif" => Project.find_by(identifier: "lpms3-tpl-prediktif"), "Hibrid" => Project.find_by(identifier: "lpms3-tpl-hibrid") }
delivery = ProjectCustomField.find_by(name: "Pendekatan Delivery")
STEP_OR_DOC = /\A(\[T\d-\d+\]|G\d — |Dokumen Rencana — )/
total = Hash.new(0)

Project.active.where(templated: false).order(:id).each do |proj|
  unless proj.module_enabled?("work_package_tracking") || proj.enabled_types.any?
    puts "  #{proj.identifier}: dilewati (ruang informasi tanpa Work packages)"
    next
  end
  pend = delivery && proj.custom_values.find { |cv| cv.custom_field_id == delivery.id }
  pend_name = pend && delivery.custom_options.find_by(id: pend.value)&.value
  tpl = tpls[pend_name] || tpls["Prediktif"]
  next unless tpl

  proj.enabled_module_names = (proj.enabled_module_names | tpl.enabled_module_names)
  tpl.enabled_types.each { |t| ProjectType.find_or_create_by!(project: proj, type: t) }
  proj.save!(validate: false)
  proj.reload

  existing = WorkPackage.where(project_id: proj.id).pluck(:subject).to_set
  made = 0
  WorkPackage.where(project_id: tpl.id).includes(:type, :status).order(:id).each do |t|
    next unless t.subject.match?(STEP_OR_DOC)
    next if existing.include?(t.subject)

    res = WorkPackages::CreateService.new(user: User.system)
                                     .call(project: proj, type: t.type, subject: t.subject, description: t.description.to_s,
                                           journal_notes: "Struktur BOP-001 dari template #{tpl.name}")
    unless res.success?
      puts "  #{proj.identifier}: gagal #{t.subject}: #{res.errors.full_messages.join('; ')}"
      next
    end
    res.result.update_columns(status_id: t.status_id) if t.status_id && res.result.status_id != t.status_id
    made += 1
  end
  Lpms3::Wbs.ensure_root!(proj) if defined?(Lpms3::Wbs)
  Lpms3::Kontrak.ensure_info!(proj) if defined?(Lpms3::Kontrak) && Lpms3::Kontrak.cf(proj, :nomor)
  tim = Lpms3::TimProyek.sync!(proj)
  total[:wp] += made
  total[:proyek] += 1
  puts "  #{proj.identifier}: +#{made} langkah/gerbang/aspek (template #{tpl.identifier}), tim +#{tim.added.size}, member #{proj.members.count}"
end
puts "struktur proyek ok: #{total[:proyek]} proyek, #{total[:wp]} work package dibuat"
