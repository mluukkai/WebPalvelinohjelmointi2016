class RatingsController < ApplicationController
  def index
    @recent = Rating.recent
    @beers = Beer.top(3)
    @styles = Style.top(3)
    @breweries = Brewery.top(3)
    @users = User.top(4)
  end

  def new
    @rating = Rating.new
    @beers = Beer.all
  end

  def create
    @rating = Rating.new params.require(:rating).permit(:score, :beer_id)

    if @rating.save
      current_user.ratings << @rating
      redirect_to user_path current_user
    else
      @beers = Beer.all
      render :new
    end
  end

  def destroy
    rating = Rating.find(params[:id])
    rating.delete if current_user == rating.user
    redirect_to :back
  end
end