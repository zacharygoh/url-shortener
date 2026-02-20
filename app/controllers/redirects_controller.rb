# app/controllers/redirects_controller.rb
class RedirectsController < ApplicationController
  CACHE_TTL = 5.minutes

  # GET /:short_code
  def show
    short_code = params[:short_code]

    # Try cache first
    target_url = fetch_from_cache(short_code)

    unless target_url
      short_url = ShortUrl.active.find_by(short_code: short_code)

      if short_url
        target_url = short_url.target_url

        # Cache the result
        cache_short_url(short_code, short_url.id, target_url)

        # Enqueue async click tracking job
        TrackClickJob.perform_later(
          short_url.id,
          request.remote_ip,
          request.user_agent,
          request.referer
        )
      else
        return render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
      end
    end

    redirect_to target_url, status: :found, allow_other_host: true
  end

  private

  def fetch_from_cache(short_code)
    cache_key = "short_url:#{short_code}"
    cached_data = REDIS.get(cache_key)

    if cached_data
      data = JSON.parse(cached_data)

      # Enqueue click tracking if we have the short_url_id
      if data['id']
        TrackClickJob.perform_later(
          data['id'],
          request.remote_ip,
          request.user_agent,
          request.referer
        )
      end

      return data['target_url']
    end

    nil
  rescue Redis::BaseError, JSON::ParserError => e
    Rails.logger.warn("Cache fetch failed: #{e.message}")
    nil
  end

  def cache_short_url(short_code, short_url_id, target_url)
    cache_key = "short_url:#{short_code}"
    cache_value = { id: short_url_id, target_url: target_url }.to_json
    REDIS.setex(cache_key, CACHE_TTL.to_i, cache_value)
  rescue Redis::BaseError => e
    Rails.logger.warn("Cache set failed: #{e.message}")
  end
end
