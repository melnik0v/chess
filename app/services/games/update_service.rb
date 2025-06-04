# frozen_string_literal: true

module Games
  class UpdateService < ApplicationService
    option :game, type: Types.Instance(Game)
    option :fingerprint, type: Types::String
    option :game_params, type: Types::Hash
    attr_reader :status

    def process
      check_player!
      check_turn!
      update_game!
    end

    private

    def check_player!
      unless [game.white_player_fingerprint, game.black_player_fingerprint].include?(fingerprint)
        halt('You are not a player in this game.')
      end
    end

    def check_turn!
      current_player_color_code = player_color_code
      if game.turn != current_player_color_code && game_params.keys != ['state']
        halt('It is not your turn.')
      end
    end

    def update_game!
      halt(*game.errors.full_messages) unless game.update(game_params)
    end

    def player_color_code
      if game.white_player_fingerprint == fingerprint
        'w'
      elsif game.black_player_fingerprint == fingerprint
        'b'
      end
    end
  end
end
