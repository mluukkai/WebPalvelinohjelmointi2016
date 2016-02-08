module RatingAverage
  extend ActiveSupport::Concern

  def average_rating
    ratings.inject(0.0){ |sum, r| sum+r.score } / ratings.count
  end
end