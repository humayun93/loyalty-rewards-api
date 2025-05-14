namespace :stress_test do
  desc "Run transaction stress tests with configurable parameters"
  task transactions: :environment do
    # Get parameters from ENV or use defaults
    num_users = (ENV["USERS"] || 1000).to_i
    transactions_per_user = (ENV["TXN_PER_USER"] || 50).to_i
    concurrency_level = (ENV["CONCURRENCY"] || 20).to_i

    puts "========================================================"
    puts "Starting Transaction API Stress Test"
    puts "========================================================"
    puts "Configuration:"
    puts "  - Number of users: #{num_users}"
    puts "  - Transactions per user: #{transactions_per_user}"
    puts "  - Concurrency level: #{concurrency_level}"
    puts "  - Total transactions: #{num_users * transactions_per_user}"
    puts "========================================================\n\n"
    # Create a test client
    client = Client.find_or_create_by(name: "Stress Test Client", subdomain: "stress-test")

    # Create test users
    users = []
    ActsAsTenant.with_tenant(client) do
      puts "Creating #{num_users} test users..."
      num_users.times do |i|
        users << User.find_or_create_by(
          user_id: "stress-test-user-#{i}",
          birth_date: Date.new(1990, 1, 1),
          joining_date: Date.new(2020, 1, 1),
        )
        print "." if i % 10 == 0
      end
      puts "\nUsers created."
    end

    # Setup HTTP client for API requests
    require "net/http"
    require "uri"
    require "json"

    uri = URI.parse("#{ENV['API_URL'] || 'http://localhost:3000'}/api/v1/users")

    # Prepare authentication headers
    headers = {
      "Authorization" => "Bearer #{client.api_token}",
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }

    # Create a thread pool
    thread_pool = Queue.new
    total_transactions = num_users * transactions_per_user

    # Prepare transaction parameters for all users
    puts "Generating #{total_transactions} transaction requests..."
    users.each do |user|
      transactions_per_user.times do |i|
        # Create transaction with different parameters for each task
        thread_pool << {
          user: user,
          params: {
            transaction: {
              amount: 50.0 + (i * 10),
              currency: (i % 3 == 0) ? [ "EUR", "GBP", "JPY", "CAD" ].sample : "USD",
              foreign: (i % 3 == 0)
            }
          }
        }
      end
    end

    # Create a thread-safe result store using a mutex
    result_store = {
      successful: 0,
      failed: 0,
      response_times: []
    }
    result_mutex = Mutex.new

    # Process the transactions with controlled concurrency
    puts "Processing transactions with #{concurrency_level} concurrent threads..."
    start_time = Time.now

    # Create worker threads
    workers = []
    concurrency_level.times do
      workers << Thread.new do
        while !thread_pool.empty?
          begin
            # Thread-safe removal from queue
            work = thread_pool.pop(true) rescue nil
            break unless work

            user = work[:user]
            params = work[:params]

            # Prepare the request
            req_uri = URI.parse("#{ENV['API_URL'] || 'http://localhost:3000'}/api/v1/users/#{user.user_id}/transactions")
            request = Net::HTTP::Post.new(req_uri)
            headers.each { |key, value| request[key] = value }
            request.body = params.to_json

            # Send the request and measure response time
            req_start = Time.now
            response = Net::HTTP.start(req_uri.hostname, req_uri.port) do |http|
              http.request(request)
            end
            req_time = Time.now - req_start

            # Store the result with mutex protection
            is_success = response.code.to_i >= 200 && response.code.to_i < 300

            result_mutex.synchronize do
              if is_success
                result_store[:successful] += 1
              else
                result_store[:failed] += 1
                puts "Error in transaction: #{response.code} - #{response.body}"
              end

              # Store response time
              result_store[:response_times] << req_time

              # Progress indicator
              completed = result_store[:successful] + result_store[:failed]
              progress = (completed.to_f / total_transactions * 100).round
              if completed % 5 == 0 || completed == total_transactions
                print "\rProgress: #{progress}% complete (#{result_store[:successful]} succeeded, #{result_store[:failed]} failed)"
              end
            end
          rescue => e
            result_mutex.synchronize do
              puts "Error processing transaction: #{e.message}"
              result_store[:failed] += 1
            end
          end
        end
      end
    end

    # Wait for all workers to finish
    workers.each(&:join)

    # Calculate results
    total_time = Time.now - start_time

    # Safely calculate statistics
    avg_response_time = 0
    max_response_time = 0
    min_response_time = 0

    if result_store[:response_times].any?
      avg_response_time = result_store[:response_times].sum / result_store[:response_times].size
      max_response_time = result_store[:response_times].max
      min_response_time = result_store[:response_times].min
    end

    puts "\n\n========================================================"
    puts "Stress Test Results"
    puts "========================================================"
    puts "Total time: #{total_time.round(2)} seconds"
    puts "Total transactions: #{total_transactions}"
    puts "Successful transactions: #{result_store[:successful]}"
    puts "Failed transactions: #{result_store[:failed]}"
    puts "Success rate: #{(result_store[:successful].to_f / total_transactions * 100).round(2)}%"
    puts "Transactions per second: #{(total_transactions / total_time).round(2)}"
    puts "Average response time: #{avg_response_time.round(4)} seconds"
    puts "Minimum response time: #{min_response_time.round(4)} seconds"
    puts "Maximum response time: #{max_response_time.round(4)} seconds"
    puts "========================================================\n\n"

    puts "Verifying database state..."
    # Verify database state
    ActsAsTenant.with_tenant(client) do
      # Check that all users have the correct number of transactions
      all_good = true
      users.each do |user|
        user.reload
        actual_txn_count = user.transactions.count
        expected_txn_count = transactions_per_user

        if actual_txn_count != expected_txn_count
          puts "User #{user.user_id}: Expected #{expected_txn_count} transactions, but found #{actual_txn_count}"
          all_good = false
        end
      end

      puts all_good ? "All database checks passed!" : "Database verification failed! See errors above."
    end
  end
end
