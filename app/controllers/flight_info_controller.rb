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

    flight_info = Flight.find_by(flight_number: flight.flight_number)
    if flight_info
      formatted_info = FlightFormattingService.new.format_flight_info(
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
      flight_info = flight_info_service.retrieve_flight_info_from_api(flight_number)
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
end

