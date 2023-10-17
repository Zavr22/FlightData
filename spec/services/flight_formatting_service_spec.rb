require "rails_helper"

RSpec.describe FlightFormattingService do
  let(:flight_formatting_service) { FlightFormattingService.new }

  describe "#format_flight_info" do
    it "formats flight information correctly" do
      departure_data = {
        "code_iata" => "SFO",
        "city" => "San Francisco",
        "country" => "USA",
        "latitude" => 37.618817,
        "longitude" => -122.375427
      }

      arrival_data = {
        "code_iata" => "JFK",
        "city" => "New York",
        "country" => "USA",
        "latitude" => 40.6413111,
        "longitude" => -73.7781391
      }

      flight_data = {
        "route_distance" => 2500
      }

      formatted_info = flight_formatting_service.format_flight_info(departure_data, arrival_data, flight_data)

      expect(formatted_info[:route][:departure][:iata]).to eq("SFO")
      expect(formatted_info[:route][:departure][:city]).to eq("San Francisco")
      expect(formatted_info[:route][:departure][:country]).to eq("USA")
      expect(formatted_info[:route][:departure][:latitude]).to eq(37.618817)
      expect(formatted_info[:route][:departure][:longitude]).to eq(-122.375427)

      expect(formatted_info[:route][:arrival][:iata]).to eq("JFK")
      expect(formatted_info[:route][:arrival][:city]).to eq("New York")
      expect(formatted_info[:route][:arrival][:country]).to eq("USA")
      expect(formatted_info[:route][:arrival][:latitude]).to eq(40.6413111)
      expect(formatted_info[:route][:arrival][:longitude]).to eq(-73.7781391)

      expect(formatted_info[:status]).to eq("OK")
      expect(formatted_info[:distance]).to eq(4023.35)
      expect(formatted_info[:error_message]).to be_nil
    end
  end

  describe "#format_multi_leg_flight" do
    it "formats multi-leg flight correctly" do
      flight_data = [
        {
          route: { departure: {iata: "SFO"}, arrival: {iata: "JFK"}},
          status: "OK"
        },
        {
          route: {departure: {iata: "JFK"}, arrival: {iata: "LHR"}},
          status: "OK"
        }
      ]

      formatted_info = flight_formatting_service.format_multi_leg_flight(flight_data)

      expect(formatted_info[:route]).to eq(flight_data)
      expect(formatted_info[:status]).to eq("OK")
      expect(formatted_info[:error_message]).to be_nil
    end

    it "returns the original data if not a multi-leg flight" do
      flight_data = {
        route: {departure: {iata: "SFO"}, arrival: {iata: "JFK"}},
        status: "OK"
      }

      formatted_info = flight_formatting_service.format_multi_leg_flight(flight_data)

      expect(formatted_info).to eq(flight_data)
    end
  end
end
