class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :client

  acts_as_tenant(:client)

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :foreign, inclusion: { in: [ true, false ] }
  validates :points_earned, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Add a callback to calculate points via PointsService before saving for consistency
  before_save :calculate_points, if: -> { points_earned.zero? }

  private

  def calculate_points
    self.points_earned = PointsService.calculate_points(self)
  end
end
