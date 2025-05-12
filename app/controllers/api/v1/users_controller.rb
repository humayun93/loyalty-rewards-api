module Api
  module V1
    class UsersController < ApplicationController
      before_action :set_user, only: [ :show, :update, :destroy ]

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
    end
  end
end
