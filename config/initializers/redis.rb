# config/initializers/redis.rb
# Set up Redis connection for the application
# Used by: PriceCacheService, CircuitBreaker, redirect cache, Rack::Attack
redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
redis_options = { url: redis_url }
# Heroku Redis (rediss://) uses TLS with a cert chain that can fail strict verification.
# Relax verification for TLS URLs so the app can connect; traffic stays within Heroku.
redis_options[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE } if redis_url.start_with?("rediss://")
REDIS = Redis.new(redis_options)
