class FlightInfoController < ApplicationController
  def get_flight_info
    flight_number = params[:flight_num]
    flight_info_service = FlightInfoService.new(ENV["FLIGHT_AWARE_API_KEY"])
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

    puts flight.flight_number
    flight_info = Flight.find_by(flight_number: flight.flight_number)
    if flight_info
      departure_airport = Airport.find_by(code_iata: flight_info.first_leg_departure_airport_iata)
      arrival_airport = Airport.find_by(code_iata: flight_info.last_leg_arrival_airport_iata)

      formatted_info = FlightFormattingService.new.format_flight_info(
        {
          "code_iata" => departure_airport.code_iata,
          "city" => departure_airport.city,
          "country" => departure_airport.country,
          "longitude" => departure_airport.longitude,
          "latitude" => departure_airport.latitude
        },
        {
          "code_iata" => arrival_airport.code_iata,
          "city" => arrival_airport.city,
          "country" => arrival_airport.country,
          "longitude" => arrival_airport.longitude,
          "latitude" => arrival_airport.latitude
        },
        {
          "distance" => flight_info.distance_in_kilometers
        }
      )

      render json: formatted_info
    else
      flight_info = flight_info_service.retrieve_flight_info_from_api(flight.flight_number)
      puts flight_info
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

  def get_flights_by_airports
    iata_origin = params[:iata_origin]
    iata_destination = params[:iata_destination]
    flight_info_service = FlightInfoService.new(ENV["FLIGHT_AWARE_API_KEY"])
    airport_origin = Airport.new(code_iata: iata_origin )
    airport_destination = Airport.new(code_iata: iata_destination)
    unless airport_origin.valid? && airport_destination.valid?
      render json: {
        route: nil,
        status: "FAIL",
        distance: 0,
        error_message: "Invalid iata airport codes"
      }, status: :bad_request
      return
    end
    flights_info = flight_info_service.get_flights_between_airports(airport_origin.code_iata, airport_destination.code_iata)
    puts(flights_info)
    if flights_info[:status] == "FAIL"
      render json: {
        route: nil,
        status: "FAIL",
        distance: 0,
        error_message: "Failed to retrieve flight information from API, no such flights"
      }
    else
      render json: flights_info
    end
  end
end
