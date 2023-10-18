require "rails_helper"
require "vcr"
require 'webmock/rspec'

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock
end

RSpec.describe FlightInfoService do
  let(:api_key) {ENV["FLIGHT_AWARE_API_KEY"]}
  let(:flight_info_service) { FlightInfoService.new(api_key) }

  describe "#retrieve_flight_info_from_api" do
    context "when flight data is available" do
      it "returns flight information for a valid flight" do
        flight_number = "MEA503"
        allow(HTTParty).to receive(:get).and_return(double(success?: true, body: '{
            "route": [
              {
                "route": {
                  "departure": {
                    "iata": "DIA",
                    "city": "Doha",
                    "country": null,
                    "latitude": 25.261125,
                    "longitude": 51.565056
                  },
                  "arrival": {
                    "iata": "BEY",
                    "city": "Beirut",
                    "country": null,
                    "latitude": 33.820931,
                    "longitude": 35.488389
                  }
                },
                "status": "OK",
                "distance": 1132,
                "error_message": null
              },
              {
                "route": {
                  "departure": {
                    "iata": "DIA",
                    "city": "Doha",
                    "country": null,
                    "latitude": 25.261125,
                    "longitude": 51.565056
                  },
                  "arrival": {
                    "iata": "BEY",
                    "city": "Beirut",
                    "country": null,
                    "latitude": 33.820931,
                    "longitude": 35.488389
                  }
                },
                "status": "OK",
                "distance": 1132,
                "error_message": null
              }
            ],
            "status": "OK",
            "error_message": null
          }'))

        result = flight_info_service.retrieve_flight_info_from_api(flight_number)
        !expect(result).nil?
      end

      it "returns flight information for another valid flight" do
        flight_number = "MEA503"
        allow(HTTParty).to receive(:get).and_return(double(success?: true, body: '{
            "route": [
              {
                "route": {
                  "departure": {
                    "iata": "DIA",
                    "city": "Doha",
                    "country": null,
                    "latitude": 25.261125,
                    "longitude": 51.565056
                  },
                  "arrival": {
                    "iata": "BEY",
                    "city": "Beirut",
                    "country": null,
                    "latitude": 33.820931,
                    "longitude": 35.488389
                  }
                },
                "status": "OK",
                "distance": 1132,
                "error_message": null
              },
              {
                "route": {
                  "departure": {
                    "iata": "DIA",
                    "city": "Doha",
                    "country": null,
                    "latitude": 25.261125,
                    "longitude": 51.565056
                  },
                  "arrival": {
                    "iata": "BEY",
                    "city": "Beirut",
                    "country": null,
                    "latitude": 33.820931,
                    "longitude": 35.488389
                  }
                },
                "status": "OK",
                "distance": 1132,
                "error_message": null
              }
            ],
            "status": "OK",
            "error_message": null
          }'))

        result = flight_info_service.retrieve_flight_info_from_api(flight_number)
        !expect(result).nil?
      end
    end

    context "when flight data is not available" do
      it "returns a failure status for an invalid flight" do
        flight_number = "INVALID"
        allow(HTTParty).to receive(:get).and_return(double(success?: true, body: '{
          "title": "Invalid argument",
          "reason": "INVALID_ARGUMENT",
          "status": 400,
          "detail": "Invalid id provided"
          }
        '))

        result = flight_info_service.retrieve_flight_info_from_api(flight_number)

        expect(result[:status]).to eq("FAIL")
        expect(result[:route]).to be_nil
      end

      it "returns a failure status when the API request fails" do
        flight_number = "AA6"
        allow(HTTParty).to receive(:get).and_return(double(success?: false, body: ""))

        result = flight_info_service.retrieve_flight_info_from_api(flight_number)

        expect(result[:status]).to eq("FAIL")
        expect(result[:error_message]).to eq("Failed to retrieve flight information from FlightAware API")
      end
    end
  end

  describe "#get_airport_coordinates" do
    context "when airport data is available in the database" do
      it "returns airport coordinates from the database" do
        airport_code = "DIA"
        result = flight_info_service.get_airport_coordinates({ "code_iata" => airport_code })

        expect(result["code_iata"]).to eq(airport_code)
        expect(result["latitude"]).to eq(25.261125)
        expect(result["longitude"]).to eq(51.565056)
      end
    end

    context "when airport data is not available in the database" do
      it "fetches and creates airport data from the API" do
        airport_code = "DIA"
        response_data = { "code_iata" => airport_code, "latitude" => 25.0, "longitude" => 51.0 }
        allow(Airport).to receive(:find_by).and_return(nil)
        allow(flight_info_service).to receive(:fetch_airport_data).and_return(response_data)

        result = flight_info_service.get_airport_coordinates({ "code_iata" => airport_code })

        expect(result["code_iata"]).to eq(airport_code)
        expect(result["latitude"]).to eq(25.0)
        expect(result["longitude"]).to eq(51.0)
      end
    end

    context "when airport data cannot be fetched from the API" do
      it "returns default airport info" do
        airport_code = "INVALID"
        allow(Airport).to receive(:find_by).and_return(nil)
        allow(flight_info_service).to receive(:fetch_airport_data).and_return(nil)

        result = flight_info_service.get_airport_coordinates({ "code_iata" => airport_code })

        expect(result["code_iata"]).to eq("not defined by API")
        expect(result["latitude"]).to eq(0.0)
        expect(result["longitude"]).to eq(0.0)
      end
    end
  end


  describe "#fetch_airport_data" do
    it "fetches airport data from the API" do
      airport_code = "DIA"
      expected_url = "https://aeroapi.flightaware.com/aeroapi/airports/#{airport_code}"
      response_data = { "name" => "Airport Name", "city" => "Airport City" }
      allow(HTTParty).to receive(:get).with(URI(expected_url), headers: {"x-apikey" => api_key}).and_return(
        double(success?: true, body: JSON.dump(response_data))
      )

      result = flight_info_service.fetch_airport_data(airport_code)

      expect(result).to eq(response_data)
    end
  end

  describe "#create_or_update_airport" do
    it "creates or updates an airport in the database" do
      airport_code = "DIA"
      airport_data = {"name" => "Airport Name", "city" => "Airport City"}

      result = flight_info_service.create_or_update_airport(airport_code, airport_data)

      expect(result).to be_an(Airport)
    end
  end
  let(:api_key) { ENV["FLIGHT_AWARE_API_KEY"] }
  let(:flight_info_service) { FlightInfoService.new(api_key) }

  describe "#get_flights_between_airports" do
    context "when flights are available in the database" do
      it "returns flights between two airports" do
        VCR.use_cassette("get_flights_between_airports_db") do
          result = flight_info_service.get_flights_between_airports("DIA", "BEY")
          expect(result).to be_an(Array)
          expect(result).not_to be_empty
        end
      end
    end
  end

  describe "#get_flights_by_airports_codes" do
    context "when flights are available in the API response" do
      it "returns flights between two airports" do
        VCR.use_cassette("get_flights_by_airports_codes_api") do
          iata_origin = "DIA"
          iata_destination = "BEY"
          result = flight_info_service.get_flights_by_airports_codes(iata_origin, iata_destination)
          expect(result).to be_an(Array)
        end
      end
    end

    context "when no flights are available in the API response" do
      it "returns a failure status" do
        iata_origin = "DIA"
        iata_destination = "BEY"
        allow(HTTParty).to receive(:get).and_return(double(success?: true, body: JSON.dump("flights" => [])))

        result = flight_info_service.get_flights_by_airports_codes(iata_origin, iata_destination)

        expect(result[:status]).to eq("FAIL")
      end

      context "when the API request fails" do
        it "returns a failure status" do
          iata_origin = "DIA"
          iata_destination = "BEY"
          allow(HTTParty).to receive(:get).and_return(double(success?: false, body: ' "status" => "FAIL",
            "error_message" => "Failed to retrieve flight information from FlightAware API",
            "distance" => 0,
            "route" => nil"'))

          result = flight_info_service.get_flights_by_airports_codes(iata_origin, iata_destination)

          expect(result[:status]).to eq("FAIL")
        end
      end
    end
  end

end
