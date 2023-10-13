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

ActiveRecord::Schema[7.1].define(version: 2023_10_13_090944) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "flights", force: :cascade do |t|
    t.string "flight_number"
    t.string "lookup_status"
    t.integer "number_of_legs"
    t.string "first_leg_departure_airport_iata"
    t.string "last_leg_arrival_airport_iata"
    t.float "distance_in_kilometers"
    t.string "departure_iata"
    t.string "departure_city"
    t.string "departure_country"
    t.float "departure_latitude"
    t.float "departure_longitude"
    t.string "arrival_iata"
    t.string "arrival_city"
    t.string "arrival_country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "arrival_latitude"
    t.float "arrival_longitude"
  end

end
