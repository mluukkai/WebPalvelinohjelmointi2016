class Rating < ActiveRecord::Base
  belongs_to :beer

  def to_s
    "#{beer.name} #{score}"
  end
end
