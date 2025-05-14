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

Run: 

```bash
rails db:seed
```
to seed clients and get theri api tokens.

```bash
# Make the script executable
chmod +x loyalty_api_simulation.rb

# Run the simulation
API_URL=http://localhost:3000 CLIENT1_TOKEN=token  CLIENT2_TOKEN=token2 ./loyalty_api_simulation.rb
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