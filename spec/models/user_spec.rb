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
      # Create a user for client1 with a UUID
      uuid = SecureRandom.uuid
      create(:user, user_id: uuid, client: client1)
      
      # Same user_id for client1 should be invalid
      user = build(:user, user_id: uuid, client: client1)
      expect(user).not_to be_valid
      expect(user.errors[:user_id]).to include('has already been taken')
      
      # Test with a different tenant
      with_tenant(client2) do
        # Same user_id for client2 should be valid
        user2 = build(:user, user_id: uuid, client: client2)
        expect(user2).to be_valid
      end
    end
    
    it 'disallows email-like formats for user_id' do
      # Build a user with an email-like user_id
      user = build(:user, user_id: 'user@example.com')
      expect(user).not_to be_valid
      expect(user.errors[:user_id]).to include('cannot be an email address. Please use a UUID or other identifier.')
    end
    
    it 'requires user_id to be a valid UUID format' do
      # Build a user with an invalid UUID format
      user = build(:user, user_id: 'not-a-uuid')
      expect(user).not_to be_valid
      expect(user.errors[:user_id]).to include('must be a valid UUID in format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx')
      
      # Build a user with a valid UUID
      valid_uuid = SecureRandom.uuid
      user = build(:user, user_id: valid_uuid)
      expect(user).to be_valid
    end
  end
  
  describe 'tenant scoping' do
    before do
      # Create users for different clients with UUIDs
      with_tenant(client1) do
        create(:user, user_id: SecureRandom.uuid, client: client1)
        create(:user, user_id: SecureRandom.uuid, client: client1)
      end
      
      with_tenant(client2) do
        create(:user, user_id: SecureRandom.uuid, client: client2)
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
        user = User.create(user_id: SecureRandom.uuid)
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