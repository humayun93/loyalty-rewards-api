module Api
  module V1
    class PingController < ApplicationController
      def index
        render json: {
          message: "Authenticated",
          client: current_client.name,
          client_id: current_client.id,
          tenant_id: ActsAsTenant.current_tenant&.id,
          tenant_name: ActsAsTenant.current_tenant&.name
        }
      end

      def debug
        # Get current user count for debugging
        user_count = User.count
        users = User.all.map { |u| { id: u.id, user_id: u.user_id, client_id: u.client_id } }

        render json: {
          message: "Debug info",
          client: current_client.name,
          client_id: current_client.id,
          tenant_id: ActsAsTenant.current_tenant&.id,
          user_count: user_count,
          users: users
        }
      end
    end
  end
end
