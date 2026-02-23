# ADR 003: Rate Limiting Strategy

## Context

Protect against abuse and resource exhaustion. Rate limiting is for URL creation (spam) and redirects (scanning) only.

## Decision

We will implement **multi-tier rate limiting** using Rack::Attack with Redis backend.

### Implementation

```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  # URL creation: 10 requests/minute per IP
  throttle("shorten/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/api/shorten" && req.post?
  end

  # Redirects: 100 requests/minute per IP
  throttle("redirect/ip", limit: 100, period: 1.minute) do |req|
    req.ip if req.path =~ %r{^/[a-zA-Z0-9]+$} && req.get?
  end
end
```

### Rate Limit Tiers

| Endpoint | Limit | Period | Rationale |
|----------|-------|--------|-----------|
| POST /api/shorten | 10 | 1 minute | Prevent spam URL creation |
| GET /:short_code | 100 | 1 minute | Allow legitimate traffic but prevent scanning |

## Consequences

**Upside:** Limits spam/DoS, protects Heroku; 429 responses; Redis backs Rack::Attack. **Downside:** Shared IPs (NAT/VPN) can hit limits—we keep limits generous. Frontend must handle 429.

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

Track blocked requests and hot IPs. Later: user-based limits (with auth), geo limits, adaptive limits, and `X-RateLimit-*` headers.

## References

- [Rack::Attack Documentation](https://github.com/rack/rack-attack)
- [Token Bucket Algorithm](https://en.wikipedia.org/wiki/Token_bucket)
- [GitHub Rate Limiting](https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting)
