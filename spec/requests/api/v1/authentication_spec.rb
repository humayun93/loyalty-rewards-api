require 'rails_helper'

RSpec.describe 'API Authentication', type: :request do
  let(:client) { create(:client) }
  
  describe 'GET /api/v1/ping' do
    context 'with valid authentication' do
      it 'returns a successful response with client info' do
        get '/api/v1/ping', headers: { 'Authorization' => "Bearer #{client.api_token}" }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Authenticated')
        expect(json_response['client']).to eq(client.name)
      end
    end
    
    context 'without authentication' do
      it 'returns unauthorized status' do
        get '/api/v1/ping'
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
    
    context 'with invalid token' do
      it 'returns unauthorized status' do
        get '/api/v1/ping', headers: { 'Authorization' => 'Bearer invalid_token' }
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
    
    context 'with malformed authorization header' do
      it 'returns unauthorized status for header without Bearer prefix' do
        get '/api/v1/ping', headers: { 'Authorization' => client.api_token }
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end
end 