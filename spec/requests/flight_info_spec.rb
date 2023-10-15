require "rails_helper"

RSpec.describe FlightInfoController, type: :controller do
  describe "GET #get_flight_info" do
    context "with a valid flight number" do
      it "returns flight information" do
        flight_number = "MEA503"
        expect(HTTParty).to receive(:get).and_return(
          double(success?: true, body: '{
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
          }')
        )
        get :get_flight_info, params: {flight_num: flight_number}
        expect(response).to have_http_status(:ok)
      end
    end

    context "with an invalid flight number" do
      it "returns a bad request status" do
        flight_number = "invalid"
        get :get_flight_info, params: {flight_num: flight_number}

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to eq({
          "route" => nil,
          "status" => "FAIL",
          "distance" => 0,
          "error_message" => "Invalid flight number format"
        })
      end
    end

    context "when the API request fails" do
      it "returns a bad gateway status" do
        flight_number = "AA1234"
        expect(HTTParty).to receive(:get).and_return(
          double(success?: false, body: "")
        )

        get :get_flight_info, params: {flight_num: flight_number}

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({
          "route" => nil,
          "status" => "FAIL",
          "distance" => 0,
          "error_message" => "Failed to retrieve flight information from API, no such flights"
        })
      end
    end
  end
end
