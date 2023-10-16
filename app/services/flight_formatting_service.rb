class FlightFormattingService
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
