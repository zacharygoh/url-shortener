# ADR 003: Rate Limiting Strategy

## Context

Protect against abuse, resource exhaustion, and external API quota (e.g. GeckoTerminal). Need limits on: URL creation (spam), redirects (scanning), and swap-price API.

## Decision

We will implement **multi-tier rate limiting** using Rack::Attack with Redis backend.

### Implementation

```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  # URL creation: 10 requests/minute per IP
  throttle('shorten/ip', limit: 10, period: 1.minute) do |req|
    req.ip if req.path == '/api/shorten' && req.post?
  end

  # Redirects: 100 requests/minute per IP
  throttle('redirect/ip', limit: 100, period: 1.minute) do |req|
    req.ip if req.path =~ %r{^/[a-zA-Z0-9]+$} && req.get?
  end

  # Swap price API: 10 requests/minute per IP
  throttle('swap-price/ip', limit: 10, period: 1.minute) do |req|
    req.ip if req.path =~ %r{^/api/swap-price/} && req.get?
  end
end
```

### Rate Limit Tiers

| Endpoint | Limit | Period | Rationale |
|----------|-------|--------|-----------|
| POST /api/shorten | 10 | 1 minute | Prevent spam URL creation |
| GET /:short_code | 100 | 1 minute | Allow legitimate traffic but prevent scanning |
| GET /api/swap-price/* | 10 | 1 minute | Match GeckoTerminal API limits |

### Circuit Breaker for External APIs

In addition to rate limiting, we implement a **circuit breaker** for the GeckoTerminal API:

```ruby
# app/clients/gecko_terminal_client.rb
class GeckoTerminalClient
  CIRCUIT_BREAKER_THRESHOLD = 5 # failures before opening
  CIRCUIT_BREAKER_TIMEOUT = 60  # seconds to wait

  # Tracks failures in Redis
  # Opens circuit after 5 failures
  # Prevents cascade failures
end
```

## Consequences

**Upside:** Limits spam/DoS, protects GeckoTerminal quota and Heroku; 429 and circuit breaker avoid cascades. **Downside:** Shared IPs (NAT/VPN) can hit limits—we keep limits generous. Rack::Attack needs Redis (we already use it). Frontend must handle 429; circuit breaker adds a bit of code.

## Alternatives Considered

No rate limiting: rejected (abuse/quota risk). Controller-level limits: rejected (harder to test, slower than middleware). API gateway: overkill on Heroku. Custom token bucket: Rack::Attack already does it. User-based limits: no auth in MVP; could add later.

## Rate Limit Response

When rate limit is exceeded:

```json
HTTP/1.1 429 Too Many Requests
Retry-After: 60

{
  "error": "Rate limit exceeded. Please try again in 60 seconds."
}
```

## Monitoring / Future

Track blocked requests, hot IPs, circuit breaker state, and GeckoTerminal latency. Later: user-based limits (with auth), geo limits, adaptive limits, and `X-RateLimit-*` headers.

## References

- [Rack::Attack Documentation](https://github.com/rack/rack-attack)
- [Token Bucket Algorithm](https://en.wikipedia.org/wiki/Token_bucket)
- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html)
- [GitHub Rate Limiting](https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting)
