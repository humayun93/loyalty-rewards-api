module Api
  module V1
    class UsersController < ApplicationController
      before_action :set_user, only: [ :show, :update, :destroy, :points, :rewards ]

      # GET /api/v1/users
      def index
        # acts_as_tenant automatically scopes this to current_client
        @users = User.all

        render json: @users
      end

      # GET /api/v1/users/:user_id
      def show
        render json: @user
      end

      # POST /api/v1/users
      def create
        # Validate dates before creating user
        return if invalid_dates?(params[:user])

        @user = User.new(user_params)

        # No need to set client_id, acts_as_tenant does this automatically
        if @user.save
          render json: @user, status: :created
        else
          render json: { errors: @user.errors }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/users/:user_id
      def update
        # Validate dates before updating user
        return if invalid_dates?(params[:user])

        if @user.update(user_params)
          render json: @user
        else
          render json: { errors: @user.errors }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/users/:user_id
      def destroy
        @user.destroy
        head :no_content
      end

      # GET /api/v1/users/:user_id/points
      def points
        # Calculate monthly, yearly, and lifetime points
        monthly_points = @user.transactions
                              .where(created_at: Date.today.beginning_of_month..Date.today.end_of_month)
                              .sum(:points_earned)

        yearly_points = @user.transactions
                             .where(created_at: Date.today.beginning_of_year..Date.today.end_of_year)
                             .sum(:points_earned)

        render json: {
          user_id: @user.user_id,
          current_points: @user.points,
          monthly_points: monthly_points,
          yearly_points: yearly_points
        }
      end

      # GET /api/v1/users/:user_id/rewards
      def rewards
        # Default to active rewards, allow filtering by status
        status = params[:status] || "active"

        if status == "all"
          user_rewards = @user.rewards
        else
          user_rewards = @user.rewards.where(status: status)
        end

        render json: {
          user_id: @user.user_id,
          rewards: user_rewards.order(issued_at: :desc).map do |reward|
            {
              id: reward.id,
              reward_type: reward.reward_type,
              description: reward.description,
              status: reward.status,
              issued_at: reward.issued_at,
              expires_at: reward.expires_at
            }
          end
        }
      end

      private

      def set_user
        # acts_as_tenant automatically scopes this to current_client
        @user = User.find_by!(user_id: params[:user_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
      end

      def user_params
        params.require(:user).permit(:user_id, :birth_date, :joining_date)
      end

      def invalid_dates?(user_params)
        if user_params[:birth_date].present?
          begin
            Date.parse(user_params[:birth_date])
          rescue ArgumentError
            render json: { error: "Birth date must be a valid date" }, status: :unprocessable_entity
            return true
          end
        end

        if user_params[:joining_date].present?
          begin
            Date.parse(user_params[:joining_date])
          rescue ArgumentError
            render json: { error: "Joining date must be a valid date" }, status: :unprocessable_entity
            return true
          end
        end

        false
      end
    end
  end
end
