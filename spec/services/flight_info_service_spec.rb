require "rails_helper"

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
    it "returns not defined by API for an invalid airport code" do
      airport_code = "INVALID"
      allow(HTTParty).to receive(:get).and_return(double(success?: true, body: "..."))

      result = flight_info_service.get_airport_coordinates(airport_code)

      expect(result["code_iata"]).to eq("not defined by api")
      expect(result["latitude"]).to eq(0.0)
      expect(result["longitude"]).to eq(0.0)
    end

    it "returns not defined by API for a non-IATA airport code" do
      airport_code = "XYZ"
      allow(HTTParty).to receive(:get).and_return(double(success?: true, body: "..."))

      result = flight_info_service.get_airport_coordinates(airport_code)

      expect(result["code_iata"]).to eq("not defined by api")
      expect(result["latitude"]).to eq(0.0)
      expect(result["longitude"]).to eq(0.0)
    end
  end
end
