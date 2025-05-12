class User < ApplicationRecord
  acts_as_tenant :client

  validates :user_id, presence: true, uniqueness: { scope: :client_id }
end
