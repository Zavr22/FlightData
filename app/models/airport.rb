class Airport < ApplicationRecord
  validates :code_iata, presence: true
  validate :valid_code_iata
  has_many :flights

  def valid_code_iata
    return if code_iata.blank?
    valid_format_iata = /\A([A-Z]{3})\z/

    unless code_iata.nil?
      self.code_iata = code_iata.gsub(/[^A-Za-z]/, "").upcase
    end
    unless code_iata.match(valid_format_iata)
      errors.add(:code_iata, "is not in a valid format")
      nil
    end
  end
end
