class ApiDocsController < ActionController::Base
  include Swagger::Blocks

  swagger_root do
    key :swagger, "2.0"
    info do
      key :version, "1.0.0"
      key :title, "Loyalty Rewards API"
      key :description, "API for managing user loyalty rewards"
      contact do
        key :name, "API Support"
        key :email, "support@example.com"
      end
    end
    key :host, ENV["API_HOST"] || "localhost:3000"
    key :basePath, "/api/v1"
    key :consumes, [ "application/json" ]
    key :produces, [ "application/json" ]

    # Add security definitions
    security_definition :api_key do
      key :type, :apiKey
      key :name, :Authorization
      key :in, :header
    end

    # Add response schemas that will be reused
    response :unauthorized do
      key :description, "Unauthorized"
    end

    response :not_found do
      key :description, "Resource not found"
    end

    response :unprocessable_entity do
      key :description, "Unprocessable entity"
    end
  end

  # Generates the Swagger JSON for the API documentation
  def index
    render json: Swagger::Blocks.build_root_json([ self.class ])
  end

  # Provides a redirect to the Swagger UI
  def swagger_ui
    redirect_to "/api-docs"
  end
end
