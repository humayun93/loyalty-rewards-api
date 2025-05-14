require 'rails_helper'

RSpec.describe PointsService, type: :service do
  let(:client) { create(:client) }
  let(:user) { with_tenant(client) { create(:user, client: client, points: 0) } }
  
  describe '.calculate_points' do
    context 'with domestic transactions' do
      it 'calculates 10 points per $100' do
        with_tenant(client) do
          transaction = build(:transaction, user: user, amount: 100, foreign: false)
          expect(PointsService.calculate_points(transaction)).to eq(10)
          
          transaction = build(:transaction, user: user, amount: 50, foreign: false)
          expect(PointsService.calculate_points(transaction)).to eq(5)
          
          transaction = build(:transaction, user: user, amount: 250, foreign: false)
          expect(PointsService.calculate_points(transaction)).to eq(25)
        end
      end
      
      it 'keeps decimal precision for fractional amounts' do
        with_tenant(client) do
          transaction = build(:transaction, user: user, amount: 105.75, foreign: false)
          expect(PointsService.calculate_points(transaction)).to eq(10.575)
        end
      end
      
      it 'properly handles fractional amounts' do
        with_tenant(client) do
          # $150 should give 15 points (10 * 150/100)
          transaction = build(:transaction, user: user, amount: 150, foreign: false)
          expect(PointsService.calculate_points(transaction)).to eq(15)
          
          # $75 should give 7.5 points (10 * 75/100 = 7.5)
          transaction = build(:transaction, user: user, amount: 75, foreign: false)
          expect(PointsService.calculate_points(transaction)).to eq(7.5)
          
          # $25 should give 2.5 points (10 * 25/100 = 2.5)
          transaction = build(:transaction, user: user, amount: 25, foreign: false)
          expect(PointsService.calculate_points(transaction)).to eq(2.5)
          
          # $10 should give 1 point (10 * 10/100 = 1)
          transaction = build(:transaction, user: user, amount: 10, foreign: false)
          expect(PointsService.calculate_points(transaction)).to eq(1)
          
          # $5 should give 0.5 points (10 * 5/100 = 0.5)
          transaction = build(:transaction, user: user, amount: 5, foreign: false)
          expect(PointsService.calculate_points(transaction)).to eq(0.5)
        end
      end
    end
    
    context 'with foreign transactions' do
      it 'applies 2x multiplier' do
        with_tenant(client) do
          transaction = build(:transaction, user: user, amount: 100, foreign: true)
          expect(PointsService.calculate_points(transaction)).to eq(20)
          
          transaction = build(:transaction, user: user, amount: 50, foreign: true)
          expect(PointsService.calculate_points(transaction)).to eq(10)
        end
      end
      
      it 'properly handles fractional amounts with foreign multiplier' do
        with_tenant(client) do
          # $150 foreign should give 30 points (15 * 2)
          transaction = build(:transaction, user: user, amount: 150, foreign: true)
          expect(PointsService.calculate_points(transaction)).to eq(30)
          
          # $75 foreign should give 15 points (7.5 * 2)
          transaction = build(:transaction, user: user, amount: 75, foreign: true)
          expect(PointsService.calculate_points(transaction)).to eq(15)
          
          # $25 foreign should give 5 points (2.5 * 2)
          transaction = build(:transaction, user: user, amount: 25, foreign: true)
          expect(PointsService.calculate_points(transaction)).to eq(5)
          
          # $5 foreign should give 1 points (0.5 * 2 = 1)
          transaction = build(:transaction, user: user, amount: 5, foreign: true)
          expect(PointsService.calculate_points(transaction)).to eq(1)
        end
      end
    end
  end
  
  describe '.process_transaction' do
    it 'calculates points and updates user total' do
      with_tenant(client) do
        transaction = build(:transaction, user: user, amount: 200, foreign: false)
        expect(user.points).to eq(0)
        
        points = PointsService.process_transaction(transaction)
        
        expect(points).to eq(20)
        expect(transaction.points_earned).to eq(20)
        expect(user.reload.points).to eq(20)
      end
    end
    
    it 'uses pre-calculated points if already set' do
      with_tenant(client) do
        transaction = build(:transaction, user: user, amount: 200, foreign: false, points_earned: 15)
        
        points = PointsService.process_transaction(transaction)
        
        expect(points).to eq(15)
        expect(user.reload.points).to eq(15)
      end
    end
    
    it 'accumulates points over multiple transactions' do
      with_tenant(client) do
        # First transaction
        transaction1 = build(:transaction, user: user, amount: 100, foreign: false)
        PointsService.process_transaction(transaction1)
        expect(user.reload.points).to eq(10)
        
        # Second transaction
        transaction2 = build(:transaction, user: user, amount: 150, foreign: true)
        PointsService.process_transaction(transaction2)
        
        # 10 (from first) + 30 (from second, with 2x multiplier)
        expect(user.reload.points).to eq(40)
      end
    end
    
    it 'handles fractional points correctly' do
      with_tenant(client) do
        # First transaction with fractional points
        transaction1 = build(:transaction, user: user, amount: 75, foreign: false)
        PointsService.process_transaction(transaction1)
        expect(user.reload.points).to eq(7.5) # 75/100*10 = 7.5
        
        # Second transaction with fractional points and foreign multiplier
        transaction2 = build(:transaction, user: user, amount: 25, foreign: true)
        PointsService.process_transaction(transaction2)
        
        # 7.5 (from first) + 5 (from second, 2.5 * 2 = 5)
        expect(user.reload.points).to eq(12.5)
      end
    end
  end
end 