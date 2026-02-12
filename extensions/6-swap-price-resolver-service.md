# Take-Home: Individual Swap Price Resolver Service (HTTP)

## Objective

Build a small HTTP service that returns the price of a **specific swap** identified by `tx_hash` + `swap_log_index` and computes the **base token USD price** for that swap.

## Glossary

- **Base token**: The token you're pricing (like a stock ticker). In this dataset, CLAWD (`0x9f86db9fc6f7c9408e8fda3ff8ce4e78ac7a6b07`) is the base token.
- **Quote token**: The token you're pricing it _against_ (like USD in a stock price). In this dataset, WETH (`0x4200000000000000000000000000000000000006`) is the quote token.
- **Anchor token**: A well-known token (WETH, SOL, USDC, etc.) with a reliable USD price available on public price APIs. A pool is eligible for pricing only when its quote token is an anchor token.
- **Swap**: An on-chain exchange of one token for another. Each swap is uniquely identified by `tx_hash` + `swap_log_index`.

### Required API endpoints

1. GET /swap-price/csv (required)
2. GET /swap-price/live (bonus)

Both endpoints must use the same core resolver logic and return the same response schema.

Query Params:

- `network` (required)
- `base_token_address` (required)
- `tx_hash` (required)
- `swap_log_index` (required)
- `pool_address` (only required for /swap-price/live)

### Important Constraints

1. Assume pool is eligible only when the quote token is an anchor token with a reliable USD price (see Glossary above)
2. Scoped to only 2 token pools
3. Price unit must be based on provided `base_token_address`
4. You must fetch the quote token's USD price from the endpoint `GET https://api.geckoterminal.com/api/v2/simple/networks/{network}/token_price/{addresses}` which will be used to resolve the USD price of the provided "base token" (via `base_token_address`)
5. Do not hardcode USD prices
6. **GeckoTerminal API has rate limits (~10 requests/min)**

### Core Logic Requirements

1. Find exact swap by `tx_hash` + `swap_log_index`
2. Determine quote token as the non-base token in the swap
3. Compute `swap_price_quote_in_base` from swap amounts + swap direction. This is defined as "how much quote token equals 1 unit of base token"
4. Fetch the quote token's price in USD at runtime from GeckoTerminal's price endpoint: `/api/v2/simple/networks/{network}/token_price/{addresses}` to be able to resolve the base token's USD price

Response Schema:

```json
{
  "data": {
    "network": "base",
    "pool_address": "0x9fd58e73d8047cb14ac540acd141d3fc1a41fb6252d674b730faf62fe24aa8ce",
    "tx_hash": "0x6dc703bc7c2f3ec788c9fedbfbfa55378d309793a212d469611588152a9e9507",
    "swap_log_index": 540,
    "block_timestamp": "2026-02-01T00:00:01Z",
    "base_token_address": "0x9f86db9fc6f7c9408e8fda3ff8ce4e78ac7a6b07",
    "quote_token_address": "0x4200000000000000000000000000000000000006",
    "swap_price_quote_in_base": "6.569618272390946e-8",
    "base_token_usd_price": "0.0001295",
    "quote_token_usd_price": "1972.39",
    "quote_token_price_source": "https://api.geckoterminal.com/api/v2/simple/networks/base/token_price/0x4200000000000000000000000000000000000006",
    "quote_token_price_observed_at": "2026-02-12T04:20:10Z",
    "source": "csv"
  }
}
```

> Note: `base_token_usd_price` and `quote_token_usd_price` will vary depending on when you fetch the live WETH price from GeckoTerminal.

### Rate Limiting (Required) & Caching (Optional)

GeckoTerminal's API has rate limits (~10 requests/minute for free tier).

**Requirements:**

1. Handle rate limit errors (HTTP 429) gracefully without failing requests
2. (Optional) Implement caching to minimize redundant price fetches for the same quote token
3. Document in README:
    - Your caching strategy (if any) and TTL choices
    - How the service behaves when rate limited

### Bonus Requirements (`GET /swap-price/live`)

1. Fetch trades from:
   `GET https://api.geckoterminal.com/api/v2/networks/{network}/pools/{pool_address}/trades`
2. Locate the requested swap using `tx_hash` + `swap_log_index`
3. Reuse the same core resolver logic as `/swap-price/csv`
4. Return the same response schema, with `"source": "live"`
5. Document in README any assumptions/limitations of live lookup

#### Data sources

1. A dataset containing a sample pool's ([CLAWD / WETH](https://www.geckoterminal.com/base/pools/0x9fd58e73d8047cb14ac540acd141d3fc1a41fb6252d674b730faf62fe24aa8ce)) swaps (provided as `6-swaps.csv`)
2. GeckoTerminal Public API endpoint for USD price: `GET https://api.geckoterminal.com/api/v2/simple/networks/{network}/token_price/{addresses}`
3. Bonus pool recent trades endpoint: `GET https://api.geckoterminal.com/api/v2/networks/{network}/pools/{pool_address}/trades`
4. GeckoTerminal Public API endpoint documentation: https://www.geckoterminal.com/dex-api

## Submission

Submit a private GitHub repository (or zip file) containing:

1. **Source code** with dependencies listed
2. **README** with setup instructions, API examples, and design decisions
3. **Tests** with command to run them
4. At least one **working example** request/response for `/swap-price/csv`
