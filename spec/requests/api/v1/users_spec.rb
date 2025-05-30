require 'rails_helper'

RSpec.describe 'API V1 Users', type: :request do
  let!(:client1) { create(:client, name: 'Client One') }
  let!(:client2) { create(:client, name: 'Client Two') }

  describe 'when authenticated as client1' do
    before do
      with_tenant(client1) do
        @client1_user1 = create(:user, user_id: SecureRandom.uuid)
        @client1_user2 = create(:user, user_id: SecureRandom.uuid)
      end
      
      with_tenant(client2) do
        @client2_user = create(:user, user_id: SecureRandom.uuid)
      end
      
      @auth_headers = { 'Authorization' => "Bearer #{client1.api_token}", 'Accept' => 'application/json' }
    end
    
    after do
      ActsAsTenant.current_tenant = nil
    end
    
    describe 'GET /api/v1/users' do
      it 'returns only users for client1' do
        get '/api/v1/users', headers: @auth_headers
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(2)
        user_ids = json_response.map { |user| user['user_id'] }
        expect(user_ids).to contain_exactly(@client1_user1.user_id, @client1_user2.user_id)
      end
    end
    
    describe 'GET /api/v1/users/:user_id' do
      it 'returns the requested user for client1' do
        get "/api/v1/users/#{@client1_user1.user_id}", headers: @auth_headers
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['user_id']).to eq(@client1_user1.user_id)
      end
      
      it 'cannot access users from client2' do
        get "/api/v1/users/#{@client2_user.user_id}", headers: @auth_headers
        
        expect(response).to have_http_status(:not_found)
      end
    end
    
    describe 'POST /api/v1/users' do
      it 'creates a user associated with client1' do
        new_uuid = SecureRandom.uuid
        user_params = {
          user: {
            user_id: new_uuid,
            birth_date: '1990-01-01',
            joining_date: '2020-01-01'
          }
        }
        
        expect {
          post '/api/v1/users', params: user_params, headers: @auth_headers
        }.to change {
          with_tenant(client1) { User.count }
        }.by(1)
        
        expect(response).to have_http_status(:created)
        
        json_response = JSON.parse(response.body)
        expect(json_response['user_id']).to eq(new_uuid)
        expect(json_response['birth_date']).to include('1990-01-01')
        expect(json_response['joining_date']).to include('2020-01-01')
        
        # Verify the user is associated with client1
        with_tenant(client1) do
          new_user = User.find_by(user_id: new_uuid)
          expect(new_user.client).to eq(client1)
        end
      end
      
      it 'validates birth_date format' do
        user_params = {
          user: {
            user_id: SecureRandom.uuid,
            birth_date: 'invalid-date',
            joining_date: '2020-01-01'
          }
        }
        
        post '/api/v1/users', params: user_params, headers: @auth_headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Birth date must be a valid date')
      end
      
      it 'validates joining_date format' do
        user_params = {
          user: {
            user_id: SecureRandom.uuid,
            birth_date: '1990-01-01',
            joining_date: 'not-a-date'
          }
        }
        
        post '/api/v1/users', params: user_params, headers: @auth_headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Joining date must be a valid date')
      end
    end
    
    describe 'PATCH/PUT /api/v1/users/:user_id' do
      it 'updates the requested user' do
        updated_params = {
          user: {
            birth_date: '1995-05-05'
          }
        }
        
        put "/api/v1/users/#{@client1_user1.user_id}", params: updated_params, headers: @auth_headers
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['birth_date']).to include('1995-05-05')
        
        # Verify the database was updated
        with_tenant(client1) do
          @client1_user1.reload
          expect(@client1_user1.birth_date.to_s).to include('1995-05-05')
        end
      end
      
      it 'validates birth_date format on update' do
        updated_params = {
          user: {
            birth_date: 'invalid-date-format'
          }
        }
        
        put "/api/v1/users/#{@client1_user1.user_id}", params: updated_params, headers: @auth_headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Birth date must be a valid date')
      end
      
      it 'validates joining_date format on update' do
        updated_params = {
          user: {
            joining_date: 'bad-date'
          }
        }
        
        put "/api/v1/users/#{@client1_user1.user_id}", params: updated_params, headers: @auth_headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Joining date must be a valid date')
      end
      
      it 'cannot update users from client2' do
        updated_params = {
          user: {
            birth_date: '1995-05-05'
          }
        }
        
        put "/api/v1/users/#{@client2_user.user_id}", params: updated_params, headers: @auth_headers
        
        expect(response).to have_http_status(:not_found)
      end
    end
    
    describe 'DELETE /api/v1/users/:user_id' do
      it 'destroys the requested user' do
        expect {
          delete "/api/v1/users/#{@client1_user1.user_id}", headers: @auth_headers
        }.to change { 
          with_tenant(client1) { User.count }
        }.by(-1)
        
        expect(response).to have_http_status(:no_content)
      end
      
      it 'cannot destroy users from client2' do
        expect {
          delete "/api/v1/users/#{@client2_user.user_id}", headers: @auth_headers
        }.not_to change {
          with_tenant(client2) { User.count }
        }
        
        expect(response).to have_http_status(:not_found)
      end
    end
  end
  
  describe 'when authenticated as client2' do
    before do
      # Create test users within their tenant context
      with_tenant(client1) do
        @client1_user1 = create(:user, user_id: SecureRandom.uuid)
        @client1_user2 = create(:user, user_id: SecureRandom.uuid)
      end
      
      with_tenant(client2) do
        @client2_user = create(:user, user_id: SecureRandom.uuid)
      end
      
      @auth_headers = { 'Authorization' => "Bearer #{client2.api_token}", 'Accept' => 'application/json' }
    end
    
    # Reset tenant after each test
    after do
      ActsAsTenant.current_tenant = nil
    end
    
    describe 'GET /api/v1/users' do
      it 'returns only users for client2' do
        get '/api/v1/users', headers: @auth_headers
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(1)
        expect(json_response[0]['user_id']).to eq(@client2_user.user_id)
      end
    end
  end

  describe 'GET /api/v1/users/:user_id/points' do
    before do
      @auth_headers = { 'Authorization' => "Bearer #{client1.api_token}", 'Accept' => 'application/json' }
    end
    
    let(:user) { create(:user, client: client1) }
    
    before do
      with_tenant(client1) do
        # Create some transactions for testing
        create(:transaction, user: user, client: client1, amount: 100, points_earned: 10, 
               created_at: Date.today)
        create(:transaction, user: user, client: client1, amount: 200, points_earned: 20,
               created_at: Date.today - 2.months)
      end
    end
    
    after do
      ActsAsTenant.current_tenant = nil
    end
    
    it 'returns the user points information' do
      get "/api/v1/users/#{user.user_id}/points", headers: @auth_headers
      
      expect(response).to have_http_status(:ok)
      
      json_response = JSON.parse(response.body)
      expect(json_response['user_id']).to eq(user.user_id)
      expect(json_response['current_points'].to_f).to eq(user.points.to_f)
      expect(json_response).to have_key('monthly_points')
      expect(json_response).to have_key('yearly_points')
    end
    
    it 'returns 404 for non-existent user' do
      get '/api/v1/users/non-existent/points', headers: @auth_headers
      
      expect(response).to have_http_status(:not_found)
    end
  end
  
  describe 'GET /api/v1/users/:user_id/rewards' do
    before do
      @auth_headers = { 'Authorization' => "Bearer #{client1.api_token}", 'Accept' => 'application/json' }
    end
    
    let(:user) { create(:user, client: client1) }
    
    before do
      with_tenant(client1) do
        # Create some rewards for testing
        create(:reward, user: user, client: client1, reward_type: 'free_coffee', status: 'active')
        create(:reward, user: user, client: client1, reward_type: 'free_coffee', status: 'redeemed')
        create(:reward, user: user, client: client1, reward_type: 'movie_tickets', status: 'active')
      end
    end
    
    after do
      ActsAsTenant.current_tenant = nil
    end
    
    context 'with default status (active)' do
      it 'returns only active rewards' do
        get "/api/v1/users/#{user.user_id}/rewards", headers: @auth_headers
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['user_id']).to eq(user.user_id)
        expect(json_response['rewards'].count).to eq(2)
        
        reward_types = json_response['rewards'].map { |r| r['status'] }.uniq
        expect(reward_types).to eq(['active'])
      end
    end
    
    context 'with status=all parameter' do
      it 'returns all rewards regardless of status' do
        get "/api/v1/users/#{user.user_id}/rewards?status=all", headers: @auth_headers
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['rewards'].count).to eq(3)
        
        reward_statuses = json_response['rewards'].map { |r| r['status'] }.uniq.sort
        expect(reward_statuses).to eq(['active', 'redeemed'])
      end
    end
    
    context 'with specific status parameter' do
      it 'returns only rewards with the specified status' do
        get "/api/v1/users/#{user.user_id}/rewards?status=redeemed", headers: @auth_headers
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['rewards'].count).to eq(1)
        
        expect(json_response['rewards'][0]['status']).to eq('redeemed')
      end
    end
    
    it 'returns 404 for non-existent user' do
      get '/api/v1/users/non-existent/rewards', headers: @auth_headers
      
      expect(response).to have_http_status(:not_found)
    end
  end
end 