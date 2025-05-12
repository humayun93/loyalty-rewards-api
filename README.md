# 🎁 Loyalty Program API

A scalable, multi-tenant API for issuing loyalty points and rewards to users, designed for businesses that want to incentivize their customers based on spending behavior.

Built with **Ruby on Rails 7** and **PostgreSQL**, using **schema-per-tenant** isolation via the `apartment` gem.

---

## 📌 Why Multi-Tenant (Schema-per-Tenant)?

This system is designed to support multiple client businesses each operating with isolated data.

We chose the **schema-per-tenant** pattern because:

- ✅ **Strong data isolation**: prevents cross-tenant access
- ✅ **Improved query performance**: queries run on smaller, per-tenant tables
- ✅ **Simplified backups and deletion**: entire tenant data can be dropped in one operation
- ✅ **Per-tenant scaling**: supports future horizontal DB distribution
- ✅ **Customizability**: allows unique indexes or business rules per tenant if needed

This architecture enables **safe multi-client usage**, scales with workload, and aligns well with enterprise data protection policies (e.g., GDPR).

---

## 📅 Development Plan

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

## 🧱 Stack

- Ruby on Rails 7 (API-only)
- PostgreSQL 13+
- Apartment gem (multi-tenant via schema)
- RSpec (for testing)
- Swagger / Redoc (for documentation)
- Docker (for deployment)
---

## 🚀 Setup Instructions

```bash
# Install gems
bundle install

# Setup DB
rails db:create db:migrate
rails db:seed

# Create tenant schemas
rails runner "Client.find_each { |c| Apartment::Tenant.create(c.subdomain) }"
rails db:migrate:tenants
