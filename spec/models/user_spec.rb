require 'rails_helper'

RSpec.describe User, type: :model do
  # Create clients for testing
  let!(:client1) { create(:client, name: 'Client 1', subdomain: 'client1') }
  let!(:client2) { create(:client, name: 'Client 2', subdomain: 'client2') }
  
  describe 'validations' do
    # Use around hook to ensure tenant is set for all tests in this block
    around do |example|
      ActsAsTenant.with_tenant(client1) do
        example.run
      end
    end
    
    it { should validate_presence_of(:user_id) }
    
    it 'validates uniqueness of user_id scoped to client' do
      # Create a user for client1
      create(:user, user_id: 'test@example.com')
      
      # Same user_id for client1 should be invalid
      user = build(:user, user_id: 'test@example.com')
      expect(user).not_to be_valid
      expect(user.errors[:user_id]).to include('has already been taken')
      
      # Clear the tenant for this specific test
      ActsAsTenant.with_tenant(nil) do
        # Set a different tenant
        ActsAsTenant.with_tenant(client2) do
          # Same user_id for client2 should be valid
          user2 = build(:user, user_id: 'test@example.com')
          expect(user2).to be_valid
        end
      end
    end
  end
  
  describe 'tenant scoping' do
    before do
      # Create users for different clients
      ActsAsTenant.with_tenant(client1) do
        create(:user, user_id: 'test@example.com')
        create(:user, user_id: 'test2@example.com')
      end
      
      ActsAsTenant.with_tenant(client2) do
        create(:user, user_id: 'test@example.com')
      end
    end
    
    it 'scopes queries to the current tenant' do
      # Using client1 as tenant should only see client1's users
      ActsAsTenant.with_tenant(client1) do
        expect(User.count).to eq(2)
        expect(User.pluck(:user_id)).to contain_exactly('test@example.com', 'test2@example.com')
      end
      
      # Using client2 as tenant should only see client2's users
      ActsAsTenant.with_tenant(client2) do
        expect(User.count).to eq(1)
        expect(User.pluck(:user_id)).to contain_exactly('test@example.com')
      end
    end
    
    it 'automatically assigns tenant to new records' do
      ActsAsTenant.with_tenant(client1) do
        user = User.create(user_id: 'test3@example.com')
        expect(user.client).to eq(client1)
      end
    end
    
    it 'prevents access to other tenants records' do
      # Try to access a record from client2 while using client1 as tenant
      user_from_client2 = nil
      
      ActsAsTenant.with_tenant(client2) do
        user_from_client2 = User.first
      end
      
      ActsAsTenant.with_tenant(client1) do
        expect { User.find(user_from_client2.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end 