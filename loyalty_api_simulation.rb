#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'uri'
require 'securerandom'
require 'date'

class LoyaltyRewardsApiClient
  def initialize(base_url, api_token, client_name)
    @base_url = base_url
    @headers = {
      'Authorization' => "Bearer #{api_token}",
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
    @client_name = client_name
    puts "Initializing client for #{@client_name} with token: #{api_token}"
  end

  # User Management
  def list_users
    response = get('/api/v1/users')
    puts "\n#{@client_name} - All Users:"
    if response.is_a?(Hash) && response['error']
      puts "Error: #{response['error']}"
    else
      puts JSON.pretty_generate(response)
    end
    response
  end

  def get_user(user_id)
    response = get("/api/v1/users/#{user_id}")
    puts "\n#{@client_name} - User Details for #{user_id}:"
    if response.is_a?(Hash) && response['error']
      puts "Error: #{response['error']}"
    else
      puts JSON.pretty_generate(response)
    end
    response
  end

  def create_user(user_id, birth_date, joining_date)
    user_params = {
      user: {
        user_id: user_id,
        birth_date: birth_date,
        joining_date: joining_date
      }
    }
    response = post('/api/v1/users', user_params)
    puts "\n#{@client_name} - Created New User:"
    if response.is_a?(Hash) && response['error']
      puts "Error: #{response['error']}"
    else
      puts JSON.pretty_generate(response)
    end
    response
  end

  def update_user(user_id, params)
    response = put("/api/v1/users/#{user_id}", { user: params })
    puts "\n#{@client_name} - Updated User #{user_id}:"
    if response.is_a?(Hash) && response['error']
      puts "Error: #{response['error']}"
    else
      puts JSON.pretty_generate(response)
    end
    response
  end

  def delete_user(user_id)
    response = delete("/api/v1/users/#{user_id}")
    puts "\n#{@client_name} - Deleted User #{user_id}"
    response
  end

  # Points
  def get_user_points(user_id)
    response = get("/api/v1/users/#{user_id}/points")
    puts "\n#{@client_name} - Points for User #{user_id}:"
    if response.is_a?(Hash) && response['error']
      puts "Error: #{response['error']}"
    else
      puts JSON.pretty_generate(response)
    end
    response
  end

  # Rewards
  def get_user_rewards(user_id, status = nil)
    url = "/api/v1/users/#{user_id}/rewards"
    url += "?status=#{status}" if status
    response = get(url)
    puts "\n#{@client_name} - Rewards for User #{user_id}:"
    if response.is_a?(Hash) && response['error']
      puts "Error: #{response['error']}"
    else
      puts JSON.pretty_generate(response)
    end
    response
  end

  # Transactions
  def create_transaction(user_id, amount, currency = 'USD', foreign = false)
    transaction_params = {
      transaction: {
        amount: amount,
        currency: currency,
        foreign: foreign
      }
    }
    response = post("/api/v1/users/#{user_id}/transactions", transaction_params)
    puts "\n#{@client_name} - Created Transaction for User #{user_id}:"
    if response.is_a?(Hash) && response['error']
      puts "Error: #{response['error']}"
    else
      puts JSON.pretty_generate(response)
    end
    response
  end

  private

  def get(path)
    uri = URI.parse("#{@base_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    request = Net::HTTP::Get.new(uri.request_uri, @headers)
    make_request(http, request)
  end

  def post(path, params)
    uri = URI.parse("#{@base_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    request = Net::HTTP::Post.new(uri.request_uri, @headers)
    request.body = params.to_json
    make_request(http, request)
  end

  def put(path, params)
    uri = URI.parse("#{@base_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    request = Net::HTTP::Put.new(uri.request_uri, @headers)
    request.body = params.to_json
    make_request(http, request)
  end

  def delete(path)
    uri = URI.parse("#{@base_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    request = Net::HTTP::Delete.new(uri.request_uri, @headers)
    make_request(http, request)
  end

  def make_request(http, request)
    response = http.request(request)

    if response.body && !response.body.empty?
      JSON.parse(response.body)
    else
      { status: response.code.to_i }
    end
  rescue JSON::ParserError
    { error: "Invalid JSON response", raw: response.body }
  rescue => e
    { error: e.message }
  end
end

# Main simulation script
def run_simulation
  # Configuration - Replace with actual values when running against a real API
  base_url = ENV['API_URL'] || 'http://localhost:3000'
  client1_token = ENV['CLIENT1_TOKEN'] || 'client1_api_token_here'
  client2_token = ENV['CLIENT2_TOKEN'] || 'client2_api_token_here'

  # Initialize API clients for different tenants
  client1 = LoyaltyRewardsApiClient.new(base_url, client1_token, 'Client One')
  client2 = LoyaltyRewardsApiClient.new(base_url, client2_token, 'Client Two')

  # Step 1: List users for each client
  puts "=== Listing existing users ==="
  client1_users = client1.list_users
  client2_users = client2.list_users

  # Step 2: Create new users for each client
  puts "\n=== Creating new users ==="
  user1_id = SecureRandom.uuid
  user2_id = SecureRandom.uuid

  client1.create_user(user1_id, '1990-01-15', Date.today.prev_month.to_s)
  client2.create_user(user2_id, '1985-05-20', Date.today.prev_month.to_s)

  # Step 3: Get user details
  puts "\n=== Getting user details ==="
  client1.get_user(user1_id)
  client2.get_user(user2_id)

  # Step 4: Create transactions and earn points
  puts "\n=== Creating transactions ==="
  # Regular domestic transaction
  client1.create_transaction(user1_id, 100.0)
  # Foreign transaction (2x points)
  client1.create_transaction(user1_id, 100.0, 'EUR', true)

  # For client2 user
  client2.create_transaction(user2_id, 200.0)

  # Step 5: Check points balance
  puts "\n=== Checking points balances ==="
  client1.get_user_points(user1_id)
  client2.get_user_points(user2_id)

  # Step 6: Create more transactions to trigger rewards
  puts "\n=== Creating more transactions to trigger rewards ==="
  # Add enough transactions to pass the monthly threshold (100+ points)
  client1.create_transaction(user1_id, 900.0)

  # For new user spending reward (1000+ within first 60 days)
  client2.create_transaction(user2_id, 900.0)

  # Step 7: Check rewards
  puts "\n=== Checking rewards ==="
  client1.get_user_rewards(user1_id)
  client2.get_user_rewards(user2_id)

  # Check all rewards (including redeemed ones)
  client1.get_user_rewards(user1_id, 'all')

  # Step 8: Update user information
  puts "\n=== Updating user information ==="
  client1.update_user(user1_id, { birth_date: Date.today.strftime('%Y-%m-%d') })

  # Step 9: Delete a user (uncomment if needed)
  # puts "\n=== Deleting a user ==="
  # client1.delete_user(user1_id)

  puts "\n=== Simulation Complete ==="
end

# Run the simulation
run_simulation
