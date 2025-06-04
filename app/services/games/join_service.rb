# frozen_string_literal: true

module Games
  class JoinService < ApplicationService
    option :game, type: Types.Instance(Game)
    option :fingerprint, type: Types::String

    def process
      if game.state == 'waiting_for_player'
        return if already_joined?
        join_player!
        start_game!
      elsif already_joined?
        # ничего не делаем, просто возвращаем game
      else
        halt('Game is not available for joining.')
      end
    end

    private

    def already_joined?
      [game.white_player_fingerprint, game.black_player_fingerprint].include?(fingerprint)
    end

    def join_player!
      if game.white_player_fingerprint.nil?
        game.white_player_fingerprint = fingerprint
      elsif game.black_player_fingerprint.nil?
        game.black_player_fingerprint = fingerprint
      else
        halt('Game is already full.')
      end
    end

    def start_game!
      game.state = 'in_progress'
      halt(*game.errors.full_messages) unless game.save
    end
  end
end
