class Flight < ApplicationRecord
  validates :flight_number, presence: true
  validate :valid_flight_number

  def valid_flight_number
    return if flight_number.blank?
    valid_format = /\A([A-Z0-9]{2}\d{4}|[A-Z0-9]{3}\d{4})\z/

    unless flight_number.match(valid_format)
      errors.add(:flight_number, 'is not in a valid format')
      return
    end
    unless flight_number.nil?
      zzzz = flight_number[-4..-1]
      if zzzz.length < 4
        padded_zzzz = zzzz.rjust(4, '0')
        self.flight_number = flight_number[0..-5] + padded_zzzz
      end
    end
  end

end
