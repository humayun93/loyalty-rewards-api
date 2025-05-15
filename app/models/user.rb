class User < ApplicationRecord
  acts_as_tenant :client

  has_many :transactions, dependent: :destroy
  has_many :rewards, dependent: :destroy

  validates :user_id, presence: true, uniqueness: { scope: :client_id }
  validate :validate_user_id_format
  validate :validate_date_formats

  # Control which attributes are exposed when converting to JSON
  def as_json(options = {})
    super(options.merge(only: [ :user_id, :birth_date, :points, :joining_date, :created_at, :updated_at ]))
  end

  # Custom validation to ensure user_id is not an email and is URL-safe
  def validate_user_id_format
    if user_id.present?
      if user_id.include?("@")
        errors.add(:user_id, "cannot be an email address. Please use a UUID or other identifier.")
      end

      if user_id.include?(" ")
        errors.add(:user_id, "cannot contain spaces")
      end

      unless user_id.match?(/\A[A-Za-z0-9\-_~]+\z/)
        errors.add(:user_id, "can only contain URL-safe characters (letters, numbers, and -_~)")
      end
    end
  end

  # Validate birth_date and joining_date formats
  def validate_date_formats
    # Joining date cannot be in the future
    if joining_date.present? && joining_date > Date.today
      errors.add(:joining_date, "cannot be in the future")
    end

    # Birth date should be reasonable (not in the future, not unrealistically old)
    if birth_date.present?
      if birth_date > Date.today
        errors.add(:birth_date, "cannot be in the future")
      elsif birth_date < Date.today - 120.years
        errors.add(:birth_date, "is unrealistically old")
      end
    end
  end

  # Get active rewards for a user
  def active_rewards
    rewards.active
  end

  # Check if user is currently in their birth month
  def birthday_month?
    birth_date.present? && birth_date.month == Date.today.month
  end

  # Check if user is a new user (joined within the last 60 days)
  def new_user?
    joining_date.present? && joining_date >= 60.days.ago
  end

  private

  def valid_date?(date)
    date.is_a?(Date)
  end
end
