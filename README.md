# Loyalty Program API

A scalable, multi-tenant API for issuing loyalty points and rewards to users, designed for businesses that want to incentivize their customers based on spending behavior.

Built with **Ruby on Rails 8** and **PostgreSQL**, using **row-based multi-tenancy** isolation via the `acts_as_tenant` gem.

---

## Assumptions

- **Fractional Points**: The system allows fractional loyalty points (e.g., 2.5 points for a $25 transaction), following the rule of 10 points per $100.
- **Points Precision**: Points are stored with a precision of 10 digits and 3 decimal places for fine-grained accumulation.
- **Transaction Amounts**: Transaction amounts are stored with a precision of 10 digits and 2 decimal places.
- **Points Accumulation**: Fractional points are accumulated precisely, without rounding, until redemption.
- **Multi-tenancy**: Each client's data is completely isolated in using row level tenancy.
- **Currency Conversion**: Foreign currency transactions are flagged but not converted; the amount is assumed to be already converted.
- **User Identifiers**: User IDs must be URL-safe strings (can include letters, numbers, hyphens, underscores, and tildes). They cannot contain spaces, periods, or email addresses. UUIDs are recommended.

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

- [x] Initialize Rails 8 API-only app with PostgreSQL
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

- Ruby on Rails 8 (API-only)
- PostgreSQL 13+
- Act_As_Tenant gem
- RSpec (for testing)
- Swagger (for documentation)
- Docker (for deployment)
---

### Quick Setup with Docker Compose

The quickest way to get started with the application is using Docker Compose:

```bash
# Clone the repository (if you haven't already)
git clone https://github.com/humayun93/loyalty-rewards-api.git
cd loyalty-rewards-api

# Create a .env file with your configuration
cp .env.example .env  # Edit the .env file as needed

# Start the application with Docker Compose
docker-compose up -d

# Run database migrations and seed data
docker-compose exec api rails db:create db:migrate db:seed
# The seed command will display the API keys that can be used for testing
```bash
Creating clients...
Created client Acme Corporation with token: token_1
Created client Globex Industries with token: token_2
Created client Oceanic Airlines with token: token_3
Finished creating clients
```
# The API should now be available at http://localhost:3000


# To run the API simulation (optional)
`API_URL=http://localhost:3000 CLIENT1_TOKEN=token_1  CLIENT2_TOKEN=token_2 ruby loyalty_api_simulation.rb`
```
To view logs:
```bash
docker-compose logs -f
```

To stop the application:
```bash
docker-compose down
```
More at [Docker documentation]

## Setup Instructions

```bash
# Install gems
bundle install

# Setup DB
rails db:create db:migrate
rails db:seed
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

For a complete script that demonstrates the API functionality and workflow, please see [API Simulation Documentation](docs/api_simulation_readme.md).

## Performance Documentation

For details about system performance characteristics, optimizations, and benchmarks, see [Performance Documentation](spec/performance/README.md.md).


### Further Development - Subdomain Isolation Plan

To achieve complete tenant isolation, this application supports a subdomain-based approach:

1. **DNS Configuration**: Each tenant can have their own subdomain (e.g., `client1.loyalty-api.com`, `client2.loyalty-api.com`)

2. **Nginx/Load Balancer Setup**:
   - Configure a reverse proxy (like Nginx) to route requests based on subdomain
   - Example configuration in `config/nginx.conf.example`

3. **Authentication Flow**:
   - The subdomain is extracted from the request hostname
   - The system identifies the tenant based on the subdomain
   - All database operations are automatically scoped to the appropriate tenant schema

4. **Implementation Plan**:
   - Update middleware to extract tenant from request subdomain
   - Add subdomain validation to Client model
   - Configure production environment to support multiple domains
   - Document DNS requirements for client onboarding

This approach provides complete logical and physical separation between tenants while maintaining a single application instance.
