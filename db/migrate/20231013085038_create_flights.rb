class CreateFlights < ActiveRecord::Migration[7.1]
  def change
    create_table :flights do |t|
      t.string :flight_number
      t.string :lookup_status
      t.integer :number_of_legs
      t.string :first_leg_departure_airport_iata
      t.string :last_leg_arrival_airport_iata
      t.float :distance_in_kilometers
      t.string :departure_iata
      t.string :departure_city
      t.string :departure_country
      t.float :departure_latitude
      t.float :departure_longitude
      t.string :arrival_iata
      t.string :arrival_city
      t.string :arrival_country

      t.timestamps
    end
  end
end
