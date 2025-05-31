class Api::V1::UsersController < ApplicationController
  # include Authenticatable # Удаляем, так как теперь он в ApplicationController

  skip_before_action :authenticate_request, only: [:create]

  def create
    user = User.new(user_params)

    if user.save
      token = encode_token({ user_id: user.id })
      render json: { user: { id: user.id, email: user.email }, jwt: token }, status: :ok
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    render json: { user: { id: current_user.id, email: current_user.email } }, status: :ok
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  def encode_token(payload)
    JWT.encode(payload, Rails.application.secret_key_base)
  end
end
