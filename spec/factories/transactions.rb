FactoryBot.define do
  factory :transaction do
    association :user
    client { user.client }
    amount { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    currency { "USD" }
    foreign { false }
    points_earned { 0 }
    
    # A convenient way to create a transaction with a user in a client
    trait :with_client do
      transient do
        client_object { create(:client) }
      end
      
      user { with_tenant(client_object) { create(:user, client: client_object) } }
      client { client_object }
    end
    
    trait :foreign do
      foreign { true }
      currency { Faker::Currency.code }
    end
  end
end
