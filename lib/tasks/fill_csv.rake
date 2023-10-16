desc "Import data from CSV file"
task csv: :environment do
  file_path = "/Users/mihailkulik/Documents/Programming/FlightData/flight-data/lib/tasks/flight_numbers.csv"

  updated_rows = []
  headers = []

  CSV.foreach(file_path, headers: true) do |row|
    flight_number = row["Example flight number"].split(" ").first
    flight = Flight.new(flight_number: flight_number)
    if flight.valid?
      flight_info_service = FlightInfoService.new(ENV["FLIGHT_AWARE_API_KEY"])
      flight_data = flight_info_service.retrieve_flight_info_from_api(flight_number)
      puts flight_data
      if flight_data
        if flight_data[:status] != "OK"
          row["Lookup status"] = "FAIL, no such flights"
          row["Distance in kilometers"] = 0
          row["Flight number used for lookup"] = flight_number
          updated_rows << row
        else
          floght_data = flight_data[:route].first
          puts floght_data
          new_row = row.dup
          new_row["Flight number used for lookup"] = flight_number
          new_row["Lookup status"] = floght_data[:status]
          new_row["Number of legs"] = floght_data[:route].length
          new_row["First leg departure airport IATA"] = floght_data[:route][:departure][:iata]
          new_row["Last leg arrival airport IATA"] = floght_data[:route][:arrival][:iata]
          new_row["Distance in kilometers"] = floght_data[:distance]
          updated_rows << new_row
        end
      else
        updated_rows << row
      end
    else
      row["Lookup status"] = "invalid flight number"
      row["Flight number used for lookup"] = flight_number
      row["Distance in kilometers"] = 0
      updated_rows << row
    end

    headers = row.headers
  end

  CSV.open(file_path, "w", write_headers: true, headers: headers) do |csv|
    updated_rows.each { |row| csv << row }
  end

  puts "CSV file updated successfully."
end
