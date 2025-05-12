# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create demo clients
puts "Creating clients..."

clients = [
  { name: "Acme Corporation", subdomain: "acme" },
  { name: "Globex Industries", subdomain: "globex" },
  { name: "Oceanic Airlines", subdomain: "oceanic" }
]

clients.each do |client_attrs|
  client = Client.find_or_initialize_by(subdomain: client_attrs[:subdomain])
  client.name = client_attrs[:name]
  
  if client.new_record?
    client.save!
    puts "Created client #{client.name} with token: #{client.api_token}"
  else
    puts "Client #{client.name} already exists"
  end
end

puts "Finished creating clients"
