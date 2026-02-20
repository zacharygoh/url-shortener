# app/services/short_urls/click_tracker_service.rb
module ShortUrls
  class ClickTrackerService
    def initialize(short_url:, ip:, user_agent:, referrer:)
      @short_url = short_url
      @ip = ip
      @user_agent = user_agent
      @referrer = referrer
    end

    def call
      # Lookup geolocation
      geo_service = GeoIpService.new
      geo_data = geo_service.lookup(@ip)

      # Increment click count
      @short_url.increment!(:click_count)

      # Create click event record
      ClickEvent.create!(
        short_url: @short_url,
        ip_address: @ip,
        country_code: geo_data[:country_code],
        city: geo_data[:city],
        user_agent: @user_agent,
        referrer: @referrer,
        clicked_at: Time.current
      )

      { success: true }
    rescue StandardError => e
      Rails.logger.error("Error tracking click: #{e.message}")
      { success: false, error: e.message }
    end
  end
end
