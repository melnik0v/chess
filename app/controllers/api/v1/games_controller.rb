# frozen_string_literal: true

class Api::V1::GamesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { error: e.message }, status: :not_found
  end

  rescue_from StandardError do |e|
    Rails.logger.error("[GamesController] StandardError: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
    render json: { error: 'Internal server error' }, status: :internal_server_error
  end

  # POST /api/v1/games
  # Создание новой игры
  # TODO: покрыть тестами (request specs)
  # TODO: добавить валидацию параметров через контракт/валидатор
  def create
    service = Games::CreateService.call(
      fingerprint: params[:fingerprint],
      chosen_color: params[:chosen_color]
    )

    if service.success?
      render json: { uuid: service.game.uuid }, status: :created
    else
      render json: { errors: service.errors }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/games/:uuid
  # Получение информации об игре
  # TODO: покрыть тестами (request specs)
  # TODO: добавить валидацию параметров через контракт/валидатор
  def show
    game = Game.find_by(uuid: params[:uuid])

    if game
      render json: game
    else
      render json: { error: "Game not found" }, status: :not_found
    end
  end

  # POST /api/v1/games/:uuid/join
  # Присоединение к игре
  # TODO: покрыть тестами (request specs)
  # TODO: добавить валидацию параметров через контракт/валидатор
  def join
    game = Game.find_by!(uuid: params[:uuid])
    service = Games::JoinService.call(
      game: game,
      fingerprint: params[:fingerprint]
    )

    if service.success?
      render json: game, status: :ok
    else
      render json: { status: :failed, error: service.errors }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/games/:uuid
  # Обновление состояния игры (ход, сдача и т.д.)
  # TODO: покрыть тестами (request specs)
  # TODO: добавить валидацию параметров через контракт/валидатор
  def update
    game = Game.find_by!(uuid: params[:uuid])
    service = Games::UpdateService.call(
      game: game,
      fingerprint: params[:fingerprint],
      game_params: game_params.to_h
    )

    if service.success?
      render json: game
    else
      render json: { error: service.errors }, status: :unprocessable_entity
    end
  end

  private

  def game_params
    params.require(:game).permit(:fen, :state)
  end
end
