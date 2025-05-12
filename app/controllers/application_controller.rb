class ApplicationController < ActionController::API
  before_action :authenticate_client!
  
  private
  
  def authenticate_client!
    unless current_client
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
  
  def current_client
    @current_client ||= authenticate_with_token
  end
  
  def authenticate_with_token
    token = extract_token_from_header
    Client.find_by(api_token: token) if token.present?
  end
  
  def extract_token_from_header
    auth_header = request.headers['Authorization']
    return nil unless auth_header.present?
    
    # Format: "Bearer token123"
    auth_header.split(' ').last if auth_header.start_with?('Bearer ')
  end
end
