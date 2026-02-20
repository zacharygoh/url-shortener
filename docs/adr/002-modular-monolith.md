# ADR 002: Modular Monolith Architecture

## Context

Small team (1–2), ~2-week MVP, Heroku. Need an architecture that keeps deployment and ops simple while allowing future extraction.

## Decision

We will implement a **Modular Monolith** architecture rather than microservices.

### Structure

```
app/
├── services/          # Business logic (Service Objects)
│   ├── short_urls/
│   └── swap_prices/
├── queries/           # Complex queries (Query Objects)
├── values/            # Domain value objects
├── decorators/        # Presentation logic
├── clients/           # External API clients
└── jobs/              # Background jobs
```

### Modular Boundaries

Namespaces (`ShortUrls::`, `SwapPrices::`), service objects for business logic, query objects for data access. Modules talk via clear interfaces.

## Consequences

**Upside:** One codebase, one deploy, no service discovery; faster dev and tests, lower ops cost, fits Heroku free tier. Clear boundaries make it possible to extract services later (YAGNI). **Downside:** Can’t scale pieces independently; single DB. Mitigations: Redis cache, Sidekiq, read replicas if needed. All changes ship together; test coverage and feature flags help. Merge conflicts are manageable with 1–2 people and clear ownership.

## Why Not Microservices?

No scaling evidence yet. Microservices add discovery, inter-service calls, tracing, gateways, more DBs and pipelines—more cost and failure modes on Heroku. They pay off for larger teams (10+); we’re 1–2.

## Migration Path

If we split later: extract `SwapPrices::` (own tables, GeckoTerminal client, few ties to shortener); keep auth and Redis shared; add an API gateway to route traffic. Shopify, GitHub, and Basecamp run large Rails monoliths with clear boundaries.

## References

- [The Majestic Monolith](https://m.signalvnoise.com/the-majestic-monolith/)
- [Shopify's Modular Monolith](https://shopify.engineering/shopify-monolith)
- [Martin Fowler on Monolith First](https://martinfowler.com/bliki/MonolithFirst.html)
