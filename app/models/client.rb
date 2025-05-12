class Client < ApplicationRecord
  has_secure_token :api_token, length: 24
  
  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true,
    format: {
        with: /\A[A-Za-z0-9](?:[A-Za-z0-9_-]*[A-Za-z0-9])?\z/,
        message: "only allows letters, numbers, hyphens, and underscores (cannot start or end with a hyphen or underscore)"
    }
end
