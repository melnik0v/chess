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

ActiveRecord::Schema[8.0].define(version: 2025_06_02_182322) do
  create_table "games", force: :cascade do |t|
    t.integer "white_player_id"
    t.integer "black_player_id"
    t.string "fen"
    t.text "moves"
    t.string "status"
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer "white_time_left"
    t.integer "black_time_left"
    t.string "time_control"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state"
    t.string "invitation_token"
  end

  create_table "passkeys", force: :cascade do |t|
    t.integer "user_id", null: false
    t.binary "external_id"
    t.binary "public_key"
    t.string "nickname"
    t.integer "sign_count"
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_passkeys_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
  end

  add_foreign_key "passkeys", "users"
end
