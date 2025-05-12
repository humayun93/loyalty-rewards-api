require 'rails_helper'

RSpec.describe Api::V1::PingController, type: :request do
  let(:client) { create(:client) }
  
  describe 'GET /api/v1/ping' do
    it 'returns the client name and authentication message' do
      get '/api/v1/ping', headers: { 'Authorization' => "Bearer #{client.api_token}" }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq('Authenticated')
      expect(json_response['client']).to eq(client.name)
    end
    
    it 'works with different clients' do
      client1 = create(:client, name: 'Client One')
      client2 = create(:client, name: 'Client Two')
      
      get '/api/v1/ping', headers: { 'Authorization' => "Bearer #{client1.api_token}" }
      json_response = JSON.parse(response.body)
      expect(json_response['client']).to eq('Client One')
      
      get '/api/v1/ping', headers: { 'Authorization' => "Bearer #{client2.api_token}" }
      json_response = JSON.parse(response.body)
      expect(json_response['client']).to eq('Client Two')
    end
  end
end 