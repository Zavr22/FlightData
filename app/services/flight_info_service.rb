# app/services/flight_info_service.rb
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
        formatted_flights = []
        flight_data.each do |flight|
          print flight
          departure_coordinates = if flight["origin"].nil?
            {"latitude" => "", "longitude" => ""}
          else
            get_airport_coordinates(flight["origin"])
          end
          arrival_coordinates = if flight["destination"].nil?
            {"latitude" => "", "longitude" => ""}
          else
            get_airport_coordinates(flight["destination"])
          end
          formatted_info = @formatting_service.format_flight_info(departure_coordinates, arrival_coordinates, flight)
          save_flight_info(flight, departure_coordinates, arrival_coordinates)

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

  def save_flight_info(flight_data, departure_coordinates, arrival_coordinates)
    Flight.create(
      flight_number: flight_data["ident"],
      lookup_status: "OK",
      number_of_legs: 1,
      first_leg_departure_airport_iata: departure_coordinates["code_iata"],
      last_leg_arrival_airport_iata: arrival_coordinates["code_iata"],
      distance_in_kilometers: flight_data["route_distance"],
      departure_iata: departure_coordinates["code_iata"],
      departure_city: departure_coordinates["city"],
      departure_country: flight_data["origin"]["country"],
      departure_latitude: departure_coordinates["latitude"],
      departure_longitude: departure_coordinates["longitude"],
      arrival_iata: arrival_coordinates["code_iata"],
      arrival_city: arrival_coordinates["city"],
      arrival_country: arrival_coordinates["country"],
      arrival_latitude: arrival_coordinates["latitude"],
      arrival_longitude: arrival_coordinates["longitude"]
    )
  end

  def get_airport_coordinates(place_info)
    if place_info["code_iata"].nil?
      return {
        "airport_code" => "not defined by api",
        "alternate_ident" => "not defined by api",
        "code_icao" => "not defined by api",
        "code_iata" => "not defined by api",
        "code_lid" => "not defined by api",
        "name" => "not defined by api",
        "type" => "not defined by api",
        "elevation" => "not defined by api",
        "city" => "not defined by api",
        "state" => "not defined by api",
        "longitude" => 0.0,
        "latitude" => 0.0,
        "timezone" => "not defined by api",
        "country_code" => "not defined by api",
        "wiki_url" => "not defined by api",
        "airport_flights_url" => "not defined by api",
        "alternatives" => []
      }
    end

    if !place_info["code_iata"].match?(/[A-Z]{3}/)
      return {
        "airport_code" => "not defined by api",
        "alternate_ident" => "not defined by api",
        "code_icao" => "not defined by api",
        "code_iata" => "not defined by api",
        "code_lid" => "not defined by api",
        "name" => "not defined by api",
        "type" => "not defined by api",
        "elevation" => "not defined by api",
        "city" => "not defined by api",
        "state" => "not defined by api",
        "longitude" => "not defined by api",
        "latitude" => "not defined by api",
        "timezone" => "not defined by api",
        "country_code" => "not defined by api",
        "wiki_url" => "not defined by api",
        "airport_flights_url" => "not defined by api",
        "alternatives" => []
      }
    end
    response = HTTParty.get(URI("https://aeroapi.flightaware.com/aeroapi/airports/#{place_info["code_iata"]}"), headers: {"x-apikey" => @api_key})
    if response
      JSON.parse(response.body)
    end
  end
end
