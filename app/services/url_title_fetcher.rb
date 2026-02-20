# app/services/url_title_fetcher.rb
# Fetches the title tag from a given URL with SSRF protection
class UrlTitleFetcher
  TIMEOUT = 5 # seconds
  OPEN_TIMEOUT = 2 # seconds

  def fetch(url)
    return nil if url.blank?
    return nil if private_or_internal?(url)

    response = HTTParty.get(
      url,
      timeout: TIMEOUT,
      open_timeout: OPEN_TIMEOUT,
      follow_redirects: true
    )

    return nil unless response.success?

    doc = Nokogiri::HTML(response.body)
    title = doc.at_css("title")&.text&.strip
    title.presence
  rescue StandardError => e
    Rails.logger.warn("Failed to fetch title for #{url}: #{e.message}")
    nil
  end

  private

  # Defense-in-depth: Block private and internal IP ranges to prevent SSRF
  # RFC 1918 private ranges: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
  # Link-local: 169.254.0.0/16
  # Loopback: 127.0.0.0/8
  def private_or_internal?(url)
    uri = URI.parse(url)
    host = uri.host.to_s.downcase

    # Check for localhost
    return true if host.blank? || host == "localhost" || host == "127.0.0.1" || host.start_with?("127.")

    # Check for private IP ranges
    return true if host.start_with?("10.") || host.start_with?("192.168.") || host.start_with?("169.254.")

    # Check for 172.16.0.0/12 range (172.16.0.0 - 172.31.255.255)
    if host.start_with?("172.")
      octets = host.split(".")
      second_octet = octets[1].to_i
      return true if second_octet >= 16 && second_octet <= 31
    end

    false
  rescue URI::InvalidURIError
    true # If URI is invalid, treat as private to be safe
  end
end
