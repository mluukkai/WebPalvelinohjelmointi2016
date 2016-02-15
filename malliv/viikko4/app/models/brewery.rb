class Brewery < ActiveRecord::Base
  include RatingAverage

  validates :name, presence: true
  validates :year, numericality: { less_than_or_equal_to: Proc.new { Time.now.year } }

  has_many :beers, dependent: :destroy
  has_many :ratings, through: :beers
end