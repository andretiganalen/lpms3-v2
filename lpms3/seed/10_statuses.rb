require_relative "00_data"
names = Lpms3Data::TYPES.values.flat_map(&:first).uniq
base = (Status.maximum(:position) || 0) + 1
names.each_with_index do |n, i|
  s = Status.find_or_initialize_by(name: n)
  s.is_closed = Lpms3Data::CLOSED.include?(n)
  s.position ||= base + i
  s.save!
end
puts "statuses ok: #{Status.where(name: names).count}/#{names.size}"
