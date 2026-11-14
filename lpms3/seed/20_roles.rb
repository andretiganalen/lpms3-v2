require_relative "00_data"
avail = OpenProject::AccessControl.permissions.map(&:name).to_set
Lpms3Data::ROLES.each do |name, perms|
  r = ProjectRole.find_or_initialize_by(name: name)
  r.permissions = (perms.uniq & avail.to_a)
  r.save!
  skipped = perms - avail.to_a
  puts "  #{name}: #{r.permissions.size} izin#{skipped.any? ? " (tak tersedia: #{skipped.join(',')})" : ''}"
end
puts "roles ok: #{ProjectRole.where(name: Lpms3Data::ROLES.keys).count}/#{Lpms3Data::ROLES.size}"
