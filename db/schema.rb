# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_05_30_153139) do
  create_table "games", force: :cascade do |t|
    t.string "fen", default: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    t.text "moves"
    t.string "state"
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer "white_time_left"
    t.integer "black_time_left"
    t.string "time_control"
    t.string "white_player_fingerprint"
    t.string "black_player_fingerprint"
    t.string "uuid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_games_on_uuid", unique: true
  end
end
