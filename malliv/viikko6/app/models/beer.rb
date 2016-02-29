class Beer < ActiveRecord::Base
  include RatingAverage

  validates :name, presence: true
  validates :style, presence: true

  belongs_to :brewery
  belongs_to :style
  has_many :ratings, dependent: :destroy
  has_many :raters, -> { uniq }, through: :ratings, source: :user

  def self.top(n)
    sorted_by_rating_average = Beer.all.sort_by{ |b| -(b.average_rating || 0) }
    sorted_by_rating_average[0, n]
  end

  def to_s
    "#{name} #{brewery.name}"
  end
end
