FactoryBot.define do
  factory :user do
    user_id { Faker::Internet.email }
    birth_date { Faker::Date.birthday(min_age: 18, max_age: 65) }
    joining_date { Faker::Date.backward(days: 365) }
    points { 0 }
    
    # This association will be set automatically by acts_as_tenant
    # when a tenant is active, but we need it for testing
    client
  end
end 