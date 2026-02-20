# ADR 001: Short Code Strategy

## Context

Short codes must be unique, under 15 characters, URL-safe (alphanumeric), and fast to generate/decode at scale.

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

No collisions: BIGSERIAL IDs are monotonic, each ID maps to one Base62 code, encoding is reversible. We set `short_code` in an `after_create` callback so the DB assigns the ID first (avoids race conditions).

## Consequences

**Upside:** Simple (no distributed ID system), no collisions, O(log N) encode/decode, reversible, scales to trillions. **Downside:** Codes are sequential and guessable (acceptable for MVP; later: Feistel or Hashids). No custom slugs yet; could add `custom_alias`. Short code depends on DB insert, which we need anyway.

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
- Feistel-style encoding for non-sequential IDs (e.g. “Beautiful IDs” post; original Booking.com link is no longer available)
- [Sqids](https://hashids.org/) (formerly Hashids) — short IDs from numbers with optional salt
