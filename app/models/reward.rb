class Reward < ApplicationRecord
  belongs_to :user
  belongs_to :client
  
  acts_as_tenant :client
  
  TYPES = ['free_coffee', 'movie_tickets'].freeze
  STATUSES = ['active', 'redeemed', 'expired'].freeze
  
  validates :reward_type, presence: true, inclusion: { in: TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :issued_at, presence: true
  validate :expiration_date_validation
  
  scope :active, -> { where(status: 'active') }
  scope :by_type, ->(type) { where(reward_type: type) }
  
  # Add a method to mark a reward as redeemed
  def redeem!
    update!(status: 'redeemed')
  end
  
  # Add a method to mark a reward as expired
  def expire!
    update!(status: 'expired')
  end
  
  private
  
  def expiration_date_validation
    if expires_at.present? && expires_at < issued_at
      errors.add(:expires_at, "cannot be before issued_at")
    end
  end
end
