class UpdateFlightsTable < ActiveRecord::Migration[7.1]
  def change
    remove_column :flights, :departure_iata, :string
    remove_column :flights, :departure_city, :string
    remove_column :flights, :departure_country, :string
    remove_column :flights, :departure_latitude, :float
    remove_column :flights, :departure_longitude, :float
    remove_column :flights, :arrival_iata, :string
    remove_column :flights, :arrival_city, :string
    remove_column :flights, :arrival_country, :string

    add_reference :flights, :departure_airport, null: false, foreign_key: { to_table: :airports }
    add_reference :flights, :arrival_airport, null: false, foreign_key: { to_table: :airports }
  end
end
