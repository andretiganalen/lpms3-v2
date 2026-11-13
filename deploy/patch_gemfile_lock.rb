# Menambahkan plugin path (openproject-lpms3) ke Gemfile.lock tanpa resolusi jaringan.
# Alasan: `bundle install` di image slim ingin mengambil gem git grup dev (pry) dan git tidak tersedia.
lock = File.read("Gemfile.lock")
name = "openproject-lpms3"
version = ARGV.fetch(0)
path = ARGV.fetch(1)
abort("#{name} sudah ada di Gemfile.lock") if lock.include?("#{name} (")

lock = lock.sub(/^PATH\n/, "PATH\n  remote: #{path}\n  specs:\n    #{name} (#{version})\n\nPATH\n")
lock = lock.sub(/^  openproject-webhooks!\n/, "  #{name}!\n  openproject-webhooks!\n") # urutan abjad
lock = lock.sub(/^  openproject-webhooks \(1\.0\.0\)\n/, "  #{name} (#{version})\n  openproject-webhooks (1.0.0)\n")
[/^PATH\n  remote: #{Regexp.escape(path)}/, /^  #{name}!$/, /^  #{name} \(#{Regexp.escape(version)}\)$/].each do |re|
  abort("patch gagal: #{re}") unless lock.match?(re)
end
File.write("Gemfile.lock", lock)
puts "Gemfile.lock: #{name} #{version} ditambahkan"
