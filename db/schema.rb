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

ActiveRecord::Schema[8.1].define(version: 2026_10_02_141500) do
  create_table "homesteads", force: :cascade do |t|
    t.string "name", default: "South Acre", null: false
    t.integer "coins", default: 20, null: false
    t.string "weather", default: "clear", null: false
    t.datetime "weather_until"
    t.datetime "last_ticked_at"
    t.datetime "last_seen_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "plots", force: :cascade do |t|
    t.integer "homestead_id", null: false
    t.integer "position", null: false
    t.string "crop_key"
    t.datetime "planted_at"
    t.integer "bonus_seconds", default: 0, null: false
    t.boolean "spoiled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["homestead_id", "position"], name: "index_plots_on_homestead_id_and_position", unique: true
    t.index ["homestead_id"], name: "index_plots_on_homestead_id"
  end

  create_table "world_events", force: :cascade do |t|
    t.integer "homestead_id", null: false
    t.string "kind", null: false
    t.string "message", null: false
    t.datetime "happened_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["homestead_id", "happened_at"], name: "index_world_events_on_homestead_id_and_happened_at"
    t.index ["homestead_id"], name: "index_world_events_on_homestead_id"
  end

  add_foreign_key "plots", "homesteads"
  add_foreign_key "world_events", "homesteads"
end
