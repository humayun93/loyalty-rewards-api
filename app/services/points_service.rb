class PointsService
  # Base rule: 10 points per $100
  BASE_POINTS_RATE = 10
  BASE_AMOUNT = 100
  # 2x points for foreign spending
  FOREIGN_MULTIPLIER = 2

  # Calculate points earned for a transaction
  def self.calculate_points(transaction)
    # Calculate base points (10 points per $100)

    base_points = (transaction.amount / BASE_AMOUNT * BASE_POINTS_RATE)

    # Apply 2x multiplier for foreign transactions
    multiplier = transaction.foreign ? FOREIGN_MULTIPLIER : 1

    base_points * multiplier
  end

  # Process a transaction by calculating points and updating user's total
  def self.process_transaction(transaction)
    # Calculate points if not already set
    transaction.points_earned = calculate_points(transaction) if transaction.points_earned.zero?

    # Update user's points total
    user = transaction.user
    user.with_lock do
      user.points += transaction.points_earned
      user.save!
    end

    transaction.points_earned
  end
end
