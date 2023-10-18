class FlightInfoService
  def initialize(api_key)
    @api_key = api_key
    @formatting_service = FlightFormattingService.new
  end

  def retrieve_flight_info_from_api(flight_number)
    url = URI("https://aeroapi.flightaware.com/aeroapi/flights/#{flight_number}")
    response = HTTParty.get(url, headers: {"x-apikey" => @api_key})

    if response.success? && response.body.present?
      data = JSON.parse(response.body)

      if data["flights"].is_a?(Array) && !data["flights"].empty?
        flight_data = data["flights"]
        airport_coordinates_cache = {}

        formatted_flights = []

        flight_data.each do |flight|
          departure_airport = flight["origin"]
          arrival_airport = flight["destination"]

          departure_coordinates = airport_coordinates_cache[departure_airport] || get_airport_coordinates(departure_airport)
          arrival_coordinates = airport_coordinates_cache[arrival_airport] || get_airport_coordinates(arrival_airport)

          airport_coordinates_cache[departure_airport] = departure_coordinates
          airport_coordinates_cache[arrival_airport] = arrival_coordinates

          existing_flight = Flight.find_by(flight_number: flight["ident"])

          if existing_flight.nil?
            save_flight_info(flight, departure_coordinates, arrival_coordinates)
          end

          distance = flight["route_distance"].to_f
          distance_in_kilometers = distance.nil? ? 0 : (distance * 1.60934)
          formatted_info = @formatting_service.format_flight_info(departure_coordinates, arrival_coordinates, distance_in_kilometers)

          formatted_flights << formatted_info
        end

        return @formatting_service.format_multi_leg_flight(formatted_flights)
      end
    end
    {
      route: nil,
      status: "FAIL",
      distance: 0,
      error_message: "Failed to retrieve flight information from FlightAware API"
    }
  end

  def get_flights_by_airports_codes(origin_iata, destination_iata)
    puts origin_iata
    puts destination_iata
    url = URI("https://aeroapi.flightaware.com/aeroapi/airports/#{origin_iata}/flights/to/#{destination_iata}")
    response = HTTParty.get(url, headers: {"x-apikey" => @api_key})

    if response.success? && response.body.present?
      data = JSON.parse(response.body)
      puts(data)
      if data["flights"].is_a?(Array) && !data["flights"].empty?
        flight_data = data["flights"]
        airport_coordinates_cache = {}
        formatted_flights = []
        flight_data.each do |segments|
          flight_segment = segments["segments"]
          if flight_segment.is_a?(Array) && !flight_segment.empty?
            flight_segment.each do |flight|
              puts flight
              puts flight["origin"]
              puts flight["desttination"]
              departure_airport = if flight["origin"].nil?
                {"latitude" => "", "longitude" => ""}
              else
                departure_coordinates = airport_coordinates_cache[departure_airport] || get_airport_coordinates(flight["origin"])
              end
              arrival_airport = if flight["destination"].nil?
                {"latitude" => "", "longitude" => ""}
              else
                arrival_coordinates = airport_coordinates_cache[arrival_airport] || get_airport_coordinates(flight["destination"])
              end
              airport_coordinates_cache[departure_airport] = departure_coordinates
              airport_coordinates_cache[arrival_airport] = arrival_coordinates
              existing_flight = Flight.find_by(flight_number: flight["ident"])
              if existing_flight.nil?
                save_flight_info(flight, departure_coordinates, arrival_coordinates)
              end
              distance = flight["route_distance"].to_f
              distance_in_kilometers = distance.nil? ? 0 : (distance * 1.60934)
              formatted_info = @formatting_service.format_flight_info(departure_coordinates, arrival_coordinates, distance_in_kilometers)

              formatted_flights << formatted_info
            end
          end
        end
        return @formatting_service.format_multi_leg_flight(formatted_flights)
      end
    end
    {
      route: nil,
      status: "FAIL",
      distance: 0,
      error_message: "Failed to retrieve flight information from FlightAware API"
    }
  end

  def get_flights_between_airports(airport_origin, airport_destination)
    flights = Flight.where(first_leg_departure_airport_iata: airport_origin, last_leg_arrival_airport_iata: airport_destination)
    puts flights
    if flights.present?
      flights.map do |flight|
        departure_airport = Airport.find_by(code_iata: flight.first_leg_departure_airport_iata)
        arrival_airport = Airport.find_by(code_iata: flight.last_leg_arrival_airport_iata)
        return @formatting_service.format_multi_leg_flight(@formatting_service.format_flight_info(departure_airport, arrival_airport, flight.distance_in_kilometers))
      end
    else
      get_flights_by_airports_codes(airport_origin, airport_destination)
    end
  end

  def save_flight_info(flight_data, departure_coordinates, arrival_coordinates)
    departure_airport = Airport.find_or_create_by(code_iata: departure_coordinates["code_iata"]) do |airport|
      airport.city = departure_coordinates["city"]
      airport.country = departure_coordinates["country"]
      airport.latitude = departure_coordinates["latitude"]
      airport.longitude = departure_coordinates["longitude"]
    end
    arrival_airport = Airport.find_or_create_by(code_iata: arrival_coordinates["code_iata"]) do |airport|
      airport.city = arrival_coordinates["city"]
      airport.country = arrival_coordinates["country"]
      airport.latitude = arrival_coordinates["latitude"]
      airport.longitude = arrival_coordinates["longitude"]
    end
    Flight.create(
      flight_number: flight_data["ident"],
      lookup_status: "OK",
      number_of_legs: 1,
      first_leg_departure_airport_iata: departure_coordinates["code_iata"],
      last_leg_arrival_airport_iata: arrival_coordinates["code_iata"],
      distance_in_kilometers: flight_data["route_distance"],
      departure_airport: departure_airport,
      arrival_airport: arrival_airport
    )
  end

  def get_airport_coordinates(airport_code)
    airport_data = Airport.find_by(code_iata: airport_code["code_iata"])

    if airport_data
      airport_data
    else
      airport_data = fetch_airport_data(airport_code["code_iata"])
      if airport_data
        create_or_update_airport(airport_code, airport_data)
        airport_data
      else
        default_airport_info
      end
    end
  end

  def default_airport_info
    {
      "airport_code" => "not defined by API",
      "alternate_ident" => "not defined by API",
      "code_icao" => "not defined by API",
      "code_iata" => "not defined by API",
      "code_lid" => "not defined by API",
      "name" => "not defined by API",
      "type" => "not defined by API",
      "elevation" => "not defined by API",
      "city" => "not defined by API",
      "state" => "not defined by API",
      "longitude" => 0.0,
      "latitude" => 0.0,
      "timezone" => "not defined by API",
      "country_code" => "not defined by API",
      "wiki_url" => "not defined by API",
      "airport_flights_url" => "not defined by API",
      "alternatives" => []
    }
  end

  def fetch_airport_data(airport_code)
   response = HTTParty.get(URI("https://aeroapi.flightaware.com/aeroapi/airports/#{airport_code}"), headers: {"x-apikey" => @api_key})
   if response
     JSON.parse(response.body)
   end
 end

  def create_or_update_airport(airport_code, airport_data)
    airport = Airport.find_or_initialize_by(code_iata: airport_code["code_iata"])

    airport.update(
      code_icao: airport_data["code_icao"],
      name: airport_data["name"],
      city: airport_data["city"],
      country: airport_data["country"],
      latitude: airport_data["latitude"],
      longitude: airport_data["longitude"]
    )

    airport
  end
end
