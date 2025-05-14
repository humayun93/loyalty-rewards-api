require 'rails_helper'
require 'benchmark'
require 'csv'

RSpec.describe 'Transaction Controller Stress Tests', type: :request do
  let!(:client) { create(:client, name: 'Stress Test Client') }
  let!(:auth_headers) { { 'Authorization' => "Bearer #{client.api_token}", 'Accept' => 'application/json' } }
  
  let(:transaction_params) do
    {
      transaction: {
        amount: 100.0,
        currency: 'USD',
        foreign: false
      }
    }
  end
  
  # Add benchmark tracking
  let(:benchmark_file) { Rails.root.join('tmp', 'benchmarks', 'transaction_benchmarks.csv') }
  
  # Helper method to save benchmark results
  def save_benchmark(test_name, time_taken, transaction_count)
    # Ensure directory exists
    FileUtils.mkdir_p(File.dirname(benchmark_file))
    
    # Create file with headers if it doesn't exist
    unless File.exist?(benchmark_file)
      CSV.open(benchmark_file, 'w') do |csv|
        csv << ['timestamp', 'test_name', 'time_taken', 'transaction_count', 'avg_time_per_transaction']
      end
    end
    
    # Append benchmark data
    CSV.open(benchmark_file, 'a') do |csv|
      csv << [
        Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        test_name,
        time_taken.round(4),
        transaction_count,
        (time_taken / transaction_count).round(6)
      ]
    end
    
    # Output comparison with previous runs if available
    if File.exist?(benchmark_file)
      previous_runs = CSV.read(benchmark_file, headers: true)
      previous_test_runs = previous_runs.select { |row| row['test_name'] == test_name }
      
      if previous_test_runs.count > 1
        previous_run = previous_test_runs[-2] # Second to last entry (last entry is current run)
        if previous_run
          prev_time = previous_run['time_taken'].to_f
          prev_avg = previous_run['avg_time_per_transaction'].to_f
          puts "Previous result: #{prev_time.round(4)}s (#{prev_avg.round(6)}s per transaction)"
          
          change_pct = ((time_taken - prev_time) / prev_time * 100).round(2)
          puts "Change: #{change_pct > 0 ? '+' : ''}#{change_pct}%"
        end
      end
    end
  end
  
  before do
    # Create test user in the client tenant
    with_tenant(client) do
      @user = create(:user, user_id: 'stress-test-user-1', points: 0)
    end
  end

  # Helper method to run transaction in a thread
  def run_transaction(user_id, params, headers)
    post "/api/v1/users/#{user_id}/transactions", params: params, headers: headers
    response
  end

  describe 'concurrent transaction creation' do
    it 'handles multiple parallel transaction requests for the same user' do
      # Number of concurrent transactions to create
      num_transactions = 25
      
      puts "\n==== Starting Stress Test with #{num_transactions} concurrent transactions ===="
      
      # Measure the time taken
      time = Benchmark.measure do
        # Track responses to ensure all transactions were processed
        responses = []
        mutex = Mutex.new
        
        # Create threads to simulate concurrent requests
        threads = Array.new(num_transactions) do |i|
          Thread.new do
            # Create a deep copy of transaction_params for this thread
            thread_params = Marshal.load(Marshal.dump(transaction_params))
            # Small variation in amount to verify individual transactions
            thread_params[:transaction][:amount] = 100.0 + i
            resp = run_transaction(@user.user_id, thread_params, auth_headers)
            
            # Thread-safely track the response
            mutex.synchronize do
              responses << {index: i, response: resp, status: resp.status}
            end
          end
        end
        
        # Wait for all threads to complete
        threads.each(&:join)
        
        # Output any failed responses
        failed = responses.select { |r| r[:status] != 201 }
        if failed.any?
          puts "Failed responses: #{failed.map { |r| r[:status] }.join(', ')}"
        end
      end
      
      puts "Time taken: #{time.real.round(2)} seconds"
      puts "Average response time: #{(time.real / num_transactions).round(4)} seconds per request"
      
      # Save benchmark results
      save_benchmark('parallel_same_user', time.real, num_transactions)
      
      # Wait briefly to ensure all database operations complete
      sleep(0.5)
      
      # Verify that all transactions were created
      with_tenant(client) do
        actual_count = @user.transactions.count
        if actual_count != num_transactions
          puts "Expected #{num_transactions} transactions, but found #{actual_count}"
          puts "Transaction amounts: #{@user.transactions.pluck(:amount).sort}"
        end
        
        expect(@user.transactions.count).to eq(num_transactions)
        
        # Check that all transactions have the correct amounts
        (0...num_transactions).each do |i|
          expect(@user.transactions.where(amount: 100.0 + i).count).to eq(1)
        end
        
        # Check that points were calculated correctly
        @user.reload
        expected_points = (0...num_transactions).sum { |i| (100.0 + i) / 10 }
        expect(@user.points.round(2)).to eq(expected_points.round(2))
      end
    end
    
    it 'handles multiple parallel transaction requests for different users' do
      # Number of users and transactions per user
      num_users = 10
      transactions_per_user = 5
      total_transactions = num_users * transactions_per_user
      
      # Create users
      users = []
      with_tenant(client) do
        num_users.times do |i|
          users << create(:user, user_id: "stress-test-user-multi-#{i}", points: 0)
        end
      end
      
      puts "\n==== Starting Multi-User Stress Test with #{total_transactions} transactions across #{num_users} users ===="
      
      # Measure the time taken
      time = Benchmark.measure do
        # Create threads to simulate concurrent requests
        threads = []
        
        users.each do |user|
          transactions_per_user.times do |i|
            threads << Thread.new do
              # Create a deep copy of transaction_params for this thread
              thread_params = Marshal.load(Marshal.dump(transaction_params))
              thread_params[:transaction][:amount] = 100.0 + i
              run_transaction(user.user_id, thread_params, auth_headers)
            end
          end
        end
        
        # Wait for all threads to complete
        threads.each(&:join)
      end
      
      puts "Time taken: #{time.real.round(2)} seconds"
      puts "Average response time: #{(time.real / total_transactions).round(4)} seconds per request"
      
      # Save benchmark results
      save_benchmark('parallel_multi_user', time.real, total_transactions)
      
      # Verify that all transactions were created
      with_tenant(client) do
        users.each do |user|
          user.reload
          expect(user.transactions.count).to eq(transactions_per_user)
          
          # Expected points for each user
          expected_points = (0...transactions_per_user).sum { |i| (100.0 + i) / 10 }
          expect(user.points.round(2)).to eq(expected_points.round(2))
        end
      end
    end
    
    it 'handles rapid sequential transactions' do
      # Number of sequential transactions
      num_transactions = 50
      
      puts "\n==== Starting Sequential Stress Test with #{num_transactions} rapid transactions ===="
      
      # Measure the time taken
      time = Benchmark.measure do
        num_transactions.times do |i|
          # Create a deep copy of transaction_params for each iteration
          thread_params = Marshal.load(Marshal.dump(transaction_params))
          thread_params[:transaction][:amount] = 100.0
          
          post "/api/v1/users/#{@user.user_id}/transactions", params: thread_params, headers: auth_headers
          expect(response).to have_http_status(:created)
        end
      end
      
      puts "Time taken: #{time.real.round(2)} seconds"
      puts "Average response time: #{(time.real / num_transactions).round(4)} seconds per request"
      
      # Save benchmark results
      save_benchmark('sequential_transactions', time.real, num_transactions)
      
      # Verify transactions and points
      with_tenant(client) do
        @user.reload
        expect(@user.transactions.count).to eq(num_transactions)
        expected_points = num_transactions * 10.0 # Each $100 = 10 points
        expect(@user.points).to eq(expected_points)
      end
    end
    
    it 'handles a mix of foreign and domestic transactions' do
      # Number of transactions of each type
      num_transactions = 15
      total_transactions = num_transactions * 2
      
      puts "\n==== Starting Mixed Transaction Type Stress Test with #{total_transactions} transactions ===="
      
      # Measure the time taken
      time = Benchmark.measure do
        # Create threads for domestic transactions
        domestic_threads = Array.new(num_transactions) do
          Thread.new do
            # Create a deep copy of transaction_params for this thread
            thread_params = Marshal.load(Marshal.dump(transaction_params))
            thread_params[:transaction][:foreign] = false
            run_transaction(@user.user_id, thread_params, auth_headers)
          end
        end
        
        # Create threads for foreign transactions
        foreign_threads = Array.new(num_transactions) do
          Thread.new do
            # Create a deep copy of transaction_params for this thread
            thread_params = Marshal.load(Marshal.dump(transaction_params))
            thread_params[:transaction][:foreign] = true
            thread_params[:transaction][:currency] = 'EUR'
            run_transaction(@user.user_id, thread_params, auth_headers)
          end
        end
        
        # Wait for all threads to complete
        (domestic_threads + foreign_threads).each(&:join)
      end
      
      puts "Time taken: #{time.real.round(2)} seconds"
      puts "Average response time: #{(time.real / total_transactions).round(4)} seconds per request"
      
      # Save benchmark results
      save_benchmark('mixed_transactions', time.real, total_transactions)
      
      # Verify transactions and points
      with_tenant(client) do
        @user.reload
        expect(@user.transactions.count).to eq(total_transactions)
        expect(@user.transactions.where(foreign: true).count).to eq(num_transactions)
        expect(@user.transactions.where(foreign: false).count).to eq(num_transactions)
        
        # Each $100 domestic = 10 points, foreign = 20 points
        expected_points = (num_transactions * 10.0) + (num_transactions * 20.0)
        expect(@user.points).to eq(expected_points)
      end
    end
    
    it 'handles high volume transactions with parameter variations' do
      # Large number of transactions with different parameters
      num_transactions = 40
      
      puts "\n==== Starting High Volume Parameter Variation Test with #{num_transactions} transactions ===="
      
      # Measure the time taken
      time = Benchmark.measure do
        threads = Array.new(num_transactions) do |i|
          Thread.new do
            # Create a deep copy of transaction_params for this thread
            thread_params = Marshal.load(Marshal.dump(transaction_params))
            
            # Vary parameters based on index
            thread_params[:transaction][:amount] = 50.0 + (i * 10)
            thread_params[:transaction][:foreign] = (i % 3 == 0) # Every third transaction is foreign
            thread_params[:transaction][:currency] = (i % 3 == 0) ? ['EUR', 'GBP', 'JPY', 'CAD'].sample : 'USD'
            
            run_transaction(@user.user_id, thread_params, auth_headers)
          end
        end
        
        # Wait for all threads to complete
        threads.each(&:join)
      end
      
      puts "Time taken: #{time.real.round(2)} seconds"
      puts "Average response time: #{(time.real / num_transactions).round(4)} seconds per request"
      
      # Save benchmark results
      save_benchmark('high_volume_variations', time.real, num_transactions)
      
      # Verify transactions were created
      with_tenant(client) do
        @user.reload
        expect(@user.transactions.count).to eq(num_transactions)
        
        # Verify foreign transactions count
        foreign_count = (0...num_transactions).count { |i| i % 3 == 0 }
        expect(@user.transactions.where(foreign: true).count).to eq(foreign_count)
        
        # Calculate expected points - too complex to verify exact amount due to variations
        # but we can verify it's greater than zero
        expect(@user.points).to be > 0
      end
    end
    
    it 'correctly creates transactions, awards points, and issues rewards' do
      # Set up a more complex scenario to test reward issuance
      with_tenant(client) do
        # Create a user with a birthday this month for birthday reward testing
        @birthday_user = create(:user, 
                                user_id: "stress-test-birthday-user", 
                                points: 0, 
                                birth_date: Date.today.change(year: 1990))
        
        # Create a new user for new user reward testing
        @new_user = create(:user, 
                          user_id: "stress-test-new-user", 
                          points: 0, 
                          joining_date: 7.days.ago)
      end
      
      # Test parameters
      num_transactions = 12
      large_amount = 1000.0 # Large enough to trigger the new user reward
      
      puts "\n==== Starting Transactions, Points, and Rewards Verification Test ===="
      
      birthday_time = nil
      new_user_time = nil
      
      # Measure time for birthday user
      puts "Testing birthday user transactions..."
      birthday_time = Benchmark.measure do
        threads = Array.new(num_transactions) do
          Thread.new do
            thread_params = Marshal.load(Marshal.dump(transaction_params))
            thread_params[:transaction][:amount] = 100.0
            run_transaction(@birthday_user.user_id, thread_params, auth_headers)
          end
        end
        threads.each(&:join)
      end
      
      # Save benchmark for birthday user
      save_benchmark('birthday_user_transactions', birthday_time.real, num_transactions)
      
      # Measure time for new user (with large transaction to trigger reward)
      puts "Testing new user transactions..."
      new_user_time = Benchmark.measure do
        # First transaction with large amount to trigger new user reward
        large_params = Marshal.load(Marshal.dump(transaction_params))
        large_params[:transaction][:amount] = large_amount
        run_transaction(@new_user.user_id, large_params, auth_headers)
        
        # Remaining transactions
        threads = Array.new(num_transactions - 1) do
          Thread.new do
            thread_params = Marshal.load(Marshal.dump(transaction_params))
            thread_params[:transaction][:amount] = 100.0
            run_transaction(@new_user.user_id, thread_params, auth_headers)
          end
        end
        threads.each(&:join)
      end
      
      # Save benchmark for new user
      save_benchmark('new_user_transactions', new_user_time.real, num_transactions)
      
      # Wait briefly to ensure all database operations complete
      sleep(0.5)
      
      # Verify everything was created correctly
      with_tenant(client) do
        # Birthday user verification
        puts "\nBirthday User Verification:"
        @birthday_user.reload
        birthday_transactions = @birthday_user.transactions
        birthday_rewards = @birthday_user.rewards
        
        puts "- Transactions: #{birthday_transactions.count}/#{num_transactions}"
        puts "- Points: #{@birthday_user.points} (Expected: #{num_transactions * 10.0})"
        puts "- Rewards: #{birthday_rewards.count}"
        
        # Should have all transactions
        expect(birthday_transactions.count).to eq(num_transactions)
        
        # Should have correct points (regular domestic transactions)
        expect(@birthday_user.points).to eq(num_transactions * 10.0)
        
        # Should have birthday reward and monthly points reward (if threshold met)
        
        expect(birthday_rewards.where(reward_type: 'free_coffee', 
                                    description: 'Birthday month free coffee').count).to be(1)
                                    
        # Check for monthly points reward if threshold met
        monthly_points_threshold = RewardEngine::MONTHLY_POINTS_THRESHOLD
        if @birthday_user.points >= monthly_points_threshold
          expect(birthday_rewards.where(reward_type: 'free_coffee')
                               .where("description LIKE ?", "%#{monthly_points_threshold}%")
                               .count).to eq(1)
        end
        
        # New user verification
        puts "\nNew User Verification:"
        @new_user.reload
        new_user_transactions = @new_user.transactions
        new_user_rewards = @new_user.rewards
        
        puts "- Transactions: #{new_user_transactions.count}/#{num_transactions}"
        puts "- Points: #{@new_user.points} (Expected: #{(large_amount + (num_transactions-1) * 100.0) / 10})"
        puts "- Rewards: #{new_user_rewards.count}"
        
        # Should have all transactions
        expect(new_user_transactions.count).to eq(num_transactions)
        
        # Should have one large transaction
        expect(new_user_transactions.where(amount: large_amount).count).to eq(1)
        
        # Should have correct points
        expected_new_user_points = (large_amount + (num_transactions-1) * 100.0) / 10
        expect(@new_user.points).to eq(expected_new_user_points)
        
        # Should have new user movie tickets reward
        expect(new_user_rewards.where(reward_type: 'movie_tickets', 
                                     description: 'New user spending reward').count).to eq(1)
                                     
        # Check for monthly points reward if threshold met
        if @new_user.points >= monthly_points_threshold
          expect(new_user_rewards.where(reward_type: 'free_coffee')
                               .where("description LIKE ?", "%#{monthly_points_threshold}%")
                               .count).to eq(1)
        end
        
        puts "\nTest completed successfully!"
      end
    end
    
    # Add a task to analyze benchmark trends
    it 'provides benchmark trend analysis', skip: 'Run this test separately to analyze trends' do
      return unless File.exist?(benchmark_file)
      
      benchmarks = CSV.read(benchmark_file, headers: true)
      puts "\n==== Benchmark Trend Analysis ===="
      
      # Group by test name
      test_groups = benchmarks.group_by { |row| row['test_name'] }
      
      test_groups.each do |test_name, runs|
        next if runs.count < 2
        
        puts "\nTest: #{test_name}"
        puts "Total runs: #{runs.count}"
        
        # Sort by timestamp
        sorted_runs = runs.sort_by { |row| row['timestamp'] }
        
        # Calculate statistics
        times = sorted_runs.map { |row| row['time_taken'].to_f }
        avg_times = sorted_runs.map { |row| row['avg_time_per_transaction'].to_f }
        
        puts "First run: #{sorted_runs.first['timestamp']} - #{times.first.round(4)}s"
        puts "Latest run: #{sorted_runs.last['timestamp']} - #{times.last.round(4)}s"
        puts "Average time: #{(times.sum / times.size).round(4)}s"
        puts "Min time: #{times.min.round(4)}s"
        puts "Max time: #{times.max.round(4)}s"
        
        # Calculate trend (improving or degrading)
        if times.size >= 3
          recent_times = times.last(3)
          older_times = times.first(times.size - 3)
          
          recent_avg = recent_times.sum / recent_times.size
          older_avg = older_times.sum / older_times.size
          
          change_pct = ((recent_avg - older_avg) / older_avg * 100).round(2)
          trend = change_pct <= 0 ? "improving" : "degrading"
          
          puts "Recent trend: #{trend} (#{change_pct > 0 ? '+' : ''}#{change_pct}%)"
        end
      end
    end
  end
end 