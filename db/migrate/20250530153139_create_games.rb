class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.integer :white_player_id
      t.integer :black_player_id
      t.string :fen
      t.text :moves
      t.string :turn
      t.string :status
      t.datetime :start_time
      t.datetime :end_time
      t.integer :white_time_left
      t.integer :black_time_left
      t.string :time_control

      t.timestamps
    end
  end
end
