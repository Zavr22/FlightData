require 'rails_helper'

RSpec.describe Airport, type: :model do
  describe 'validations' do
    it 'is valid with a valid code_iata' do
      airport = Airport.new(code_iata: 'JFK')
      expect(airport).to be_valid
    end

    it 'is not valid with an invalid code_iata' do
      airport = Airport.new(code_iata: '409dofivdjn jodn ')
      expect(airport).not_to be_valid
      expect(airport.errors[:code_iata]).to include('is not in a valid format')
    end

    it 'transforms code_iata to uppercase and removes non-alphabetic characters' do
      airport = Airport.new(code_iata: 'abc123')
      airport.valid?
      expect(airport.code_iata).to eq('ABC')
    end
  end

  describe 'associations' do
    it 'has many flights' do
      association = described_class.reflect_on_association(:flights)
      expect(association.macro).to eq :has_many
    end
  end
end