require "rails_helper"
require "rake"

RSpec.describe "import:csv" do
  let(:rake) { Rake::Application.new }
  let(:file_path) { "/Users/mihailkulik/Documents/Programming/FlightData/flight-data/lib/tasks/flight_numbers.csv" }

  before do
    Rake.application = rake
    Rake.application.rake_require("lib/tasks/fill_csv", [Rails.root.to_s])
    Rake::Task.define_task(:environment)
  end

  it "imports data from a CSV file" do
    expect { Rake::Task["import:csv"].invoke }.not_to raise_error
  end
end
