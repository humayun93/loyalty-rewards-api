# Loyalty Program API

A scalable, multi-tenant API for issuing loyalty points and rewards to users, designed for businesses that want to incentivize their customers based on spending behavior.

Built with **Ruby on Rails 7** and **PostgreSQL**, using **schema-per-tenant** isolation via the `apartment` gem.

---

## Assumptions

- **Fractional Points**: The system allows fractional loyalty points (e.g., 2.5 points for a $25 transaction), following the rule of 10 points per $100.
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
- [x] Prepare for Dockerization or cloud deployment

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

# Loyalty Rewards API Simulation

This Ruby script simulates interactions with the Loyalty Rewards API. It demonstrates the complete workflow of managing users, creating transactions, earning points, and receiving rewards in a multi-tenant environment.

## API Features Demonstrated

The simulation demonstrates these key features of the API:

1. **Multi-tenant Authentication**: Uses separate API tokens for different clients
2. **User Management**: Creating, reading, updating, and deleting users
3. **Transactions**: Creating transactions that earn points
4. **Points System**: Tracking and viewing user point balances 
5. **Rewards Engine**: Automatic rewards generation based on:
   - Monthly points threshold
   - New user spending
   - Birthday month

## How to Use

### Prerequisites
- Ruby
- A running instance of the Loyalty Rewards API

### Configuration

Set the following environment variables or modify the default values in the script:
```
API_URL=http://your-api-url
CLIENT1_TOKEN=your_client1_api_token
CLIENT2_TOKEN=your_client2_api_token
```

### Running the Simulation

```bash
# Make the script executable
chmod +x loyalty_api_simulation.rb

# Run the simulation
./loyalty_api_simulation.rb
```

## Simulation Steps

The script runs through these steps:

1. List existing users for each client
2. Create new users for each client
3. Get user details
4. Create transactions (both domestic and foreign)
5. Check points balances 
6. Create more transactions to trigger rewards
7. Check rewards
8. Update user information
9. (Optional) Delete a user

## API Endpoints Used

The script demonstrates all these API endpoints:

- `GET /api/v1/users` - List users for a client
- `GET /api/v1/users/:user_id` - Get a specific user
- `POST /api/v1/users` - Create a new user
- `PUT /api/v1/users/:user_id` - Update a user
- `DELETE /api/v1/users/:user_id` - Delete a user
- `GET /api/v1/users/:user_id/points` - Get user's points information
- `GET /api/v1/users/:user_id/rewards` - Get user's rewards
- `POST /api/v1/users/:user_id/transactions` - Create a transaction

## Expected Behavior

When run against the API, this script should:

1. Create users for two different clients
2. Generate points from transactions
3. Demonstrate the multi-tenant isolation (each client can only see their own users)
4. Trigger rewards based on the loyalty program rules (once enough points/spending is accrued)
5. Show how birth date and joining date affect rewards eligibility
