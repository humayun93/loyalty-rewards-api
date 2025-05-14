class ApiDocsController < ActionController::Base
  include Swagger::Blocks

  openapi_endpoint do
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
    key :host, "api.example.com"
    key :basePath, "/api/v1"
    key :consumes, [ "application/json" ]
    key :produces, [ "application/json" ]
  end

  def index
    render json: Swagger::Blocks.build_root_json([ self.class ])
  end
end
