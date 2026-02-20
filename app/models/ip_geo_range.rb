# frozen_string_literal: true

# Read-only model for IP geolocation range lookups (IP2Location LITE DB3).
# Data loaded via: rails ip_geo:import[/path/to/IP2LOCATION-LITE-DB3.CSV]
class IpGeoRange < ApplicationRecord
  def self.lookup(ip_int)
    where("ip_from <= ? AND ip_to >= ?", ip_int, ip_int).limit(1).pick(:country_code, :country_name, :region, :city)
  end
end
