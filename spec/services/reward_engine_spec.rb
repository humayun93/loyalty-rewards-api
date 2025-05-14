require 'rails_helper'

RSpec.describe RewardEngine do
  let(:client) { create(:client) }
  
  # Set the current tenant immediately when let is defined
  before(:all) do
    # Create a client for the entire test suite to use
    @global_client = create(:client)
  end
  
  before(:each) do
    # Set tenant for each test
    ActsAsTenant.current_tenant = @global_client
    
    # Create fresh user and engine for each test
    @user = create(:user, client: @global_client)
    @engine = RewardEngine.new(@user)
  end
  
  after(:each) do
    ActsAsTenant.current_tenant = nil
  end
  
  describe '#process_transaction' do
    context 'when monthly points threshold is reached' do
      it 'issues a free coffee reward' do
        # Create a transaction that exceeds the monthly points threshold
        transaction = create(:transaction, user: @user, client: @global_client, 
                            amount: 1000, 
                            points_earned: RewardEngine::MONTHLY_POINTS_THRESHOLD)
        
        reward_count_before = @user.rewards.count
        rewards = @engine.process_transaction(transaction)
        
        expect(rewards).not_to be_empty
        expect(@user.rewards.count).to be > reward_count_before
        
        coffee_reward = @user.rewards.find_by(reward_type: 'free_coffee')
        expect(coffee_reward).not_to be_nil
        expect(coffee_reward.description).to include('Free coffee for earning')
      end
      
      it 'does not issue duplicate rewards in the same month' do
        # Create a transaction to get the first reward
        transaction1 = create(:transaction, user: @user, client: @global_client, 
                             amount: 1000, 
                             points_earned: RewardEngine::MONTHLY_POINTS_THRESHOLD)
        
        # Process first transaction and get initial rewards
        first_rewards = @engine.process_transaction(transaction1)
        initial_coffee_rewards = first_rewards.select { |r| r.reward_type == 'free_coffee' && 
                                                          r.description.include?('Free coffee for earning') }
        
        # Create another transaction in the same month
        transaction2 = create(:transaction, user: @user, client: @global_client, 
                             amount: 1000, 
                             points_earned: RewardEngine::MONTHLY_POINTS_THRESHOLD)
        
        # Process second transaction and check no new monthly coffee rewards
        second_rewards = @engine.process_transaction(transaction2)
        second_coffee_rewards = second_rewards.select { |r| r.reward_type == 'free_coffee' && 
                                                          r.description.include?('Free coffee for earning') }
        
        expect(second_coffee_rewards).to be_empty
      end
    end
    
    context 'when it is the user birthday month' do
      before(:each) do
        # Create a user with birth date in the current month
        @birth_date_user = create(:user, client: @global_client, 
                               birth_date: Date.today.change(year: 1990))
        @birth_engine = RewardEngine.new(@birth_date_user)
      end
      
      it 'issues a birthday free coffee reward' do
        transaction = create(:transaction, user: @birth_date_user, client: @global_client, amount: 10)
        
        reward_count_before = @birth_date_user.rewards.count
        rewards = @birth_engine.process_transaction(transaction)
        
        expect(rewards).not_to be_empty
        expect(@birth_date_user.rewards.count).to be > reward_count_before
        
        birthday_reward = @birth_date_user.rewards.find_by(reward_type: 'free_coffee', 
                                                        description: 'Birthday month free coffee')
        expect(birthday_reward).not_to be_nil
      end
      
      it 'does not issue duplicate birthday rewards in the same month' do
        # Issue first birthday reward
        transaction1 = create(:transaction, user: @birth_date_user, client: @global_client, amount: 10)
        first_rewards = @birth_engine.process_transaction(transaction1)
        
        # Try to issue another one
        transaction2 = create(:transaction, user: @birth_date_user, client: @global_client, amount: 10)
        second_rewards = @birth_engine.process_transaction(transaction2)
        
        birthday_rewards = second_rewards.select { |r| r.reward_type == 'free_coffee' && 
                                                    r.description == 'Birthday month free coffee' }
        expect(birthday_rewards).to be_empty
      end
    end
    
    context 'when new user spends over threshold in first 60 days' do
      before(:each) do
        # Create a user who recently joined
        @new_user = create(:user, client: @global_client, 
                         joining_date: 7.days.ago,
                         # Set birth date to a different month but in the past to avoid birthday rewards
                         birth_date: Date.today.prev_month(6).change(year: 1990))
        @new_user_engine = RewardEngine.new(@new_user)
      end
      
      it 'issues movie tickets reward' do
        transaction = create(:transaction, user: @new_user, client: @global_client, 
                            amount: RewardEngine::NEW_USER_TRANSACTION_THRESHOLD)
        
        reward_count_before = @new_user.rewards.count
        rewards = @new_user_engine.process_transaction(transaction)
        
        expect(rewards).not_to be_empty
        expect(@new_user.rewards.count).to be > reward_count_before
        
        movie_reward = @new_user.rewards.find_by(reward_type: 'movie_tickets')
        expect(movie_reward).not_to be_nil
        expect(movie_reward.description).to eq('New user spending reward')
      end
      
      it 'does not issue duplicate movie ticket rewards' do
        # Issue first movie reward
        transaction1 = create(:transaction, user: @new_user, client: @global_client, 
                            amount: RewardEngine::NEW_USER_TRANSACTION_THRESHOLD)
        @new_user_engine.process_transaction(transaction1)
        
        # Try to issue another one
        transaction2 = create(:transaction, user: @new_user, client: @global_client, 
                            amount: RewardEngine::NEW_USER_TRANSACTION_THRESHOLD)
        
        second_rewards = @new_user_engine.process_transaction(transaction2)
        movie_rewards = second_rewards.select { |r| r.reward_type == 'movie_tickets' }
        
        expect(movie_rewards).to be_empty
      end
      
      it 'does not issue if user is outside 60-day window' do
        # Update user to be outside the window
        @new_user.update(joining_date: 61.days.ago)
        
        transaction = create(:transaction, user: @new_user, client: @global_client, 
                            amount: RewardEngine::NEW_USER_TRANSACTION_THRESHOLD)
        
        # Get rewards count before
        reward_count_before = @new_user.rewards.count
        
        # Process transaction
        rewards = @new_user_engine.process_transaction(transaction)
        
        # Check no movie_ticket rewards
        movie_rewards = rewards.select { |r| r.reward_type == 'movie_tickets' }
        expect(movie_rewards).to be_empty
      end
    end
  end
  
  describe '#process_periodic_rewards' do
    context 'when it is the user birthday month' do
      before(:each) do
        # Create a user with birth date in the current month
        @birth_date_user = create(:user, client: @global_client, 
                               birth_date: Date.today.change(year: 1990))
        @birth_engine = RewardEngine.new(@birth_date_user)
      end
      
      it 'issues a birthday free coffee reward' do
        reward_count_before = @birth_date_user.rewards.count
        rewards = @birth_engine.process_periodic_rewards
        
        expect(rewards).not_to be_empty
        expect(@birth_date_user.rewards.count).to be > reward_count_before
        
        birthday_reward = @birth_date_user.rewards.find_by(reward_type: 'free_coffee', 
                                                        description: 'Birthday month free coffee')
        expect(birthday_reward).not_to be_nil
      end
    end
  end
end 