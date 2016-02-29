class Style < ActiveRecord::Base
  include RatingAverage

  has_many :beers
  has_many :ratings, through: :beers

  def self.top(n)
    sorted_by_rating_average = Style.all.sort_by{ |b| -(b.average_rating || 0) }
    sorted_by_rating_average[0, n]
  end
end
