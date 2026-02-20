# app/decorators/short_url_decorator.rb
class ShortUrlDecorator
  def initialize(short_url)
    @short_url = short_url
  end

  def as_json(*_args)
    {
      short_url: full_url,
      short_code: @short_url.short_code,
      target_url: @short_url.target_url,
      title: @short_url.title,
      created_at: @short_url.created_at&.iso8601
    }
  end

  def to_json(*args)
    as_json.to_json(*args)
  end

  private

  def full_url
    scheme = Rails.application.config.force_ssl ? 'https' : 'http'
    opts = Rails.application.config.action_controller.default_url_options || {}
    host = opts[:host] || 'localhost:3000'
    "#{scheme}://#{host}/#{@short_url.short_code}"
  end
end
