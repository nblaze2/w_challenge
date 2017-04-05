The db for this app was designed with the idea
that it would do a complete update when run.

This app uses the Faraday gem to access the API,
and the JSON and PG gems to interact with the data.

To set up the app run the line:

createdb now_playing

In your terminal.

Then just run:

ruby code.rb

The ruby program will drop/create the tables every time you run
the program. The program exceeded the rate-limits for the TMDB,
so I had to add code to slow the program down a little. There is also a
lingering issue with the IMDB links, that I believe possibly also has to do with
a rate-limit issue with IMDB. 
