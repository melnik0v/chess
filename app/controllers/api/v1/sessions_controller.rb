class Api::V1::SessionsController < ApplicationController
  skip_before_action :authenticate_request, only: [:create]

  def create
    user = User.find_by(email: params[:email])

    if user && user.authenticate(params[:password])
      token = encode_token({ user_id: user.id })
      render json: { user: { id: user.id, email: user.email }, jwt: token }, status: :ok
    else
      render json: { error: 'Неверный email или пароль' }, status: :unauthorized
    end
  end

  private

  def encode_token(payload)
    JWT.encode(payload, Rails.application.secret_key_base)
  end
end
