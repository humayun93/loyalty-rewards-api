# Loyalty Program API

A scalable, multi-tenant API for issuing loyalty points and rewards to users, designed for businesses that want to incentivize their customers based on spending behavior.

Built with **Ruby on Rails 7** and **PostgreSQL**, using **schema-per-tenant** isolation via the `apartment` gem.

---

## Assumptions

- **Fractional Points**: The system allows fractional loyalty points (e.g., 2.5 points for a $25 transaction), following the rule of 10 points per $100.
- **Points Precision**: Points are stored with a precision of 10 digits and 3 decimal places for fine-grained accumulation.
- **Transaction Amounts**: Transaction amounts are stored with a precision of 10 digits and 2 decimal places.
- **Points Accumulation**: Fractional points are accumulated precisely, without rounding, until redemption.
- **Multi-tenancy**: Each client's data is completely isolated in separate database schemas.
- **Currency Conversion**: Foreign currency transactions are flagged but not converted; the amount is assumed to be already converted.

---

## Why Multi-Tenant with ActsAsTenant?

This system is designed to support multiple client businesses each operating with isolated data.

We chose the **schema-per-tenant** pattern with ActsAsTenant because:

- ✅ **Strong data isolation**: ActsAsTenant ensures queries are properly scoped to the current tenant
- ✅ **Simple implementation**: Adds automatic tenant-scoping to models without complex query modifications
- ✅ **Default security**: Prevents accidental cross-tenant data access at the application level
- ✅ **Minimal query overhead**: Adds tenant conditions efficiently without significant performance impact
- ✅ **Rails-native approach**: Works seamlessly with Active Record without custom database adapters

This architecture enables **safe multi-client usage**, maintains data segregation, and aligns well with enterprise data protection policies (e.g., GDPR).

---

## Development Plan

- [x] Initialize Rails 7 API-only app with PostgreSQL
- [x] Set up `Client` model with token-based auth
- [x] Add middleware for tenant switching using `act_as_tanent` gem
- [x] Create `User` model (per-tenant)
- [x] Implement `Transaction` model and points-earning rules:
  - $100 = 10 points
  - 2x points on foreign transactions
- [x] Build reward issuance rules:
  - 100 points in month → Free Coffee
  - Birthday month → Free Coffee
  - New user spends >$1000 in 60 days → Free Movie Ticket
- [x] Implement endpoints:
  - `POST /users`
  - `POST /transactions`
  - `GET /users/:id/points`
  - `GET /users/:id/rewards`
- [x] Add RSpec tests for transactions and reward logic
- [x] Write OpenAPI spec (`docs/openapi.yaml`)
- [x] Seed example clients and tenants
- [x] Document setup, tenant creation, and API usage in `README.md`
- [x] Prepare for Dockerization

---

## Stack

- Ruby on Rails 7 (API-only)
- PostgreSQL 13+
- Apartment gem (multi-tenant via schema)
- RSpec (for testing)
- Swagger / Redoc (for documentation)
- Docker (for deployment)
---

## Setup Instructions

```bash
# Install gems
bundle install

# Setup DB
rails db:create db:migrate
rails db:seed

# Create tenant schemas
rails runner "Client.find_each { |c| Apartment::Tenant.create(c.subdomain) }"
rails db:migrate:tenants
```

### Environment Configuration

Create a `.env` file in the root directory with the following settings:

```bash
DB_USERNAME=postgres
DB_PASSWORD=postgres
EAGER_LOAD_DEV=true # only turn it on when stress testing
CI=true # only for running performance tests in local env
```

## API Simulation

For a complete script that demonstrates the API functionality and workflow, please see [API Simulation Documentation](api_simulation_readme.md).

## Performance Documentation

For details about system performance characteristics, optimizations, and benchmarks, see [Performance Documentation](performance_documentation.md).
