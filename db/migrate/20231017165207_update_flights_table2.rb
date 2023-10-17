class UpdateFlightsTable2 < ActiveRecord::Migration[7.1]
  def change
    remove_column :flights, :arrival_longitude, :float
    remove_column :flights, :arrival_latitude, :float
  end
end
