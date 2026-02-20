# config/initializers/sidekiq.rb
redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
sidekiq_redis = { url: redis_url }
sidekiq_redis[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE } if redis_url.start_with?("rediss://")

Sidekiq.configure_server do |config|
  config.redis = sidekiq_redis
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_redis
end
