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

        if @transaction.save
          # Process the transaction (calculate and add points to user)
          points_earned = PointsService.process_transaction(@transaction)

          render json: {
            transaction: @transaction,
            points_earned: points_earned.to_f,
            user_total_points: @user.points.to_f
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
