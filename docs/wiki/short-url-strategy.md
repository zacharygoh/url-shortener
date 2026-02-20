# Short URL Strategy - Technical Wiki

Short URL generation (base62 from DB ID), limitations, and possible workarounds for this service.

## How It Works

### Base62 Encoding Algorithm

Database IDs are converted to short, URL-safe codes via Base62.

```
Database ID → Base62 Encoding → Short Code
```

**Example Conversions:**
- ID `1` → Code `1`
- ID `62` → Code `10`
- ID `100` → Code `1C`
- ID `1,000` → Code `g8`
- ID `1,000,000` → Code `4c92`

### Character Set

Our Base62 alphabet consists of 62 characters:
```
0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
```

62 characters per position (0-9, a-z, A-Z).

## Capacity Analysis

### Maximum URLs

With Base62 encoding, our capacity scales exponentially:

| Code Length | Capacity | Example Range |
|-------------|----------|---------------|
| 1 char | 62 | 0-Z |
| 2 chars | 3,844 | 10-ZZ |
| 3 chars | 238,328 | 100-ZZZ |
| 4 chars | 14.7 million | 1000-ZZZZ |
| 5 chars | 916 million | 10000-ZZZZZ |
| 6 chars | 56.8 billion | 100000-ZZZZZZ |
| **7 chars** | **3.5 trillion** | **1000000-ZZZZZZZ** |

Max length 15 (requirement); typical 1-7 chars. Practical capacity 3.5 trillion (62^7), more than needed for this use case.

## Collision Handling

No collisions: BIGSERIAL IDs are monotonic, one-to-one Base62 mapping, reversible. We set `short_code` in an `after_create` callback so the DB assigns the ID first (avoids races).

```ruby
# app/models/short_url.rb
after_create :assign_short_code_from_id

def assign_short_code_from_id
  update_column(:short_code, ShortCode.encode(id))
end
```

**Don't do this (race):**
```ruby
# ❌ WRONG: Race condition possible
next_id = ShortUrl.maximum(:id) + 1
short_code = ShortCode.encode(next_id)
ShortUrl.create(short_code: short_code, ...) # ID might differ!
```

## Limitations

### 1. Sequential / guessable codes

Codes are sequential (`1`, `2`, `3`… or `abc`, `abd`). Anyone can enumerate. Fine for public links; weak for private ones. Acceptable for MVP; consider Feistel or Hashids for production.

### 2. No custom aliases

No vanity URLs; all codes are auto-generated. Could add an optional `custom_alias` field later.

### 3. Length grows with scale

First 62 URLs use 1 char; then 2, 3, … up to 7 chars for 3.5T URLs. Still under the 15-char limit.

## Workarounds & Solutions

### Non-sequential codes: Feistel or Sqids

**Feistel cipher**

A Feistel cipher shuffles sequential IDs while maintaining uniqueness:

```ruby
# Pseudo-code
def feistel_encrypt(id, key)
  left, right = id >> 16, id & 0xFFFF

  3.times do
    left, right = right, left ^ round_function(right, key)
  end

  (left << 16) | right
end
```

**Before:** `1, 2, 3, 4, 5`
**After:** `8732, 5201, 9912, 1823, 6545`

**Then Base62 encode the shuffled ID.**

**Benefits:**
- Still bijective (reversible)
- No collisions
- Non-sequential appearance

Feistel-style encoding for non-sequential IDs: concept described in posts such as "Beautiful IDs" (original Booking.com link no longer available).

**Solution 2: Sqids (formerly Hashids)**

[Sqids](https://hashids.org/) provides short, obfuscated IDs from numbers with optional salt:

```ruby
# Gemfile: gem 'sqids' (or legacy 'hashids')
# Usage: encode/decode with salt; customizable length.
```

Easy to add; requires salt management. Slightly longer codes than raw base62.

### Custom aliases

Add optional `custom_alias` field:

```ruby
# Migration
add_column :short_urls, :custom_alias, :string, limit: 15

# Model
validates :custom_alias,
  uniqueness: true,
  format: { with: /\A[a-zA-Z0-9-_]+\z/ },
  allow_nil: true

# Lookup priority
def self.find_by_code(code)
  find_by(custom_alias: code) || find_by(short_code: code)
end
```

Validate: unique, max 15 chars, alphanumeric + `-`/`_`; reserve words like admin, api, docs. Lookup: check `custom_alias` first, then `short_code`.

### Minimum length (optional)

To get consistent-length codes, pad with zeros:

```ruby
def self.encode(id, min_length: 4)
  code = base62_encode(id)
  code.rjust(min_length, '0') # Pad with zeros
end
```

Trade-off: wastes some space at low IDs; more consistent UX.

## Comparison

| Strategy | Collision Risk | Length | Guessable | Reversible | Complexity |
|----------|---------------|--------|-----------|------------|------------|
| **Base62 (Ours)** | None | 1-7 | ✓ Yes | ✓ Yes | Low |
| Base62 + Feistel | None | 1-7 | ✗ No | ✓ Yes | Medium |
| Sqids (Hashids) | None | 4-8 | ✗ No | ✓ Yes | Low |
| Random String | Low | 6-8 | ✗ No | ✗ No | Medium |
| UUID | None | 36 | ✗ No | ✗ No | Low |
| Hash (MD5/SHA) | Medium | 8-16 | ✗ No | ✗ No | Low |

## Production ideas

MVP: current Base62 is fine; document limits and monitor. Later: Feistel or Sqids for non-guessable codes, custom aliases, user-based rate limits, optional expiration and analytics.

## Performance Characteristics

### Encoding Performance
```ruby
Benchmark.measure { 1_000_000.times { ShortCode.encode(rand(1_000_000)) } }
# => ~0.8 seconds (1.25M ops/sec)
```

### Lookup Performance
```sql
-- With index on short_code
SELECT * FROM short_urls WHERE short_code = 'abc123';
-- => ~1ms average
```

Index size ~100MB per 10M URLs; lookup O(log N) with B-tree.

## References

- [Base62](https://en.wikipedia.org/wiki/Base62)
- [Sqids](https://hashids.org/) (formerly Hashids) — short IDs from numbers with optional salt
