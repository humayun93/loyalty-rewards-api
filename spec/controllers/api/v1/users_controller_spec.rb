require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do
  # Use the sequence in factory instead of hardcoding subdomain
  let!(:client1) { create(:client, name: 'Client One') }
  let!(:client2) { create(:client, name: 'Client Two') }
  
  before(:all) do
    DatabaseCleaner.clean_with(:truncation)
  end
  
  after(:all) do
    DatabaseCleaner.clean_with(:truncation)
  end
  
  describe 'when authenticated as client1' do
    before do
      # Create test users within their tenant context
      ActsAsTenant.with_tenant(client1) do
        @client1_user1 = create(:user, user_id: 'user1@client1.com')
        @client1_user2 = create(:user, user_id: 'user2@client1.com')
      end
      
      ActsAsTenant.with_tenant(client2) do
        @client2_user = create(:user, user_id: 'user@client2.com')
      end
      
      # Mock authentication methods
      allow_any_instance_of(ApplicationController).to receive(:current_client).and_return(client1)
      allow_any_instance_of(ApplicationController).to receive(:authenticate_client!)
        .and_wrap_original do |m, *args|
          ActsAsTenant.current_tenant = client1
          true
        end
    end
    
    describe 'GET #index' do
      it 'returns only users for client1' do
        get :index
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(2)
        user_ids = json_response.map { |user| user['user_id'] }
        expect(user_ids).to contain_exactly('user1@client1.com', 'user2@client1.com')
      end
    end
    
    describe 'GET #show' do
      it 'returns the requested user for client1' do
        get :show, params: { user_id: @client1_user1.user_id }
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['user_id']).to eq('user1@client1.com')
      end
      
      it 'cannot access users from client2' do
        get :show, params: { user_id: @client2_user.user_id }
        expect(response).to have_http_status(:not_found)
      end
    end
    
    describe 'POST #create' do
      it 'creates a user associated with client1' do
        user_params = {
          user: {
            user_id: 'new@client1.com',
            birth_date: '1990-01-01',
            joining_date: '2020-01-01'
          }
        }
        
        post :create, params: user_params
        expect(response).to have_http_status(:created)
        
        json_response = JSON.parse(response.body)
        expect(json_response['user_id']).to eq('new@client1.com')
        expect(json_response['birth_date']).to include('1990-01-01')
        expect(json_response['joining_date']).to include('2020-01-01')
        
        # Verify the user is associated with client1
        ActsAsTenant.with_tenant(client1) do
          new_user = User.find_by(user_id: 'new@client1.com')
          expect(new_user.client).to eq(client1)
        end
      end
    end
    
    describe 'PATCH/PUT #update' do
      it 'updates the requested user' do
        updated_params = {
          user_id: @client1_user1.user_id,
          user: {
            birth_date: '1995-05-05'
          }
        }
        
        put :update, params: updated_params
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['birth_date']).to include('1995-05-05')
        
        # Verify the database was updated
        ActsAsTenant.with_tenant(client1) do
          @client1_user1.reload
          expect(@client1_user1.birth_date.to_s).to include('1995-05-05')
        end
      end
      
      it 'cannot update users from client2' do
        updated_params = {
          user_id: @client2_user.user_id,
          user: {
            birth_date: '1995-05-05'
          }
        }
        
        put :update, params: updated_params
        expect(response).to have_http_status(:not_found)
      end
    end
    
    describe 'DELETE #destroy' do
      it 'destroys the requested user' do
        expect {
          delete :destroy, params: { user_id: @client1_user1.user_id }
        }.to change { 
          ActsAsTenant.with_tenant(client1) { User.count }
        }.by(-1)
        
        expect(response).to have_http_status(:no_content)
      end
      
      it 'cannot destroy users from client2' do
        expect {
          delete :destroy, params: { user_id: @client2_user.user_id }
        }.not_to change {
          ActsAsTenant.with_tenant(client2) { User.count }
        }
        
        expect(response).to have_http_status(:not_found)
      end
    end
  end
  
  describe 'when authenticated as client2' do
    before do
      # Create test users within their tenant context
      ActsAsTenant.with_tenant(client1) do
        @client1_user1 = create(:user, user_id: 'user1@client1.com')
        @client1_user2 = create(:user, user_id: 'user2@client1.com')
      end
      
      ActsAsTenant.with_tenant(client2) do
        @client2_user = create(:user, user_id: 'user@client2.com')
      end
      
      # Mock authentication methods
      allow_any_instance_of(ApplicationController).to receive(:current_client).and_return(client2)
      allow_any_instance_of(ApplicationController).to receive(:authenticate_client!)
        .and_wrap_original do |m, *args|
          ActsAsTenant.current_tenant = client2
          true
        end
    end
    
    describe 'GET #index' do
      it 'returns only users for client2' do
        get :index
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(1)
        expect(json_response[0]['user_id']).to eq('user@client2.com')
      end
    end
  end
end