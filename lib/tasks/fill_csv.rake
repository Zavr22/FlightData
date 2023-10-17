desc "Import data from CSV file"
task csv: :environment do
  file_path = "/Users/mihailkulik/Documents/Programming/FlightData/flight-data/lib/tasks/flight_numbers.csv"

  updated_rows = []
  headers = []

  CSV.foreach(file_path, headers: true) do |row|
    original_flight_number = row["Example flight number"].split(" ").first
    flight = Flight.new(flight_number: original_flight_number)

    unless flight.valid?
      row["Lookup status"] = "FAIL"
      row["Flight number used for lookup"] = flight.flight_number
      updated_rows << row
    end
    success = false
    max_retries = 3
    retries = 0
    current_flight_number = flight.flight_number
    flight = Flight.find_by(flight_number: current_flight_number)

    if flight
      new_row = row.dup
      new_row["Flight number used for lookup"] = original_flight_number
      new_row["Lookup status"] = "OK"
      new_row["Number of legs"] = flight.number_of_legs
      new_row["First leg departure airport IATA"] = flight.first_leg_departure_airport_iata
      new_row["Last leg arrival airport IATA"] = flight.last_leg_arrival_airport_iata
      new_row["Distance in kilometers"] = flight.distance_in_kilometers
      updated_rows << new_row
    else

      while !success && retries < max_retries
        puts current_flight_number
        flight_info_service = FlightInfoService.new(ENV["FLIGHT_AWARE_API_KEY"])
        flight_data = flight_info_service.retrieve_flight_info_from_api(current_flight_number)
        puts flight_data

        if flight_data
          if flight_data[:status] == "FAIL" && retries < max_retries
            retries += 1
          else
            if flight_data[:status] != "OK"
              row["Lookup status"] = "FAIL"
              row["Flight number used for lookup"] = current_flight_number
              updated_rows << row
            else
              flight_data = flight_data[:route].first
              puts flight_data
              new_row = row.dup
              new_row["Flight number used for lookup"] = current_flight_number
              new_row["Lookup status"] = flight_data[:status]
              new_row["Number of legs"] = flight_data[:route].length
              new_row["First leg departure airport IATA"] = flight_data[:route][:departure][:iata]
              new_row["Last leg arrival airport IATA"] = flight_data[:route][:arrival][:iata]
              new_row["Distance in kilometers"] = flight_data[:distance]
              updated_rows << new_row
            end
            success = true
          end
        else
          row["Lookup status"] = "Failed to retrieve flight information"
          row["Distance in kilometers"] = 0
          updated_rows << row
        end
      end
      headers = row.headers
    end
    sleep(20)
  end
  CSV.open(file_path, "w", write_headers: true, headers: headers) do |csv|
    updated_rows.each { |row| csv << row }
  end

  puts "CSV file updated successfully."
end
