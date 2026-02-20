# config/initializers/redis.rb
# Set up Redis connection for the application
# Used by: PriceCacheService, CircuitBreaker, redirect cache, Rack::Attack
REDIS = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
