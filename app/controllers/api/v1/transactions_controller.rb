module Api
  module V1
    class TransactionsController < ApplicationController
      before_action :set_user

      # POST /api/v1/users/:user_id/transactions
      def create
        @transaction = @user.transactions.new(
          amount: transaction_params[:amount],
          currency: transaction_params[:currency],
          foreign: transaction_params[:foreign] || false,
          client: current_client
        )

        if @transaction.valid?
          # Wrap the entire processing in a transaction for atomicity
          points_earned = nil
          rewards_issued = []
          
          ActiveRecord::Base.transaction do
            # Use user.with_lock to handle race conditions at the user level
            @user.with_lock do
              @transaction.save
              # Process the transaction (calculate and add points to user)
              points_earned = PointsService.process_transaction(@transaction)

              # Check for rewards
              reward_engine = RewardEngine.new(@user)
              rewards_issued = reward_engine.process_transaction(@transaction)
            end
          end

          render json: {
            transaction: @transaction,
            points_earned: points_earned.to_f,
            user_total_points: @user.points.to_f,
            rewards_issued: rewards_issued.map(&:as_json)
          }, status: :created
        else
          render json: { errors: @transaction.errors }, status: :unprocessable_entity
        end
      end

      private

      def set_user
        @user = User.find_by!(user_id: params[:user_user_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
      end

      def transaction_params
        params.require(:transaction).permit(:amount, :currency, :foreign)
      end
    end
  end
end
