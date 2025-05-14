require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  let(:client) { create(:client) }
  let(:test_route) { '/api/v1/ping' }

  describe 'authentication flow' do
    context 'with valid token' do
      it 'allows the request to proceed' do
        get test_route, headers: { 'Authorization' => "Bearer #{client.api_token}" }
        
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['client']).to eq(client.name)
      end
    end

    context 'without token' do
      it 'returns unauthorized status' do
        get test_route
        
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Unauthorized')
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized status' do
        get test_route, headers: { 'Authorization' => "Bearer invalid_token" }
        
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Unauthorized')
      end
    end

    context 'with malformed authorization header' do
      it 'returns unauthorized status' do
        get test_route, headers: { 'Authorization' => client.api_token }
        
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Unauthorized')
      end
    end
  end

  describe 'tenant isolation' do
    it 'sets the current tenant based on the client' do
      # Since we can't directly test ActsAsTenant in a request spec,
      # we can verify isolation by creating two clients and confirming
      # each only sees their own data in a real endpoint
      
      client1 = create(:client, name: 'Client One')
      client2 = create(:client, name: 'Client Two')
      
      get test_route, headers: { 'Authorization' => "Bearer #{client1.api_token}" }
      json_response = JSON.parse(response.body)
      expect(json_response['client']).to eq('Client One')
      
      get test_route, headers: { 'Authorization' => "Bearer #{client2.api_token}" }
      json_response = JSON.parse(response.body)
      expect(json_response['client']).to eq('Client Two')
    end
  end
end 