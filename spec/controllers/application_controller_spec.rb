require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render json: { client: current_client.name }
    end
  end

  before do
    routes.draw { get 'index' => 'anonymous#index' }
  end

  let(:client) { create(:client) }

  describe '#authenticate_client!' do
    context 'with valid token' do
      it 'allows the request to proceed' do
        request.headers['Authorization'] = "Bearer #{client.api_token}"
        get :index
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['client']).to eq(client.name)
      end
    end

    context 'without token' do
      it 'returns unauthorized status' do
        get :index
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Unauthorized')
      end
    end
  end

  describe '#current_client' do
    it 'returns the authenticated client' do
      request.headers['Authorization'] = "Bearer #{client.api_token}"
      expect(controller.send(:current_client)).to eq(client)
    end

    it 'returns nil when no valid token is provided' do
      expect(controller.send(:current_client)).to be_nil
    end

    it 'memoizes the result' do
      request.headers['Authorization'] = "Bearer #{client.api_token}"
      expect(Client).to receive(:find_by).once.and_return(client)
      
      # Call twice to verify memoization
      controller.send(:current_client)
      controller.send(:current_client)
    end
  end

  describe '#authenticate_with_token' do
    it 'finds client by token' do
      request.headers['Authorization'] = "Bearer #{client.api_token}"
      expect(controller.send(:authenticate_with_token)).to eq(client)
    end

    it 'returns nil for invalid token' do
      request.headers['Authorization'] = "Bearer invalid_token"
      expect(controller.send(:authenticate_with_token)).to be_nil
    end
  end

  describe '#extract_token_from_header' do
    it 'extracts token from Bearer header' do
      request.headers['Authorization'] = "Bearer #{client.api_token}"
      expect(controller.send(:extract_token_from_header)).to eq(client.api_token)
    end

    it 'returns nil for missing header' do
      expect(controller.send(:extract_token_from_header)).to be_nil
    end

    it 'returns nil for malformed header' do
      request.headers['Authorization'] = client.api_token
      expect(controller.send(:extract_token_from_header)).to be_nil
    end
  end
end 