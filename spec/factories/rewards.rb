FactoryBot.define do
  factory :reward do
    association :user
    association :client
    reward_type { 'free_coffee' }
    issued_at { Time.current }
    expires_at { Time.current + 30.days }
    status { 'active' }
    description { 'Test reward' }
    
    trait :movie_tickets do
      reward_type { 'movie_tickets' }
      expires_at { Time.current + 60.days }
    end
    
    trait :redeemed do
      status { 'redeemed' }
    end
    
    trait :expired do
      status { 'expired' }
      expires_at { Time.current - 1.day }
    end
  end
end
