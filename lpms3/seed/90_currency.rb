require_relative "00_data"
# Mata uang & kurs: peran global "Keuangan" (izin manage_currency_rates) dan mata uang budget = mata uang dasar korporasi. Idempoten.
if OpenProject::AccessControl.permissions.map(&:name).include?(:manage_currency_rates)
  role = GlobalRole.find_or_initialize_by(name: "Keuangan")
  role.permissions = [:manage_currency_rates]
  role.save!
  puts "  peran global Keuangan: #{role.permissions.map(&:to_s).join(',')}"
else
  puts "  izin manage_currency_rates belum terdaftar (plugin belum dimuat?)"
end
OpenProject::Lpms3::Fx.apply_base_to_budget_settings!
puts "currency ok: base=#{Lpms3::Currency.base&.code}, mata uang budget=#{Setting.costs_currency} (format #{Setting.costs_currency_format}), mata uang=#{Lpms3::Currency.count}"
