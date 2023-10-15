desc "Import data from CSV file"
task csv: :environment do
  file_path = "/Users/mihailkulik/Documents/Programming/FlightData/flight-data/lib/tasks/flight_numbers.csv"

  updated_rows = []
  headers = []

  CSV.foreach(file_path, headers: true) do |row|
    flight_number = row["Flight number used for lookup"]
    flight_data = FlightInfoController.new.retrieve_flight_info_from_api(flight_number)

    if flight_data
      if flight_data[:status] != "OK"
        row["Lookup status"] = "not found"
        updated_rows << row
      else
        flight_data[:route].each do |flight|
          new_row = row.dup
          new_row["Lookup status"] = flight[:status]
          new_row["Number of legs"] = flight_data[:route].length
          new_row["First leg departure airport IATA"] = flight[:route][:departure][:iata]
          new_row["Last leg arrival airport IATA"] = flight[:route][:arrival][:iata]
          new_row["Distance in kilometers"] = flight[:distance]
          updated_rows << new_row
        end
      end
    else
      updated_rows << row
    end

    headers = row.headers
  end

  CSV.open(file_path, "w", write_headers: true, headers: headers) do |csv|
    updated_rows.each { |row| csv << row }
  end

  puts "CSV file updated successfully."
end
