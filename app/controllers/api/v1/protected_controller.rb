class Api::V1::ProtectedController < ApplicationController
  include Authenticatable

  def index
    render json: { message: 'Доступ разрешен. Пользователь: ' + current_user.email }, status: :ok
  end
end
