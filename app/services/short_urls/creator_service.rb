# app/services/short_urls/creator_service.rb
module ShortUrls
  class CreatorService
    attr_reader :errors

    def initialize(target_url:)
      @target_url = target_url
      @errors = []
    end

    def call
      # Normalize URL
      normalized_url = normalize_url(@target_url)
      return failure("Invalid URL format") unless normalized_url

      # SSRF protection: check for private IPs
      return failure("Private or internal URLs are not allowed") if private_url?(normalized_url)

      # Create short URL record (triggers after_create to set short_code from id)
      short_url = ShortUrl.create(target_url: normalized_url)

      unless short_url.persisted?
        return failure(short_url.errors.full_messages.join(", "))
      end

      # Fetch title asynchronously (but synchronously for now for simplicity)
      fetch_title(short_url)

      success(short_url)
    rescue StandardError => e
      Rails.logger.error("Error creating short URL: #{e.message}")
      failure("Failed to create short URL")
    end

    private

    def normalize_url(url)
      return nil if url.blank?

      # Prepend https when URL has no scheme so Addressable parses host correctly (e.g. "example.com")
      if url.match?(/\A[a-z][a-z0-9+.-]*:/i)
        addr = Addressable::URI.parse(url)
      else
        url_with_scheme = "https://#{url.strip}"
        addr = Addressable::URI.parse(url_with_scheme)
        # Reject scheme-less input that doesn't parse to a host that looks like a domain (e.g. "not-a-valid-url")
        return nil if addr.host.blank? || !addr.host.include?('.')
      end

      # Ensure scheme is present
      addr.scheme ||= 'https'

      # Normalize host to lowercase
      addr.host = addr.host&.downcase

      # Remove trailing slash from path
      addr.path = addr.path.chomp('/') if addr.path.present?

      addr.to_s
    rescue Addressable::URI::InvalidURIError
      nil
    end

    def private_url?(url)
      uri = URI.parse(url)
      host = uri.host.to_s.downcase

      # Check for localhost
      return true if host.blank? || host == 'localhost' || host == '127.0.0.1' || host.start_with?('127.')

      # Check for private IP ranges
      return true if host.start_with?('10.') || host.start_with?('192.168.') || host.start_with?('169.254.')

      # Check for 172.16.0.0/12 range
      if host.start_with?('172.')
        octets = host.split('.')
        second_octet = octets[1].to_i
        return true if second_octet >= 16 && second_octet <= 31
      end

      false
    rescue URI::InvalidURIError
      true
    end

    def fetch_title(short_url)
      fetcher = UrlTitleFetcher.new
      title = fetcher.fetch(short_url.target_url)
      short_url.update(title: title) if title.present?
    end

    def success(short_url)
      { success: true, short_url: short_url }
    end

    def failure(message)
      @errors << message
      { success: false, errors: @errors }
    end
  end
end
