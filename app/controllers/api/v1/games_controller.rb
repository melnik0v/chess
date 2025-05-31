class Api::V1::GamesController < ApplicationController
  include Authenticatable # Включаем модуль аутентификации
  before_action :authenticate_request # Требовать аутентификации для всех действий

  def create
    # Предполагаем, что параметр :chosen_color содержит выбранный цвет ('white' или 'black')
    chosen_color = params[:chosen_color]
    # current_user = User.first # Заменяем на реальный current_user

    game = Game.new(state: 'waiting_for_player')

    if chosen_color == 'white'
      game.white_player = current_user
    elsif chosen_color == 'black'
      game.black_player = current_user
    end

    if game.save
      render json: { game_id: game.id, invitation_token: game.invitation_token }, status: :created
    else
      render json: { errors: game.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    game = Game.find_by(id: params[:id])

    if game
      # Возвращаем game как есть, оно содержит player_ids и fen
      render json: game
    else
      render json: { error: "Game not found" }, status: :not_found
    end
  end

  def join
    # Логика присоединения к игре
    game = Game.find_by(invitation_token: params[:invitation_token])

    if game && game.state == 'waiting_for_player'
      # current_user = User.first # Заменяем на реальный current_user

      # Проверяем, не является ли текущий пользователь уже одним из игроков
      if game.white_player == current_user || game.black_player == current_user
        render json: { error: "You are already a player in this game." }, status: :unprocessable_entity
        return # Прерываем выполнение метода
      end

      if game.white_player.nil?
        game.white_player = current_user
      elsif game.black_player.nil?
        game.black_player = current_user
      else
        # Оба слота заняты, хотя статус 'waiting_for_player' - это не должно происходить при правильной логике
        render json: { error: "Game is already full." }, status: :unprocessable_entity
        return # Прерываем выполнение метода
      end

      game.state = 'in_progress'

      # Устанавливаем начальный FEN и ход белых при переходе игры в статус in_progress
      game.fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'

      if game.save
        render json: game
      else
        render json: { errors: game.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "Game not found or not waiting for player" }, status: :not_found
    end
  end

  def update
    game = Game.find_by(id: params[:id])

    if game
      # Проверка: является ли текущий пользователь игроком в этой игре?
      unless game.white_player == current_user || game.black_player == current_user
        render json: { error: "You are not a player in this game." }, status: :forbidden
        return
      end

      # Проверка очередности хода
      # chess.js использует 'w' для белых и 'b' для черных для определения хода
      # Нам нужно сопоставить это с цветом текущего игрока в базе данных
      current_player_color_code = if game.white_player == current_user
                               'w'
                             elsif game.black_player == current_user
                               'b'
                             end

      if game.turn != current_player_color_code && game_params.keys != ['state']
        render json: { error: "It is not your turn." }, status: :unprocessable_entity
        return
      end

      # Применяем изменения (FEN или state при сдаче)
      if game.update(game_params)
        render json: game
      else
        render json: { errors: game.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "Game not found" }, status: :not_found
    end
  end

  private

  def game_params
    params.require(:game).permit(:fen, :state)
  end
end
