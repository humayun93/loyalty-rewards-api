module Api
  module V1
    class PingController < ApplicationController
      def index
        render json: { message: "Authenticated", client: current_client.name }
      end
    end
  end
end 