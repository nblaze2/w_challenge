require 'pg'
require 'pry'

def db_connection
  begin
    connection = PG.connect(dbname: 'dvdrental')
    yield(connection)
  ensure
    connection.close
  end
end
max_rentals = db_connection do |conn|
  conn.exec(
  'SELECT customer.customer_id, Count(*) AS Frequency
  FROM customer
  JOIN rental ON customer.customer_id = rental.customer_id
  JOIN staff ON rental.staff_id = staff.staff_id
  JOIN store ON staff.store_id = store.store_id
  WHERE store.store_id = 2
  GROUP BY customer.customer_id
  HAVING Count(*) >= ALL
    (SELECT Count(*)
    FROM customer
    JOIN rental ON customer.customer_id = rental.customer_id
    JOIN staff ON rental.staff_id = staff.staff_id
    JOIN store ON staff.store_id = store.store_id
    WHERE store.store_id = 2
    GROUP BY customer.customer_id);'
  ).to_a
end
top_renters = []
db_connection do |conn|
  max_rentals.each do |renter|
    split_name = conn.exec(
      'SELECT first_name, last_name
      FROM customer
      WHERE customer_id = $1', [renter["customer_id"]]
      ).to_a
      top_renters << split_name[0]["first_name"] + ' ' + split_name[0]["last_name"]
  end
end
puts "Q1) The people who had the most rentals (24 each) from store 2 are:"
puts top_renters
puts ''

ip_rentals = db_connection do |conn|
  conn.exec(
  "SELECT rental.rental_date, rental.return_date
  FROM film
  JOIN inventory ON film.film_id = inventory.film_id
  JOIN rental ON inventory.inventory_id = rental.inventory_id
  WHERE film.title = 'Image Princess'
  AND inventory.store_id = 2
  ORDER BY rental.rental_date").to_a
end
puts "Q2) On 29/07/2005 at 3 pm 'Image Princess' was already checked out from Store 2"
puts ip_rentals
puts ''

cust_count_month = db_connection do |conn|
  conn.exec(
  "SELECT COUNT(DISTINCT customer_id) AS ActiveCustomers, EXTRACT(MONTH FROM rental_date) AS Month, EXTRACT(YEAR FROM rental_date) AS Year
  FROM rental
  GROUP BY Year, Month"
  ).to_a
end
puts "Q3) The number of active customers per month based on number of unique 'customer_id' used:"
cust_count_month.each do |i|
  puts "Month/Year: #{i['month']}/#{i['year']} | Active Customers: #{i['activecustomers']}"
end
puts ''

max_category = db_connection do |conn|
  conn.exec(
  'SELECT category.name, Count(*) AS MostPopular
  FROM category
  JOIN film_category ON category.category_id = film_category.category_id
  JOIN film ON film_category.film_id = film.film_id
  JOIN inventory ON film.film_id = inventory.film_id
  JOIN rental ON inventory.inventory_id = rental.inventory_id
  GROUP BY category.name
  HAVING Count(*) >= ALL
    (SELECT Count(*)
    FROM category
    JOIN film_category ON category.category_id = film_category.category_id
    JOIN film ON film_category.film_id = film.film_id
    JOIN inventory ON film.film_id = inventory.film_id
    JOIN rental ON inventory.inventory_id = rental.inventory_id
    GROUP BY category.name);'
  ).to_a
end
puts "Q4) The most popular category is #{max_category[0]['name']} with #{max_category[0]['mostpopular']} rentals"
puts ''

fav_sports = db_connection do |conn|
  conn.exec(
  'SELECT film.title, Count(*) AS MostPopular
  FROM film
  JOIN film_category ON film.film_id = film_category.film_id
  JOIN category ON film_category.category_id = category.category_id
  JOIN inventory ON film.film_id = inventory.film_id
  JOIN rental ON inventory.inventory_id = rental.inventory_id
  GROUP BY film.title
  HAVING Count(*) >= ALL
    (SELECT Count(*)
    FROM film
    JOIN film_category ON film.film_id = film_category.film_id
    JOIN category ON film_category.category_id = category.category_id
    JOIN inventory ON film.film_id = inventory.film_id
    JOIN rental ON inventory.inventory_id = rental.inventory_id
    GROUP BY film.title);'
  ).to_a
end

puts "Q5) The most popular movie in the sports categorty is: #{fav_sports[0]['title']} with #{fav_sports[0]['mostpopular']} rentals"
puts ""
puts "Q6) I have more questions than insights.
* Why are all your rentals from the summer of 2005 and February 2006 (see Q3),
but your payments are all in the spring of 2007?
('SELECT SUM(amount) AS Income, EXTRACT(MONTH FROM payment_date) AS Month, EXTRACT(YEAR FROM payment_date) AS Year FROM payment')
Generally it is important for businesses to collect payment within a timely fashion, so they can stay in business.
* Why are your two DVD stores on different continents?
It seems like the answer to Q2 is irrelavent if the other store is a 20+ hour flight away.
('SELECT store.store_id, city.city, country.country FROM country dvdrental-# JOIN city ON country.country_id = city.country_id
JOIN address ON city.city_id = address.city_id
JOIN store ON address.address_id = store.address_id')
Also how do you manage to serve customers in 109 countries across the globe?
('SELECT COUNT(DISTINCT country) FROM country')
It would be a lot easier if the two stores focused on local customers, and if all the stores were in the same time-zone and continent.
* Otherwise you have a nice distribution of product. You have an even distribution of categories in both stores.
(SELECT category.name, Count(*) AS MostPopular, store.store_id
FROM store
JOIN staff ON store.store_id = staff.store_id
JOIN rental ON staff.staff_id = rental.staff_id
JOIN inventory ON rental.inventory_id = inventory.inventory_id
JOIN film ON inventory.film_id = film.film_id JOIN film_category ON film.film_id = film_category.film_id
JOIN category ON film_category.category_id = category.category_id GROUP BY store.store_id, category.name)
*  There is even variety of actors featured in the inventory.
(SELECT actor.actor_id, Count(*) AS ActorFilms FROM film_actor JOIN actor ON film_actor.actor_id = actor.actor_id GROUP BY actor.actor_id)"
