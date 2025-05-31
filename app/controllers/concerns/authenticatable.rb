module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request
  end

  private

  def authenticate_request
    header = request.headers['Authorization']
    token = header.split(' ').last if header
    begin
      @decoded = decode_token(token)
      @current_user = User.find(@decoded[:user_id])
    rescue ActiveRecord::RecordNotFound => e
      render json: { errors: e.message }, status: :unauthorized
    rescue JWT::DecodeError => e
      render json: { errors: e.message }, status: :unauthorized
    end
  end

  def decode_token(token)
    JWT.decode(
      token,
      Rails.application.secret_key_base,
      true,
      algorithm: 'HS256'
    )[0]&.with_indifferent_access
  end

  def current_user
    @current_user
  end
end
