# app/jobs/track_click_job.rb
class TrackClickJob < ApplicationJob
  queue_as :default

  def perform(short_url_id, ip, user_agent, referrer)
    short_url = ShortUrl.find_by(id: short_url_id)
    return unless short_url

    ShortUrls::ClickTrackerService.new(
      short_url: short_url,
      ip: ip,
      user_agent: user_agent,
      referrer: referrer
    ).call
  end
end
