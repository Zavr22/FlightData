# README

* Ruby version 3.0.6
----------------------
* Theme: Rails Api that that accept flight number and finds a flight's route information based on it
* Main route is http://localhost:3000/flight_info?flight_num=XXZZZZ or YYYZZZZ flight number format
* It uses AeroApi to get information about flights
* Controller contains lots of checks of data that are received from API to prevent issues with API data processing
* PostgreSQL is used for cache data for not making extra requests to API 
----------------------
* It has script (./lib/tasks/fill_csv.rake) that accept CSV file and fills it with data (original file is located in ./lib/tasks)
----------------------
* Tests were made with rspec, located in ./spec/
* Models, Controller and Script were tested
--------------------------------
* To start server  use command: rails server


