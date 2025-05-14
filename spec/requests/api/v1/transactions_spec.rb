require 'rails_helper'

RSpec.describe 'API V1 Transactions', type: :request do
  let!(:client1) { create(:client, name: 'Client One') }
  let!(:client2) { create(:client, name: 'Client Two') }

  describe 'when authenticated as client1' do
    before do
      with_tenant(client1) do
        @client1_user = create(:user, user_id: '32ebc067-c66c-4300-98ee-379b37046174', points: 0)
      end
      
      with_tenant(client2) do
        @client2_user = create(:user, user_id: '8c347f65-bc8b-46ac-8fcc-c4a3febcfed5', points: 0)
      end
      
      @auth_headers = { 'Authorization' => "Bearer #{client1.api_token}", 'Accept' => 'application/json' }
    end
    
    describe 'POST /api/v1/users/:user_id/transactions' do
      context 'with valid parameters' do
        it 'creates a transaction and earns points' do
          transaction_params = {
            transaction: {
              amount: 100.0,
              currency: 'USD',
              foreign: false
            }
          }
          
          expect {
            post "/api/v1/users/#{@client1_user.user_id}/transactions", 
                 params: transaction_params,
                 headers: @auth_headers
          }.to change { 
            with_tenant(client1) { @client1_user.transactions.count }
          }.by(1)
          
          expect(response).to have_http_status(:created)
          
          json_response = JSON.parse(response.body)
          expect(json_response['transaction']['amount']).to eq('100.0')
          expect(json_response['transaction']['currency']).to eq('USD')
          expect(json_response['transaction']['foreign']).to eq(false)
          expect(json_response['points_earned']).to eq(10) # 10 points per $100
          expect(json_response['user_total_points']).to eq(10)
        end
        
        it 'applies multiplier for foreign transactions' do
          transaction_params = {
            transaction: {
              amount: 100.0,
              currency: 'EUR',
              foreign: true
            }
          }
          
          post "/api/v1/users/#{@client1_user.user_id}/transactions", 
               params: transaction_params,
               headers: @auth_headers
               
          expect(response).to have_http_status(:created)
          
          json_response = JSON.parse(response.body)
          expect(json_response['transaction']['foreign']).to eq(true)
          expect(json_response['points_earned']).to eq(20) # 2x points for foreign transactions
        end
        
        it 'defaults foreign to false when not provided' do
          transaction_params = {
            transaction: {
              amount: 100.0,
              currency: 'USD'
            }
          }
          
          post "/api/v1/users/#{@client1_user.user_id}/transactions", 
               params: transaction_params,
               headers: @auth_headers
               
          expect(response).to have_http_status(:created)
          
          json_response = JSON.parse(response.body)
          expect(json_response['transaction']['foreign']).to eq(false)
          expect(json_response['points_earned']).to eq(10)
        end
        
        it 'accumulates points for the user' do
          # First transaction
          post "/api/v1/users/#{@client1_user.user_id}/transactions", 
               params: {
                 transaction: {
                   amount: 100.0,
                   currency: 'USD'
                 }
               },
               headers: @auth_headers
          
          # Second transaction
          post "/api/v1/users/#{@client1_user.user_id}/transactions", 
               params: {
                 transaction: {
                   amount: 200.0,
                   currency: 'USD'
                 }
               },
               headers: @auth_headers
          
          json_response = JSON.parse(response.body)
          expect(json_response['points_earned']).to eq(20) # 20 points for $200
          expect(json_response['user_total_points']).to eq(30) # 10 + 20 = 30
        end
        
        it 'awards fractional points for smaller amounts' do
          post "/api/v1/users/#{@client1_user.user_id}/transactions", 
               params: {
                 transaction: {
                   amount: 25.0,
                   currency: 'USD'
                 }
               },
               headers: @auth_headers
               
          expect(response).to have_http_status(:created)
          
          json_response = JSON.parse(response.body)
          expect(json_response['points_earned']).to eq(2.5) # 2.5 points for $25 (10 points per $100)
          expect(json_response['user_total_points']).to eq(2.5)
          
          # Second transaction to see if fractional points accumulate correctly
          post "/api/v1/users/#{@client1_user.user_id}/transactions", 
               params: {
                 transaction: {
                   amount: 35.0,
                   currency: 'USD'
                 }
               },
               headers: @auth_headers
               
          expect(response).to have_http_status(:created)
          
          json_response = JSON.parse(response.body)
          expect(json_response['points_earned']).to eq(3.5) # 3.5 points for $35
          expect(json_response['user_total_points']).to eq(6.0) # 2.5 + 3.5 = 6.0
        end
      end
      
      context 'with invalid parameters' do
        it 'returns error when amount is missing' do
          post "/api/v1/users/#{@client1_user.user_id}/transactions", 
               params: {
                 transaction: {
                   currency: 'USD'
                 }
               },
               headers: @auth_headers
               
          expect(response).to have_http_status(:unprocessable_entity)
          
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to have_key('amount')
        end
        
        it 'returns error when currency is missing' do
          post "/api/v1/users/#{@client1_user.user_id}/transactions", 
               params: {
                 transaction: {
                   amount: 100.0
                 }
               },
               headers: @auth_headers
               
          expect(response).to have_http_status(:unprocessable_entity)
          
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to have_key('currency')
        end
        
        it 'returns not found when user_id does not exist' do
          post "/api/v1/users/uuid/transactions", 
               params: {
                 transaction: {
                   amount: 100.0,
                   currency: 'USD'
                 }
               },
               headers: @auth_headers
               
          expect(response).to have_http_status(:not_found)
          
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('User not found')
        end
      end
      
      it 'cannot create transactions for users from another client' do
        post "/api/v1/users/#{@client2_user.user_id}/transactions", 
             params: {
               transaction: {
                 amount: 100.0,
                 currency: 'USD'
               }
             },
             headers: @auth_headers
             
        expect(response).to have_http_status(:not_found)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('User not found')
      end
    end
  end
  
  describe 'when authenticated as client2' do
    before do
      with_tenant(client1) do
        @client1_user = create(:user, user_id: '32ebc067-c66c-4300-98ee-379b37046174')
      end
      
      with_tenant(client2) do
        @client2_user = create(:user, user_id: '8c347f65-bc8b-46ac-8fcc-c4a3febcfed5')
      end
      
      @auth_headers = { 'Authorization' => "Bearer #{client2.api_token}", 'Accept' => 'application/json' }
    end
    
    it 'can create transactions for its own users' do
      post "/api/v1/users/#{@client2_user.user_id}/transactions", 
           params: {
             transaction: {
               amount: 100.0,
               currency: 'USD'
             }
           },
           headers: @auth_headers
           
      expect(response).to have_http_status(:created)
      
      json_response = JSON.parse(response.body)
      expect(json_response['transaction']).to be_present
      expect(json_response['user_total_points']).to eq(10)
    end
    
    it 'cannot create transactions for users from client1' do
      post "/api/v1/users/#{@client1_user.user_id}/transactions", 
           params: {
             transaction: {
               amount: 100.0,
               currency: 'USD'
             }
           },
           headers: @auth_headers
           
      expect(response).to have_http_status(:not_found)
      
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('User not found')
    end
  end
end 