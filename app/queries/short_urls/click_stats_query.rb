# app/queries/short_urls/click_stats_query.rb
module ShortUrls
  class ClickStatsQuery
    def initialize(short_url)
      @short_url = short_url
    end

    # Get click counts grouped by country
    def clicks_by_country
      @short_url.click_events
                .where.not(country_code: nil)
                .group(:country_code)
                .count
    end

    # Get recent clicks with details
    def recent_clicks(limit: 10)
      @short_url.click_events
                .order(clicked_at: :desc)
                .limit(limit)
                .pluck(:country_code, :city, :clicked_at)
                .map do |country, city, clicked_at|
          {
            country: country,
            city: city,
            clicked_at: clicked_at&.iso8601
          }
        end
    end

    # Get click count for a specific period
    def click_count_for_period(start_time:, end_time: Time.current)
      @short_url.click_events
                .where(clicked_at: start_time..end_time)
                .count
    end

    # Get most recent click timestamp
    def most_recent_clicked_at
      @short_url.click_events
                .maximum(:clicked_at)
    end

    # Get complete stats for API response
    def full_stats
      {
        short_code: @short_url.short_code,
        target_url: @short_url.target_url,
        click_count: @short_url.click_count,
        created_at: @short_url.created_at&.iso8601,
        clicks_by_country: clicks_by_country,
        recent_clicks: recent_clicks
      }
    end
  end
end
