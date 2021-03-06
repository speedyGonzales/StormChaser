# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140407222717) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "avg_cyclone_data", force: true do |t|
    t.string   "year"
    t.float    "fatalities"
    t.float    "property_loss"
    t.float    "crop_loss"
    t.float    "injuries"
    t.float    "distance"
    t.float    "f_scale"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cyclone_dates", force: true do |t|
    t.integer  "day"
    t.integer  "month"
    t.integer  "year"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cyclones", force: true do |t|
    t.integer  "cyclone_date_id"
    t.integer  "path_id"
    t.integer  "f_scale"
    t.integer  "hour"
    t.integer  "minute"
    t.integer  "time_zone"
    t.string   "state"
    t.integer  "injuries"
    t.integer  "fatalities"
    t.float    "property_loss"
    t.float    "crop_loss"
    t.float    "start_lat"
    t.float    "start_long"
    t.float    "stop_lat"
    t.float    "stop_long"
    t.float    "distance"
    t.float    "width"
    t.integer  "county_code_one"
    t.integer  "county_code_two"
    t.integer  "county_code_three"
    t.integer  "county_code_four"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cyclones", ["cyclone_date_id"], name: "index_cyclones_on_cyclone_date_id", using: :btree
  add_index "cyclones", ["path_id"], name: "index_cyclones_on_path_id", using: :btree

  create_table "historical_weathers", force: true do |t|
    t.float    "wind_speed"
    t.float    "wind_bearing"
    t.float    "temperature"
    t.float    "pressure"
    t.integer  "hour"
    t.integer  "cyclone_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "historical_weathers", ["cyclone_id"], name: "index_historical_weathers_on_cyclone_id", using: :btree

  create_table "paths", force: true do |t|
    t.integer  "states_crossed"
    t.boolean  "complete_track"
    t.integer  "segment_num"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
