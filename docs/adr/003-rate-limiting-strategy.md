# ADR 003: Rate Limiting Strategy

## Status
Accepted

## Context

Our URL shortener needs protection against:
- Abuse (spam, DoS attacks)
- Resource exhaustion
- Unfair usage patterns
- External API quota limits (GeckoTerminal)

We need rate limiting for:
1. URL creation endpoint (prevent spam)
2. Redirect endpoint (prevent scanning/abuse)
3. Swap price API endpoints (protect GeckoTerminal quota)

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

### Positive

1. **Abuse Prevention**
   - Blocks spam and DoS attacks
   - Protects server resources
   - Fair usage for all users

2. **Cost Control**
   - Prevents excessive GeckoTerminal API calls
   - Reduces Redis/PostgreSQL load
   - Heroku dyno protection

3. **User Experience**
   - Legitimate users rarely hit limits
   - Clear error messages (429 status)
   - Gradual degradation vs hard failures

4. **External API Protection**
   - Circuit breaker prevents cascade failures
   - Respects third-party rate limits
   - Automatic recovery when API recovers

### Negative

1. **False Positives**
   - Legitimate users behind NAT/VPN may share IP
   - **Mitigation**: Generous limits (10/min for creation is reasonable)

2. **Redis Dependency**
   - Rack::Attack requires Redis
   - **Mitigation**: Already using Redis for caching and Sidekiq

3. **Implementation Complexity**
   - Must handle 429 responses in frontend
   - Circuit breaker adds code complexity
   - **Mitigation**: Better than cascading failures

## Alternatives Considered

### 1. No Rate Limiting
- **Rejected**: Vulnerable to abuse, API quota exhaustion

### 2. Application-Level Rate Limiting
- Implement in Rails controllers
- **Rejected**: Harder to test, less performant than Rack middleware

### 3. API Gateway (Kong, AWS API Gateway)
- Offload rate limiting to infrastructure
- **Rejected**: Overkill for Heroku deployment, adds cost

### 4. Token Bucket Algorithm (Custom)
- Implement custom token bucket
- **Rejected**: Rack::Attack provides this with better testing

### 5. User-Based Rate Limiting
- Rate limit by user account instead of IP
- **Rejected**: No authentication in MVP (could add later)

## Rate Limit Response

When rate limit is exceeded:

```json
HTTP/1.1 429 Too Many Requests
Retry-After: 60

{
  "error": "Rate limit exceeded. Please try again in 60 seconds."
}
```

## Monitoring

Track rate limit metrics:
- Number of blocked requests per endpoint
- IPs frequently hitting limits (potential abuse)
- Circuit breaker open/close events
- GeckoTerminal API response times

## Future Enhancements

1. **User-Based Limits**:
   - Higher limits for authenticated users
   - API keys with custom quotas

2. **Geographic Rate Limiting**:
   - Different limits for different regions
   - Block known bad actors by country

3. **Adaptive Rate Limiting**:
   - Increase limits during known traffic spikes
   - Decrease limits under load

4. **Rate Limit Headers**:
   - `X-RateLimit-Limit`: Maximum requests
   - `X-RateLimit-Remaining`: Remaining requests
   - `X-RateLimit-Reset`: Time until reset

## References

- [Rack::Attack Documentation](https://github.com/rack/rack-attack)
- [Token Bucket Algorithm](https://en.wikipedia.org/wiki/Token_bucket)
- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html)
- [GitHub Rate Limiting](https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting)

## Decision Date
2026-02-16

## Authors
- CoinGecko Engineering Team
