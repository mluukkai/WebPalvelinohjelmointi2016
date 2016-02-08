json.array!(@beer_clubs) do |beer_club|
  json.extract! beer_club, :id, :name, :city, :founded
  json.url beer_club_url(beer_club, format: :json)
end
