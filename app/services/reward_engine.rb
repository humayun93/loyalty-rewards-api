class RewardEngine
  # Rule configurations
  MONTHLY_POINTS_THRESHOLD = 100 # Points needed for free coffee
  NEW_USER_TRANSACTION_THRESHOLD = 1000 # Dollars needed in first 60 days for movie tickets

  # Reward expiration configuration
  COFFEE_REWARD_EXPIRY = 30.days
  MOVIE_TICKET_EXPIRY = 60.days

  def initialize(user)
    @user = user
    @client = user.client
  end

  # Main method to process transaction and check for rewards
  def process_transaction(transaction)
    rewards_issued = []

    # Check monthly points for free coffee
    rewards_issued << check_monthly_points_reward(transaction)

    # Check birthday month for free coffee
    rewards_issued << check_birthday_reward

    # Check new user spending for movie tickets
    rewards_issued << check_new_user_spending(transaction)

    rewards_issued.compact
  end

  # Process rewards without a transaction (e.g., for birthday checks)
  def process_periodic_rewards
    rewards_issued = []

    rewards_issued << check_birthday_reward

    rewards_issued.compact
  end

  private

  # Check if user has earned enough points this month for a free coffee
  def check_monthly_points_reward(transaction)
    # Calculate points earned this month including current transaction
    start_of_month = Date.today.beginning_of_month
    end_of_month = Date.today.end_of_month

    monthly_points = @user.transactions
                        .where(created_at: start_of_month..end_of_month)
                        .sum(:points_earned) + transaction.points_earned

    # Check if user has already received a coffee reward this month
    existing_coffee_reward = @user.rewards
                                .where(reward_type: "free_coffee",
                                      issued_at: start_of_month..end_of_month,
                                      status: [ "active", "redeemed" ])
                                .exists?

    if monthly_points >= MONTHLY_POINTS_THRESHOLD && !existing_coffee_reward
      # Issue free coffee reward
      issue_reward("free_coffee", "Free coffee for earning #{MONTHLY_POINTS_THRESHOLD}+ points this month")
    end
  end

  # Check if it's the user's birthday month for a free coffee
  def check_birthday_reward
    # Check if user has a birth date
    return nil unless @user.birth_date.present?

    # Check if it's currently the user's birth month
    if @user.birthday_month?
      # Check if user already has a birthday reward this month
      start_of_month = Date.today.beginning_of_month
      end_of_month = Date.today.end_of_month

      existing_birthday_reward = @user.rewards
                                    .where(reward_type: "free_coffee",
                                          description: "Birthday month free coffee",
                                          issued_at: start_of_month..end_of_month,
                                          status: [ "active", "redeemed" ])
                                    .exists?

      unless existing_birthday_reward
        # Issue birthday coffee reward
        issue_reward("free_coffee", "Birthday month free coffee")
      end
    else
      nil
    end
  end

  # Check if new user has spent enough in first 60 days for movie tickets
  def check_new_user_spending(transaction)
    # Check if user is a new user (within first 60 days)
    return nil unless @user.new_user?

    # Check if user already has movie ticket reward
    existing_movie_reward = @user.rewards
                              .where(reward_type: "movie_tickets",
                                    description: "New user spending reward",
                                    status: [ "active", "redeemed" ])
                              .exists?

    return nil if existing_movie_reward

    # Calculate total spending in first 60 days
    joining_date = @user.joining_date
    spending_window_end = joining_date + 60.days

    # Return nil if outside the 60-day window
    return nil if Date.today > spending_window_end

    total_spending = @user.transactions
                        .where(created_at: joining_date..spending_window_end)
                        .sum(:amount) + transaction.amount

    if total_spending >= NEW_USER_TRANSACTION_THRESHOLD
      # Issue movie tickets reward
      issue_reward("movie_tickets", "New user spending reward", MOVIE_TICKET_EXPIRY)
    end
  end

  # Helper method to issue a reward
  def issue_reward(reward_type, description, expiry_days = COFFEE_REWARD_EXPIRY)
    @user.rewards.create!(
      client: @client,
      reward_type: reward_type,
      description: description,
      issued_at: Time.current,
      expires_at: Time.current + expiry_days,
      status: "active"
    )
  end
end
