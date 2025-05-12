class User < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant :client
  
  # Validations
  validates :user_id, presence: true, uniqueness: { scope: :client_id }
end 