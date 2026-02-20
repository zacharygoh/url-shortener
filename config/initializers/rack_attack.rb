# config/initializers/rack_attack.rb
class Rack::Attack
  # Throttle URL shortening requests to 10 per minute per IP
  throttle("shorten/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/api/shorten" && req.post?
  end

  # Throttle redirect requests to 100 per minute per IP
  throttle("redirect/ip", limit: 100, period: 1.minute) do |req|
    req.ip if req.path =~ %r{^/[a-zA-Z0-9]+$} && req.get?
  end
end
