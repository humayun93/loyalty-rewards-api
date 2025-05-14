class PointsService
  # Base rule: 10 points per $100
  BASE_POINTS_RATE = 10
  BASE_AMOUNT = 100
  # 2x points for foreign spending
  FOREIGN_MULTIPLIER = 2
  # Round to 3 decimal places for consistent results
  PRECISION = 3

  # Calculate points earned for a transaction
  def self.calculate_points(transaction)
    # Calculate base points (10 points per $100)
    # Use to_f to ensure we get fractional points for smaller amounts
    base_points = (transaction.amount.to_f / BASE_AMOUNT * BASE_POINTS_RATE)

    # Apply 2x multiplier for foreign transactions
    multiplier = transaction.foreign ? FOREIGN_MULTIPLIER : 1

    result = base_points * multiplier

    result.round(PRECISION)
  end

  # Process a transaction by calculating points and updating user's total
  def self.process_transaction(transaction)
    # Calculate points if not already set
    if transaction.points_earned.zero?
      transaction.points_earned = calculate_points(transaction)
      transaction.save! # Save the transaction with points_earned
    end

    # Update user's points total
    user = transaction.user
    user.points += transaction.points_earned
    user.save!

    transaction.points_earned
  end
end
