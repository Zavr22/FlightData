class AddLatitudeAndLongitudeToFlights < ActiveRecord::Migration[7.1]
  def change
    add_column :flights, :arrival_latitude, :float
    add_column :flights, :arrival_longitude, :float
  end
end
