class Game < ApplicationRecord
  belongs_to :white_player, class_name: 'User', optional: true
  belongs_to :black_player, class_name: 'User', optional: true

  before_create :generate_invitation_token

  # Добавьте валидации и другие методы здесь

  # Метод для определения очередности хода из FEN
  def turn
    fen_parts = self.fen.split(' ')
    if fen_parts.length > 1
      fen_parts[1] # Возвращает 'w' или 'b'
    else
      'w' # По умолчанию ход белых, если FEN некорректен или отсутствует
    end
  end

  private

  def generate_invitation_token
    self.invitation_token = SecureRandom.hex(10)
  end
end
