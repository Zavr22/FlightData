class FlightInfoController < ApplicationController
  def get_flight_info
    flight_number = params[:flight_num]
    flight = Flight.new(flight_number: flight_number)
    unless flight.valid?
      render json: {
        route: nil,
        status: "FAIL",
        distance: 0,
        error_message: "Invalid flight number format"
      }, status: :bad_request
      return
    end

    flight_info = Flight.find_by(flight_number: flight.flight_number)
    if flight_info
      formatted_info = format_flight_info(
        {
          "code_iata" => flight_info.departure_iata,
          "city" => flight_info.departure_city,
          "country" => flight_info.departure_country,
          "longitude" => flight_info.departure_longitude,
          "latitude" => flight_info.departure_longitude
        },
        {
          "code_iata" => flight_info.arrival_iata,
          "city" => flight_info.arrival_city,
          "country" => flight_info.arrival_country,
          "longitude" => flight_info.arrival_longitude,
          "latitude" => flight_info.arrival_longitude
        },
        {
          "distance" => flight_info.distance_in_kilometers
        }
      )
      render json: formatted_info
    else
      flight_info = retrieve_flight_info_from_api(flight_number)
      if flight_info[:status] == "FAIL"
        render json: {
          route: nil,
          status: "FAIL",
          distance: 0,
          error_message: "Failed to retrieve flight information from API, no such flights"
        }
      else
        render json: flight_info
      end
    end
  end

  def retrieve_flight_info_from_api(flight_number)
    url = URI("https://aeroapi.flightaware.com/aeroapi/flights/#{flight_number}")
    response = HTTParty.get(url, headers: { "x-apikey" => "AtQvG41GKevewFSnsM0kWMtcMkhgeZ0U" })

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
          formatted_info = format_flight_info(departure_coordinates, arrival_coordinates, flight)
          save_flight_info(flight, departure_coordinates, arrival_coordinates)

          formatted_flights << formatted_info
        end

        return format_multi_leg_flight(formatted_flights)
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
    response = HTTParty.get(URI("https://aeroapi.flightaware.com/aeroapi/airports/#{place_info["code_iata"]}"), headers: {"x-apikey" => "AtQvG41GKevewFSnsM0kWMtcMkhgeZ0U"})
    if response
      JSON.parse(response.body)
    end
  end

  def format_flight_info(departure_data, arrival_data, flight_data)
    {
      route: {
        departure: {
          iata: departure_data["code_iata"],
          city: departure_data["city"],
          country: departure_data["country"],
          latitude: departure_data["latitude"],
          longitude: departure_data["longitude"]
        },
        arrival: {
          iata: arrival_data["code_iata"],
          city: arrival_data["city"],
          country: arrival_data["country"],
          latitude: arrival_data["latitude"],
          longitude: arrival_data["longitude"]
        }
      },
      status: "OK",
      distance: flight_data["route_distance"],
      error_message: nil
    }
  end

  def format_multi_leg_flight(flight_data)
    if flight_data.is_a?(Array) && flight_data.length > 1
      {
        route: flight_data,
        status: "OK",
        error_message: nil
      }
    else
      flight_data
    end
  end
end

