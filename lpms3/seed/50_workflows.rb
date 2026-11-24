require_relative "00_data"
st  = ->(n) { Status.find_by!(name: n) }
role = ->(n) { ProjectRole.find_by!(name: n) }
count = 0
mk = lambda do |type, r, from, to|
  Workflow.find_or_create_by!(type_variant_id: type.default_variant.id, role_id: r.id, old_status_id: st[from].id, new_status_id: st[to].id)
  count += 1
end
Lpms3Data::TYPES.each do |tname, (statuses, _c, _m)|
  type = Type.find_by!(name: tname)
  # WP baru OpenProject selalu berstatus default "New"; beri transisi New -> status awal tipe
  # agar pembuat dapat memilih status awal yang benar di form (CR: hanya Pimpro).
  owners = (Lpms3Data::REGISTER_OWNERS[tname] || []).select { |rn| ProjectRole.exists?(name: rn) }
  (tname == "Change Request" ? ["Pimpro"] : Lpms3Data::GENERAL_ROLES + (Lpms3Data::DECISION_FLOWS[tname] ? [] : owners))
    .each { |rn| mk.(type, role[rn], "New", statuses.first) }
  if (flows = Lpms3Data::DECISION_FLOWS[tname])
    # Sinkron penuh: hanya transisi di DECISION_FLOWS yang boleh ada; sisanya (dari seed lama) dihapus.
    keep = flows.flat_map { |rn, pairs| pairs.map { |f, t| [role[rn].id, st[f].id, st[t].id] } }
    keep.each { |rid, o, n| Workflow.find_or_create_by!(type_variant_id: type.default_variant.id, role_id: rid, old_status_id: o, new_status_id: n) }
    count += keep.size
    removed = Workflow.where(type_variant_id: type.default_variant.id).reject { |w| keep.include?([w.role_id, w.old_status_id, w.new_status_id]) }
    removed.each(&:destroy!)
    puts "#{tname}: #{keep.size} transisi, #{removed.size} dihapus"
  elsif tname == "Change Request"
    Lpms3Data::CR_FLOW.each { |rn, pairs| pairs.each { |f, t| mk.(type, role[rn], f, t) } }
  else
    # semua transisi antar-status untuk peran umum (sederhana; dapat diperketat PMO)
    (Lpms3Data::GENERAL_ROLES + owners).uniq.each do |rn|
      statuses.permutation(2).each { |f, t| mk.(type, role[rn], f, t) }
    end
  end
end
puts "workflows ok: #{Workflow.where(type_variant_id: TypeVariant.where(type_id: Type.where(name: Lpms3Data::TYPES.keys).select(:id))).count} (diproses #{count})"
# 1.44: "Admin Pejabat Eselon 2" bekerja seperti Tim Proyek (plus kelola anggota): salin seluruh transisi Tim Proyek.
if (adm2 = ProjectRole.find_by(name: "Admin Pejabat Eselon 2"))
  src = ProjectRole.find_by!(name: "Tim Proyek")
  n = 0
  Workflow.where(role_id: src.id).find_each do |w|
    Workflow.find_or_create_by!(type_variant_id: w.type_variant_id, role_id: adm2.id, old_status_id: w.old_status_id, new_status_id: w.new_status_id)
    n += 1
  end
  puts "Admin Pejabat Eselon 2: #{n} transisi (salinan Tim Proyek)"
end
