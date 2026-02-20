# ADR 001: Short Code Strategy

## Status
Accepted

## Context

We need a reliable method to generate unique, short codes for our URL shortener service. The codes must:
- Be unique to prevent collisions
- Be short (under 15 characters as per requirements)
- Be URL-safe (alphanumeric only)
- Support high scale (millions to billions of URLs)
- Be fast to generate and decode

## Decision

We will use **Base62 encoding** of the database auto-increment ID as our short code strategy.

### Algorithm Details

- **Character Set**: `0-9a-zA-Z` (62 characters)
- **Encoding**: Convert database ID (BIGSERIAL) to Base62
- **Capacity**: 62^7 = 3,521,614,606,208 (~3.5 trillion unique URLs)
- **Code Length**: Typically 1-7 characters, well under the 15-character limit

### Implementation

```ruby
class ShortCode
  CHARS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

  def self.encode(id)
    # Base62 encoding of database ID
  end

  def self.decode(code)
    # Reverse operation
  end
end
```

### Collision Handling

**Zero collisions** are guaranteed because:
1. PostgreSQL BIGSERIAL provides monotonically increasing IDs
2. Each ID maps to exactly one Base62 code
3. The encoding is deterministic and reversible

The short_code is generated in an `after_create` callback to ensure the database ID exists first, preventing race conditions.

## Consequences

### Positive

- **Simple Implementation**: No need for distributed ID generation
- **Zero Collisions**: Database guarantees uniqueness
- **Fast**: O(log N) encoding/decoding, no external service calls
- **Scalable**: Supports trillions of URLs
- **Reversible**: Can decode short code to ID for lookups
- **Predictable Length**: Code length grows logarithmically with ID

### Negative

- **Sequential IDs**: Codes are guessable (abc → abd → abe)
  - **Mitigation**: This is documented and acceptable for MVP
  - **Future**: Can implement Feistel Cipher or Hashids with salt for production

- **Not Customizable**: Users cannot choose custom short codes
  - **Future**: Can add optional custom_alias field

- **Database Dependency**: Short code generation requires database insert
  - This is acceptable as we need to persist the URL anyway

## Alternatives Considered

### 1. Random String Generation
- Generate random alphanumeric strings
- **Rejected**: Collision probability increases with scale, requires collision checks

### 2. UUID-based
- Use UUID as short code
- **Rejected**: UUIDs are 36 characters, far exceeding our 15-character limit

### 3. Hash-based (MD5/SHA256)
- Hash the target URL and truncate
- **Rejected**:
  - Hash collisions possible
  - Multiple short URLs for same target URL not supported (requirement)
  - Longer codes even when truncated

### 4. Distributed ID Generation (Snowflake, etc.)
- Use distributed ID generator like Twitter Snowflake
- **Rejected**: Overengineered for monolithic deployment on Heroku

### 5. External Service (bit.ly API, etc.)
- Use third-party service
- **Rejected**: Adds external dependency, cost, and latency

## Production Considerations

For production deployment, consider:

1. **Non-Sequential IDs**: Implement Feistel Cipher or Hashids to make IDs non-guessable
2. **Custom Aliases**: Add support for user-defined short codes with validation
3. **Distributed Systems**: If moving to microservices, consider Snowflake-like ID generation

## References

- [Base62 Encoding](https://en.wikipedia.org/wiki/Base62)
- [Feistel Cipher for URL Shortening](https://blog.booking.com/beautiful-ids-generator.html)
- [Hashids](https://hashids.org/)

## Decision Date
2026-02-16

## Authors
- CoinGecko Engineering Team
