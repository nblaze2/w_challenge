require 'pry'
require 'faraday'
require 'json'
require 'pg'

system('psql now_playing < schema.sql')

def db_connection
  begin
    connection = PG.connect(dbname: 'now_playing')
    yield(connection)
  ensure
    connection.close
  end
end

@conn = Faraday.new 'https://api.themoviedb.org', :ssl => {:verify => false}
@key = "bbb0e77b94b09193e6f32d5fac7a3b9c"

def check_rate_limit(response)
  if response.env[:response_headers]["x-ratelimit-remaining"].to_i < 10
    system('sleep 5')
  end
end

def get_now_playing(start_page_num)
  response = @conn.get do |req|
    req.url '3/movie/now_playing',:sensor => false

    req.params['page'] = start_page_num
    req.params['lanuguage'] = "en-US"
    req.params['region'] = "GR"
    req.params['api_key'] = "bbb0e77b94b09193e6f32d5fac7a3b9c"
  end
  check_rate_limit(response)
  response_data = JSON.parse(response.body)
  movie_array = []
  response_data["results"].each do |movie|
    movie_array << movie
  end
  if response_data["page"] == response_data["total_pages"]
    return movie_array
  else
    return movie_array + get_now_playing(response_data["page"].to_i + 1)
  end
end

def get_credits(id)
  response = @conn.get do |req|
    req.url "3/movie/#{id}/credits",:sensor => false
    req.params['api_key'] = @key
  end
  check_rate_limit(response)
  response_data = JSON.parse(response.body)
end

def get_person(id)
  response = @conn.get do |req|
    req.url "3/person/#{id}",:sensor => false
    req.params['language'] = "en-US"
    req.params['api_key'] = @key
  end
  check_rate_limit(response)
  response_data = JSON.parse(response.body)
end

all_the_data = get_now_playing(1)
all_the_data.each do |movie|
  director = []
  crew = get_credits(movie["id"])["crew"]

  crew.each do |person|
    if person["job"] == "Director"
      director << [person["id"], person["name"]]
    end
  end
  imdb_id = get_person(director.first.first)["imdb_id"]
  if imdb_id
    imdb_link = "www.imdb.com/name/#{imdb_id}"
  else
    imdb_link = 'Currently Unavailable'
  end


  db_connection do |conn|
    director_list = conn.exec(
    'SELECT name FROM directors'
    )
    unless director_list.any? { |dir| dir["name"] == director.first.last }
      conn.exec_params(
      'INSERT INTO directors (name, imdb_link) VALUES ($1, $2) RETURNING director_id AS dir_id', [director.first.last, imdb_link]
      )
    end
    dir_id = conn.exec(
    'SELECT director_id FROM directors'
    ).to_a
    conn.exec_params(
    'INSERT INTO movies (title, description, original_title, director_id) VALUES ($1, $2, $3, $4)', [movie["title"], movie["overview"], movie["original_title"], dir_id[-1]["director_id"]]
    )
  end
end
