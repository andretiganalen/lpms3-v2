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
  (tname == "Change Request" ? ["Pimpro"] : Lpms3Data::GENERAL_ROLES).each { |rn| mk.(type, role[rn], "New", statuses.first) }
  if tname == "Change Request"
    Lpms3Data::CR_FLOW.each { |rn, pairs| pairs.each { |f, t| mk.(type, role[rn], f, t) } }
  else
    # semua transisi antar-status untuk peran umum (sederhana; dapat diperketat PMO)
    Lpms3Data::GENERAL_ROLES.each do |rn|
      statuses.permutation(2).each { |f, t| mk.(type, role[rn], f, t) }
    end
  end
end
puts "workflows ok: #{Workflow.where(type_variant_id: TypeVariant.where(type_id: Type.where(name: Lpms3Data::TYPES.keys).select(:id))).count} (diproses #{count})"
