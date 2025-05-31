require 'bcrypt'

class User < ApplicationRecord
  has_secure_password
  has_many :white_games, class_name: 'Game', foreign_key: 'white_player_id'
  has_many :black_games, class_name: 'Game', foreign_key: 'black_player_id'
  has_many :passkeys, dependent: :destroy

  # Добавьте валидации, методы аутентификации и другие методы здесь
end
