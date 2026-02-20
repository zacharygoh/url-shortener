# app/services/geo_ip_service.rb
# IP geolocation via ip_geo_ranges (IP2Location LITE DB3). Load data with: rails ip_geo:import[/path/to/file.csv]
class GeoIpService
  def lookup(ip_address)
    return default_location if ip_address.blank? || private_ip?(ip_address)

    ip_int = ip_to_int(ip_address)
    return default_location if ip_int.nil?

    result = IpGeoRange.lookup(ip_int)
    return default_location if result.nil?

    # pick returns [country_code, country_name, region, city]
    {
      country_code: result[0],
      country_name: result[1],
      region: result[2],
      city: result[3]
    }
  rescue StandardError => e
    Rails.logger.warn("GeoIP lookup failed for #{ip_address}: #{e.message}")
    default_location
  end

  private

  def default_location
    { country_code: nil, country_name: nil, region: nil, city: nil }
  end

  def ip_to_int(ip_address)
    IPAddr.new(ip_address).to_i
  rescue ArgumentError
    nil # IPv6 or invalid
  end

  def private_ip?(ip)
    return true if ip =~ /^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.|127\.)/
    return true if ip =~ /^169\.254\./
    false
  end
end
