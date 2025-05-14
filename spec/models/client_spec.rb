require 'rails_helper'

RSpec.describe Client, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:subdomain) }
    it { should validate_uniqueness_of(:subdomain) }
    
    it { should allow_value('Client123').for(:subdomain) }
    it { should allow_value('my_client').for(:subdomain) }
    it { should allow_value('my-client').for(:subdomain) }
    it { should_not allow_value('my client').for(:subdomain) }
  end
  
  describe 'token generation' do
    it 'generates an api_token on creation' do
      client = create(:client)      
      expect(client.api_token).not_to be_nil
      expect(client.api_token.length).to be > 20
    end
    
    it 'regenerates api_token when requested' do
      client = create(:client)
      original_token = client.api_token
      
      client.regenerate_api_token
      expect(client.api_token).not_to eq(original_token)
    end
  end

  # We've removed tenant schema creation with Apartment, so these tests are no longer relevant
end 