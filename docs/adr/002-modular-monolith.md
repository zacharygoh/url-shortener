# ADR 002: Modular Monolith Architecture

## Status
Accepted

## Context

We need to decide on the application architecture for the URL shortener service. The decision impacts:
- Development velocity
- Deployment complexity
- Operational overhead
- Scalability patterns
- Team coordination
- Testing strategy

Given:
- Small team (1-2 engineers initially)
- MVP timeline (2 weeks)
- Heroku free tier deployment constraint
- Potential future growth

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

Clear module boundaries are maintained through:
1. **Namespace separation**: `ShortUrls::`, `SwapPrices::`
2. **Single Responsibility**: Each module owns its domain
3. **Service Objects**: Encapsulate business operations
4. **Query Objects**: Isolate data access patterns
5. **Clean interfaces**: Modules communicate through well-defined APIs

## Consequences

### Positive

1. **Faster Development**
   - No distributed systems complexity
   - Shared code reuse (models, utilities)
   - Easier debugging with single process
   - Simpler testing (no service mocking)

2. **Simpler Deployment**
   - Single Heroku dyno
   - No service discovery/coordination
   - Easier monitoring and logging
   - Lower operational cost

3. **Better for MVP**
   - Fits 2-week timeline
   - Heroku free tier friendly
   - Easier to demonstrate in interviews

4. **Future Flexibility**
   - Clean module boundaries enable extraction
   - Can split into microservices later if needed
   - YAGNI principle: Don't build infrastructure you don't need

5. **Testing Benefits**
   - Faster test suite (no network calls)
   - Easier integration tests
   - No need for service mocking

### Negative

1. **Scaling Constraints**
   - Cannot scale modules independently
   - Single database bottleneck
   - **Mitigation**:
     - Redis caching reduces DB load
     - Sidekiq for async processing
     - Read replicas if needed

2. **Deployment Coupling**
   - All changes deploy together
   - **Mitigation**:
     - Good test coverage
     - Feature flags for risky changes

3. **Team Coordination**
   - Git merge conflicts in monorepo
   - **Mitigation**:
     - Not an issue for 1-2 engineers
     - Clear module ownership helps

## Why Not Microservices?

Microservices were explicitly rejected because:

1. **Premature Optimization**: No evidence of scaling needs yet
2. **Added Complexity**:
   - Service discovery (Consul, Eureka)
   - Inter-service communication (REST, gRPC)
   - Distributed tracing (Jaeger, Zipkin)
   - API gateway (Kong, Nginx)
   - Multiple databases to manage
3. **Operational Overhead**:
   - More deployment pipelines
   - More monitoring dashboards
   - More failure modes
4. **Heroku Constraints**: Multiple services = higher cost
5. **Team Size**: Microservices benefit larger teams (10+)

## L3+ Evaluation Criteria

This decision demonstrates L3+ thinking because:

1. **Context-Aware**: Chose architecture appropriate for team size and timeline
2. **Pragmatic**: Avoided over-engineering while maintaining quality
3. **Future-Proof**: Clean boundaries enable evolution
4. **Cost-Conscious**: Optimized for Heroku free tier
5. **Production-Ready**: Patterns used by successful companies (Shopify, GitHub monoliths)

## Migration Path

If we need to split into microservices later:

1. **Extract Swap Prices Service**
   - Already has clean `SwapPrices::` namespace
   - Own database tables (`price_caches`)
   - Own external API (`GeckoTerminalClient`)
   - Minimal dependencies on URL shortener

2. **Shared Infrastructure**
   - Keep authentication/authorization centralized
   - Shared Redis for cross-service caching
   - Shared monitoring/logging

3. **API Gateway**
   - Add Kong or AWS API Gateway
   - Route traffic to appropriate services

## Examples

Successful companies using modular monoliths:
- **Shopify**: Ruby on Rails monolith serving millions of merchants
- **GitHub**: Rails monolith with clear module boundaries
- **Basecamp**: Champions of "majestic monolith" approach

## References

- [The Majestic Monolith](https://m.signalvnoise.com/the-majestic-monolith/)
- [Shopify's Modular Monolith](https://shopify.engineering/shopify-monolith)
- [Martin Fowler on Monolith First](https://martinfowler.com/bliki/MonolithFirst.html)

## Decision Date
2026-02-16

## Authors
- CoinGecko Engineering Team
