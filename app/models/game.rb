# frozen_string_literal: true

class Game < ApplicationRecord
  DEFAULT_FEN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'

  before_save do
    self.uuid ||= SecureRandom.uuid
  end

  # Возвращает цвет текущего хода ('w' или 'b') на основе FEN
  def turn
    fen_parts = self.fen.split(' ')
    if fen_parts.length > 1
      fen_parts[1] # Возвращает 'w' или 'b'
    else
      'w' # По умолчанию ход белых, если FEN некорректен или отсутствует
    end
  end

  # Добавляет turn в сериализацию
  def as_json(options = {})
    super(options).merge('turn' => turn)
  end
end
