# frozen_string_literal: true

module Games
  class CreateService < ApplicationService
    option :fingerprint, type: Types::String
    option :chosen_color, type: Types::String
    attr_reader :game

    def process
      @game = Game.new(state: 'waiting_for_player')

      case chosen_color
      when 'white'
        @game.white_player_fingerprint = fingerprint
      when 'black'
        @game.black_player_fingerprint = fingerprint
      else
        halt('Invalid chosen_color')
      end

      halt(*@game.errors.full_messages) unless @game.save
    end
  end
end
