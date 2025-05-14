require 'csv'

# Define the benchmark file path
benchmark_file = File.join(File.dirname(__FILE__), 'benchmarks', 'transaction_benchmarks.csv')

if File.exist?(benchmark_file)
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
else
  puts "Benchmark file not found at: #{benchmark_file}"
end 