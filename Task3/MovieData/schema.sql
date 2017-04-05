DROP TABLE IF EXISTS directors;
DROP TABLE IF EXISTS movies;

CREATE TABLE movies (
  movie_id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  original_title VARCHAR(255),
  director_id INT NOT NULL
);

CREATE TABLE directors (
  director_id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  imdb_link VARCHAR(255) NOT NULL
);
