require "rails_helper"

RSpec.describe Flight, type: :model do
  let(:valid_flight_number) { "AA1234" }
  let(:valid_flight_number_3_chars) { "AAA1234" }
  let(:valid_flight_number_padded) { "AAA0001" }
  let(:invalid_flight_number) { "ABCD" }

  it "is valid with a valid flight number" do
    flight = Flight.new(flight_number: valid_flight_number)
    expect(flight).to be_valid
  end

  it "is valid with a valid 3-character flight number" do
    flight = Flight.new(flight_number: valid_flight_number_3_chars)
    expect(flight).to be_valid
  end

  it "is valid with a valid flight number that is padded" do
    flight = Flight.new(flight_number: valid_flight_number_padded)
    expect(flight).to be_valid
  end

  it "is not valid with an invalid flight number" do
    flight = Flight.new(flight_number: invalid_flight_number)
    expect(flight).not_to be_valid
  end

  it "converts and validates flight number format" do
    flight = Flight.new(flight_number: "aBc123")
    flight.valid?
    expect(flight.flight_number).to eq("ABC1230")
  end

  it "validates presence of flight number" do
    flight = Flight.new
    expect(flight).not_to be_valid
  end
end
