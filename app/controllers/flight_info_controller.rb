class FlightInfoController < ApplicationController
  def get_flight_info
    flight_number = params[:flight_num]

    unless valid_flight_number?(flight_number)
      render json: {
        route: nil,
        status: "FAIL",
        distance: 0,
        error_message: "Invalid flight number format"
      }
      return
    end

    flight_info = Flight.find_by(flight_number: flight_number)

    if flight_info
      formatted_info = format_flight_info(
        {
          "code_iata" => flight_info.departure_iata,
          "city" => flight_info.departure_city,
          "country" => flight_info.departure_country
        },
        {
          "code_iata" => flight_info.arrival_iata,
          "city" => flight_info.arrival_city,
          "country" => flight_info.arrival_country
        },
        {
          "latitude" => flight_info.departure_latitude,
          "longitude" => flight_info.departure_longitude
        },
        {
          "latitude" => flight_info.arrival_latitude,
          "longitude" => flight_info.arrival_longitude
        },
        {
          "route_distance" => flight_info.distance_in_kilometers
        }
      )

      render json: formatted_info
    else
      flight_info = retrieve_flight_info_from_api(flight_number)
      if flight_info
        render json: flight_info
      else
        render json: {
          route: nil,
          status: "FAIL",
          distance: 0,
          error_message: "Failed to retrieve flight information from API"
        }
      end
    end
  end

  private

  def retrieve_flight_info_from_api(flight_number)
    url = URI("https://aeroapi.flightaware.com/aeroapi/flights/#{flight_number}")
    response = HTTParty.get(url, headers: { "x-apikey" => "GOG9beggz2hxuM9aG6312JM0aEEHVCWy" })

    if response.success? && response.body.present?
      data = JSON.parse(response.body)

      if data["flights"].is_a?(Array) && !data["flights"].empty?
        flight_data = data["flights"].first
        departure_info = flight_data["origin"]
        arrival_info = flight_data["destination"]
        departure_coordinates = get_airport_coordinates(departure_info)
        arrival_coordinates = get_airport_coordinates(arrival_info)

        formatted_info = format_flight_info(departure_info, arrival_info, departure_coordinates, arrival_coordinates, flight_data)
        Flight.create(
          flight_number: flight_number,
          lookup_status: "OK",
          number_of_legs: 1,
          first_leg_departure_airport_iata: departure_info["code_iata"],
          last_leg_arrival_airport_iata: arrival_info["code_iata"],
          distance_in_kilometers: flight_data["route_distance"],
          departure_iata: departure_info["code_iata"],
          departure_city: departure_info["city"],
          departure_country: departure_info["country"],
          departure_latitude: departure_coordinates["latitude"],
          departure_longitude: departure_coordinates["longitude"],
          arrival_iata: arrival_info["code_iata"],
          arrival_city: arrival_info["city"],
          arrival_country: arrival_info["country"],
          arrival_latitude: arrival_coordinates["latitude"],
          arrival_longitude: arrival_coordinates["longitude"]
        )
        return formatted_info
      end
    end

    {
      route: nil,
      status: "FAIL",
      distance: 0,
      error_message: "Failed to retrieve flight information from FlightAware API"
    }
  end

  def valid_flight_number?(flight_number)
    return false unless [6, 7].include?(flight_number.length)
    carrier_code = flight_number[0, 3]
    number = flight_number[3, 4]
    return false unless /^[A-Z0-9]+$/.match?(carrier_code)
    return false unless /^\d+$/.match?(number)
    true
  end

  def get_airport_coordinates(place_info)
    response = HTTParty.get(URI("https://aeroapi.flightaware.com/aeroapi/airports/#{place_info["code_icao"]}"), headers: {"x-apikey" => "GOG9beggz2hxuM9aG6312JM0aEEHVCWy"})
    if response
      JSON.parse(response.body)
    end
  end

  def format_flight_info(departure_info, arrival_info, departure_data, arrival_data, flight_data)
    {
      route: {
        departure: {
          iata: departure_info["code_iata"],
          city: departure_info["city"],
          country: departure_info["country"],
          latitude: departure_data["latitude"],
          longitude: departure_data["longitude"]
        },
        arrival: {
          iata: arrival_info["code_iata"],
          city: arrival_info["city"],
          country: arrival_info["country"],
          latitude: arrival_data["latitude"],
          longitude: arrival_data["longitude"]
        }
      },
      status: "OK",
      distance: flight_data["route_distance"],
      error_message: nil
    }
  end

end
