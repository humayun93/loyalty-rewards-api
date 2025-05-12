FactoryBot.define do
  factory :client do
    name { Faker::Company.name }
    sequence(:subdomain) { |n| "client#{n}" }
  end
end 