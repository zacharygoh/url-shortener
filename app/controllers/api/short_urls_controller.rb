# app/controllers/api/short_urls_controller.rb
module Api
  class ShortUrlsController < ApplicationController
    skip_before_action :verify_authenticity_token

    # POST /api/shorten
    def create
      result = ShortUrls::CreatorService.new(target_url: params[:target_url]).call

      if result[:success]
        short_url = result[:short_url]
        render json: { data: ShortUrlDecorator.new(short_url).as_json }, status: :created
      else
        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end
    end

    # GET /api/stats/:short_code
    def stats
      short_url = ShortUrl.active.find_by(short_code: params[:short_code])

      if short_url
        stats = ShortUrls::ClickStatsQuery.new(short_url).full_stats
        render json: { data: stats }, status: :ok
      else
        render json: { error: "Short URL not found" }, status: :not_found
      end
    end

    # GET /api/report
    def report
      limit = params[:limit]&.to_i || 100
      since = parse_since_param

      short_urls = ShortUrl.active
                           .where("created_at >= ?", since)
                           .order(created_at: :desc)
                           .limit(limit)

      data = short_urls.map do |short_url|
        query = ShortUrls::ClickStatsQuery.new(short_url)
        {
          short_code: short_url.short_code,
          target_url: short_url.target_url,
          click_count: short_url.click_count,
          created_at: short_url.created_at&.iso8601,
          clicks_by_country: query.clicks_by_country,
          recent_clicked_at: query.most_recent_clicked_at&.iso8601
        }
      end

      render json: { data: data }, status: :ok
    end

    private

    def parse_since_param
      return 7.days.ago unless params[:since]

      Time.zone.parse(params[:since])
    rescue ArgumentError
      7.days.ago
    end
  end
end
