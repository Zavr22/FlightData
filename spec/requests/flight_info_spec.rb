require "rails_helper"
require "vcr"
require "webmock/rspec"

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock
end

RSpec.describe FlightInfoController, type: :controller do
  describe "GET #get_flight_info" do
    context "with a valid flight number" do
      it "returns flight information" do
        flight_number = "MEA503"

        VCR.use_cassette("get_flight_info_valid_flight_number") do
          get :get_flight_info, params: { flight_num: flight_number }

          expect(response).to have_http_status(:ok)
          response_data = JSON.parse(response.body)
          expect(response_data["status"]).to eq("OK")
        end
      end
    end

    context "with an invalid flight number" do
      it "returns a bad request status" do
        flight_number = "invalid"

        VCR.use_cassette("get_flight_info_invalid_flight_number") do
          get :get_flight_info, params: {flight_num: flight_number}

          expect(response).to have_http_status(:bad_request)
          response_data = JSON.parse(response.body)
          expect(response_data["status"]).to eq("FAIL")
          expect(response_data["error_message"]).to eq("Invalid flight number format")
        end
      end
    end

    context "when the API request fails" do
      it "returns an ok status with message" do
        flight_number = "AA"

        VCR.use_cassette("get_flights_api_failure") do
          get :get_flight_info, params: {flight_num: flight_number}

          expect(response).to have_http_status(:ok)
          response_data = JSON.parse(response.body)
          expect(response_data["error_message"]).to eq("Failed to retrieve flight information from API, no such flights")
        end
      end
    end
  end

  describe "GET #get_flights_by_airports" do
    context "with valid airport codes" do
      it "returns flight information" do
        VCR.use_cassette("flights_by_airports_request") do
          iata_origin = "FRU"
          iata_destination = "ISI"

          get :get_flights_by_airports, params: {iata_origin: iata_origin, iata_destination: iata_destination}

          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "with invalid airport codes" do
      it "returns a bad request status" do
        VCR.use_cassette("flights_by_airports_invalid_request") do
          iata_origin = "INVALID"
          iata_destination = "INVALID"

          get :get_flights_by_airports, params: { iata_origin: iata_origin, iata_destination: iata_destination }

          expect(response).to have_http_status(:bad_request)
          expect(JSON.parse(response.body)["status"]).to eq("FAIL")
          expect(JSON.parse(response.body)["error_message"]).to eq("Invalid iata airport codes")
        end
      end
    end

    context "when the API request fails" do
      it "returns a bad gateway status" do
        VCR.use_cassette("flights_by_airports_api_failure") do
          iata_origin = "DIA"
          iata_destination = "INVALID"

          get :get_flights_by_airports, params: { iata_origin: iata_origin, iata_destination: iata_destination }

          expect(response).to have_http_status(:bad_request)
          expect(JSON.parse(response.body)["status"]).to eq("FAIL")
          expect(JSON.parse(response.body)["error_message"]).to eq("Invalid iata airport codes")
        end
      end
    end
  end
end
