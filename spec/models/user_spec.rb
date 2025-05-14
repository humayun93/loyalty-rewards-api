require 'rails_helper'

RSpec.describe User, type: :model do
  # Create clients for testing
  let!(:client1) { create(:client, name: 'Client 1', subdomain: 'client1') }
  let!(:client2) { create(:client, name: 'Client 2', subdomain: 'client2') }
  
  describe 'validations' do
    # Use around hook to ensure tenant is set for all tests in this block
    around do |example|
      with_tenant(client1) do
        example.run
      end
    end
    
    it { should validate_presence_of(:user_id) }
    
    it 'validates uniqueness of user_id scoped to client' do
      # Create a user for client1 with a string ID
      user_id = "user123"
      create(:user, user_id: user_id, client: client1)
      
      # Same user_id for client1 should be invalid
      user = build(:user, user_id: user_id, client: client1)
      expect(user).not_to be_valid
      expect(user.errors[:user_id]).to include('has already been taken')
      
      # Test with a different tenant
      with_tenant(client2) do
        # Same user_id for client2 should be valid
        user2 = build(:user, user_id: user_id, client: client2)
        expect(user2).to be_valid
      end
    end
    
    it 'disallows email-like formats for user_id' do
      # Build a user with an email-like user_id
      user = build(:user, user_id: 'user@example.com')
      expect(user).not_to be_valid
      expect(user.errors[:user_id]).to include('cannot be an email address. Please use a UUID or other identifier.')
    end
    
    it 'allows arbitrary string formats for user_id' do
      # Test various valid user_id formats
      valid_ids = [
        'user123',               # Simple string
        'abc-123-xyz',           # Hyphenated string
        '123456789',             # Numeric string
        SecureRandom.uuid,       # UUID still works
        'custom_id_format_123'   # Custom format
      ]
      
      valid_ids.each do |id|
        user = build(:user, user_id: id)
        expect(user).to be_valid, "Expected user_id '#{id}' to be valid"
      end
    end

    describe 'date validations' do
      it 'validates birth_date format' do
        # Valid date format
        user = build(:user, birth_date: '1990-01-01')
        expect(user).to be_valid

        # Date object should also be valid
        user = build(:user, birth_date: Date.new(1990, 1, 1))
        expect(user).to be_valid
      end

      it 'validates future birth_date' do
        future_date = Date.today + 1.day
        user = build(:user, birth_date: future_date)
        expect(user).not_to be_valid
        expect(user.errors[:birth_date]).to include('cannot be in the future')
      end

      it 'validates unrealistically old birth_date' do
        very_old_date = Date.today - 121.years
        user = build(:user, birth_date: very_old_date)
        expect(user).not_to be_valid
        expect(user.errors[:birth_date]).to include('is unrealistically old')
      end

      it 'validates joining_date format' do
        # Valid date format
        user = build(:user, joining_date: '2020-01-01')
        expect(user).to be_valid

        # Date object should also be valid
        user = build(:user, joining_date: Date.new(2020, 1, 1))
        expect(user).to be_valid
      end

      it 'validates future joining_date' do
        future_date = Date.today + 1.day
        user = build(:user, joining_date: future_date)
        expect(user).not_to be_valid
        expect(user.errors[:joining_date]).to include('cannot be in the future')
      end
    end
  end
  
  describe 'tenant scoping' do
    before do
      # Create users for different clients with string IDs
      with_tenant(client1) do
        create(:user, user_id: "user1-client1", client: client1)
        create(:user, user_id: "user2-client1", client: client1)
      end
      
      with_tenant(client2) do
        create(:user, user_id: "user1-client2", client: client2)
      end
    end
    
    it 'scopes queries to the current tenant' do
      # Using client1 as tenant should only see client1's users
      with_tenant(client1) do
        expect(User.count).to eq(2)
      end
      
      # Using client2 as tenant should only see client2's users
      with_tenant(client2) do
        expect(User.count).to eq(1)
      end
    end
    
    it 'automatically assigns tenant to new records' do
      with_tenant(client1) do
        user = User.create(user_id: "new-user-id")
        expect(user.client).to eq(client1)
      end
    end
    
    it 'prevents access to other tenants records' do
      # Try to access a record from client2 while using client1 as tenant
      user_from_client2 = nil
      
      with_tenant(client2) do
        user_from_client2 = User.first
      end
      
      with_tenant(client1) do
        expect { User.find(user_from_client2.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end 