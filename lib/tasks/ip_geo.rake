# frozen_string_literal: true

require "csv"

def default_ip_geo_path
  %w[IP2LOCATION-LITE-DB3.zip IP2LOCATION-LITE-DB3.CSV].map { |f| Rails.root.join(f) }.find { |p| File.file?(p) }
end

def normalize_csv_field(val)
  return nil if val.nil?
  s = val.to_s.gsub(/\A"|"\z/, "").strip
  (s.blank? || s == "-") ? nil : s
end

def row_to_attributes(row)
  {
    ip_from: row[0].to_s.gsub(/\A"|"\z/, "").strip.to_i,
    ip_to: row[1].to_s.gsub(/\A"|"\z/, "").strip.to_i,
    country_code: normalize_csv_field(row[2]),
    country_name: normalize_csv_field(row[3]),
    region: normalize_csv_field(row[4]),
    city: normalize_csv_field(row[5])
  }
end

def import_from_csv_io(io, limit: nil)
  batch = []
  total = 0
  max_rows = limit.to_i.positive? ? limit.to_i : nil
  csv = CSV.new(io, headers: false, liberal_parsing: true)
  csv.each do |row|
    break if max_rows && total >= max_rows

    batch << row_to_attributes(row)
    next unless batch.size >= 10_000

    to_insert = if max_rows && (total + batch.size) > max_rows
      batch.first(max_rows - total)
    else
      batch
    end
    IpGeoRange.insert_all(to_insert)
    total += to_insert.size
    puts "Imported #{total} rows..."
    batch = if max_rows && total >= max_rows
      []
    else
      batch.drop(to_insert.size)
    end
  end
  if batch.any?
    to_insert = if max_rows && (total + batch.size) > max_rows
      batch.first(max_rows - total)
    else
      batch
    end
    IpGeoRange.insert_all(to_insert) if to_insert.any?
    total += to_insert.size
  end
  total
end

namespace :ip_geo do
  desc "Import IP2Location LITE DB3 into ip_geo_ranges. Usage: rails ip_geo:import or rails ip_geo:import[/path/to/file.csv or file.zip]. Set IP_GEO_IMPORT_LIMIT (e.g. 1000) to cap rows for Heroku 10K limit."
  task :import, [ :path ] => :environment do |_t, args|
    path = args[:path].presence
    path = path ? File.expand_path(path) : default_ip_geo_path&.to_s

    unless path && File.file?(path)
      puts "File not found: #{path || '(no default)'}"
      puts "Download IP2Location LITE DB3 (CSV or zip), place at project root as IP2LOCATION-LITE-DB3.CSV or IP2LOCATION-LITE-DB3.zip, or pass path: rails ip_geo:import[/path/to/file.csv] or rails ip_geo:import[/path/to/file.zip]"
      exit 1
    end

    limit = ENV["IP_GEO_IMPORT_LIMIT"]&.to_i
    limit = nil if limit&.<= 0
    puts "Import limit: #{limit || 'none'}" if limit

    puts "Truncating ip_geo_ranges..."
    IpGeoRange.delete_all

    total = if path.end_with?(".zip")
      require "zip"
      Zip::File.open(path) do |zf|
        entry = zf.find_entry("IP2LOCATION-LITE-DB3.CSV") || zf.glob("*.csv").first
        unless entry
          puts "No CSV entry found in zip. Expected IP2LOCATION-LITE-DB3.CSV or any .csv file."
          exit 1
        end
        entry.get_input_stream { |io| import_from_csv_io(io, limit: limit) }
      end
    else
      File.open(path, "rb") { |io| import_from_csv_io(io, limit: limit) }
    end

    puts "Done. Total rows: #{total}"
  end
end
