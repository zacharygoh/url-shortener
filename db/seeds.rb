# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Optional: load IP2Location data for click geolocation when a zip or CSV is present
ip_geo_path = ENV["IP_GEO_FILE"].presence || ENV["IP_GEO_ZIP"].presence
ip_geo_path ||= %w[IP2LOCATION-LITE-DB3.zip IP2LOCATION-LITE-DB3.CSV].map { |f| Rails.root.join(f) }.find { |p| File.file?(p) }&.to_s
if ip_geo_path
  Rake::Task["ip_geo:import"].reenable
  Rake::Task["ip_geo:import"].invoke(ip_geo_path)
else
  puts "IP geolocation: no zip/CSV found, skipping."
end
