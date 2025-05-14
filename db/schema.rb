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

ActiveRecord::Schema[8.0].define(version: 2025_05_14_015331) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "clients", force: :cascade do |t|
    t.string "name"
    t.string "subdomain"
    t.string "api_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_clients_on_api_token", unique: true
  end

  create_table "rewards", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "client_id", null: false
    t.string "reward_type", null: false
    t.datetime "issued_at", null: false
    t.datetime "expires_at"
    t.string "status", default: "active", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_rewards_on_client_id"
    t.index ["user_id", "reward_type", "status"], name: "index_rewards_on_user_id_and_reward_type_and_status"
    t.index ["user_id"], name: "index_rewards_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "currency", default: "USD", null: false
    t.boolean "foreign", default: false, null: false
    t.decimal "points_earned", precision: 10, scale: 2, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "client_id", null: false
    t.index ["client_id"], name: "index_transactions_on_client_id"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "user_id", null: false
    t.datetime "joining_date"
    t.datetime "birth_date"
    t.decimal "points", precision: 10, scale: 2, default: 0, null: false
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "user_id"], name: "index_users_on_client_id_and_user_id", unique: true
    t.index ["client_id"], name: "index_users_on_client_id"
  end

  add_foreign_key "rewards", "clients"
  add_foreign_key "rewards", "users"
  add_foreign_key "transactions", "clients"
  add_foreign_key "transactions", "users"
  add_foreign_key "users", "clients"
end
