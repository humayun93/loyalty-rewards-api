# Transaction API Stress Testing

This directory contains stress tests for the Transactions API to verify how the system performs under high load.

## Available Tests

### RSpec Stress Tests

The RSpec-based stress tests in `transactions_stress_spec.rb` use Ruby threads to simulate concurrent API requests and measure performance. These tests:

1. Run inside the Rails environment (no external HTTP requests)
2. Create parallel transactions using threads
3. Measure performance metrics
4. Include assertions to verify correctness

To run these tests:

```bash
bundle exec rspec spec/performance/transactions_stress_spec.rb
```

The tests include:
- Concurrent transactions for a single user
- Concurrent transactions across multiple users
- Sequential rapid transactions
- Mixed transaction types (foreign and domestic)
- High volume with parameter variations

### Rake Task Stress Test

For more realistic stress testing outside of the RSpec context, a rake task is available that:

1. Makes actual HTTP requests to your running application
2. Allows configuring the test parameters via environment variables
3. Provides detailed performance metrics and database verification

To run the rake task:

```bash
# Basic usage (uses defaults)
bundle exec rake stress_test:transactions

# With custom parameters
USERS=20 TXN_PER_USER=10 CONCURRENCY=15 API_URL=http://localhost:3000 bundle exec rake stress_test:transactions
```

Configuration options:
- `USERS`: Number of users to create and test with (default: 10)
- `TXN_PER_USER`: Number of transactions to create per user (default: 5)
- `CONCURRENCY`: Number of concurrent requests to make (default: 5)
- `API_URL`: Base URL of the API (default: http://localhost:3000)

## Performance Metrics

Both tests provide performance metrics including:
- Total execution time
- Average response time
- Transactions per second
- Success rate

## Best Practices

1. **Test Environment**: Always run stress tests in a testing or staging environment, never in production.
2. **Database Reset**: Reset your database before/after running stress tests to ensure clean state.
3. **Resource Monitoring**: Monitor server resources (CPU, memory, DB connections) during stress tests.
4. **Gradually Increase Load**: Start with small numbers and gradually increase to find performance limits.
5. **Analyze Bottlenecks**: Use the results to identify performance bottlenecks in your application.

## Troubleshooting

If the stress tests are causing database connection issues:
- Check your database pool size in `config/database.yml`
- Adjust the concurrency level to be below your connection pool size
- Consider increasing database connection pool for testing

If you encounter timeout errors:
- Your application may be struggling with the load
- Try reducing the concurrency or number of transactions
- Check for N+1 query issues in the transaction creation flow 