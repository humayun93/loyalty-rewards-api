require 'rails_helper'

RSpec.describe Transaction, type: :model do
  let(:client) { create(:client) }
  let(:user) { with_tenant(client) { create(:user, client: client) } }
  
  describe "associations" do
    it "belongs to a user" do
      with_tenant(client) do
        transaction = build(:transaction, user: user, client: client)
        expect(transaction.user).to eq(user)
      end
    end
    
    it "belongs to a client" do
      with_tenant(client) do
        transaction = build(:transaction, user: user, client: client)
        expect(transaction.client).to eq(client)
      end
    end
  end
  
  describe "validations" do
    it "validates presence and numericality of amount" do
      with_tenant(client) do
        transaction = build(:transaction, user: user, client: client, amount: nil)
        expect(transaction).not_to be_valid
        expect(transaction.errors[:amount]).to include("can't be blank")
        
        transaction = build(:transaction, user: user, client: client, amount: -10)
        expect(transaction).not_to be_valid
        expect(transaction.errors[:amount]).to include("must be greater than 0")
      end
    end
    
    it "validates presence of currency" do
      with_tenant(client) do
        transaction = build(:transaction, user: user, client: client, currency: nil)
        expect(transaction).not_to be_valid
        expect(transaction.errors[:currency]).to include("can't be blank")
      end
    end
    
    it "validates inclusion of foreign" do
      with_tenant(client) do
        transaction = build(:transaction, user: user, client: client, foreign: nil)
        expect(transaction).not_to be_valid
        expect(transaction.errors[:foreign]).to include("is not included in the list")
      end
    end
    
    it "validates numericality of points_earned" do
      with_tenant(client) do
        transaction = build(:transaction, user: user, client: client, points_earned: -5)
        expect(transaction).not_to be_valid
        expect(transaction.errors[:points_earned]).to include("must be greater than or equal to 0")
      end
    end
  end
  
  describe "callbacks" do
    it "calculates points before saving" do
      with_tenant(client) do
        transaction = build(:transaction, user: user, client: client, amount: 100, foreign: false, points_earned: 0)
        expect(PointsService).to receive(:calculate_points).with(transaction).and_return(10)
        transaction.save
        expect(transaction.points_earned).to eq(10)
      end
    end
    
    it "doesn't recalculate points if already set" do
      with_tenant(client) do
        transaction = build(:transaction, user: user, client: client, amount: 100, foreign: false, points_earned: 15)
        expect(PointsService).not_to receive(:calculate_points)
        transaction.save
        expect(transaction.points_earned).to eq(15)
      end
    end
  end
  
  describe "tenant scoping" do
    it "is scoped to the client through acts_as_tenant" do
      with_tenant(client) do
        transaction = create(:transaction, user: user, client: client)
        expect(transaction.client).to eq(client)
      end
    end
  end
end
