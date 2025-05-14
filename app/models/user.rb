class User < ApplicationRecord
  acts_as_tenant :client

  has_many :transactions, dependent: :destroy

  validates :user_id, presence: true, uniqueness: { scope: :client_id }
  validate :validate_user_id_format

  # Control which attributes are exposed when converting to JSON
  def as_json(options = {})
    super(options.merge(only: [ :user_id, :birth_date, :points, :joining_date, :created_at, :updated_at ]))
  end

  # Custom validation to ensure user_id is not an email but allows UUID format
  def validate_user_id_format
    if user_id.present? && user_id.include?("@")
      errors.add(:user_id, "cannot be an email address. Please use a UUID or other identifier.")
    end

    # Optional: Validate that it follows a UUID format if needed
    unless user_id.nil? || user_id.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
      errors.add(:user_id, "must be a valid UUID in format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx")
    end
  end
end
