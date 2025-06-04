class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.string :fen, default: Game::DEFAULT_FEN
      t.text :moves
      t.string :state
      t.datetime :start_time
      t.datetime :end_time
      t.integer :white_time_left
      t.integer :black_time_left
      t.string :time_control

      t.string :white_player_fingerprint
      t.string :black_player_fingerprint
      t.string :uuid

      t.index :uuid, unique: true

      t.timestamps
    end
  end
end
