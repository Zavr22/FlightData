class Flight < ApplicationRecord
  belongs_to :departure_airport, class_name: "Airport", foreign_key: "departure_airport_id", optional: true
  belongs_to :arrival_airport, class_name: "Airport", foreign_key: "arrival_airport_id", optional: true
  validates :flight_number, presence: true
  validate :valid_flight_number

  def valid_flight_number
    return if flight_number.blank?
    valid_format = /\A([A-Z0-9]{2}\d{4}|[A-Z0-9]{3}\d{4})\z/
    puts "Original flight number: #{flight_number}"
    unless flight_number.nil?
      zzzz = flight_number.gsub(/\D/, "")
      puts zzzz
      if zzzz.length < 4
        padded_zzzz = zzzz.rjust(4, "0")
        puts padded_zzzz
        puts flight_number.gsub(/[^A-Za-z]/, "").upcase
        puts flight_number.gsub(/[^A-Za-z]/, "").upcase + padded_zzzz
        self.flight_number = flight_number.gsub(/[^A-Za-z]/, "").upcase + padded_zzzz
      end
    end
    puts "Formatted flight number: #{flight_number.match(valid_format)}"
    unless flight_number.match(valid_format)
      errors.add(:flight_number, "is not in a valid format")
      nil
    end
  end
end
