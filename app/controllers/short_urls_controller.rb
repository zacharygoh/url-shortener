# app/controllers/short_urls_controller.rb
class ShortUrlsController < ApplicationController
  # GET / - Web UI home page
  def index
    @recent_urls = ShortUrl.active.order(created_at: :desc).limit(10)
  end
end
