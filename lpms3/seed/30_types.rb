require_relative "00_data"
pos = (Type.maximum(:position) || 0) + 1
Lpms3Data::TYPES.each_with_index do |(name, (_st, hex, ms)), i|
  color = Color.find_or_create_by!(name: "LPMS3 #{name}") { |c| c.hexcode = hex }
  t = Type.find_or_initialize_by(name: name)
  t.is_milestone = !!ms
  t.is_in_roadmap = false
  t.color = color
  t.position ||= pos + i
  t.save!
end
puts "types ok: #{Type.where(name: Lpms3Data::TYPES.keys).count}/#{Lpms3Data::TYPES.size}"
