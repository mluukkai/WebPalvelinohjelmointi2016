require 'test_helper'

class BeerClubsControllerTest < ActionController::TestCase
  setup do
    @beer_club = beer_clubs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:beer_clubs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create beer_club" do
    assert_difference('BeerClub.count') do
      post :create, beer_club: { city: @beer_club.city, founded: @beer_club.founded, name: @beer_club.name }
    end

    assert_redirected_to beer_club_path(assigns(:beer_club))
  end

  test "should show beer_club" do
    get :show, id: @beer_club
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @beer_club
    assert_response :success
  end

  test "should update beer_club" do
    patch :update, id: @beer_club, beer_club: { city: @beer_club.city, founded: @beer_club.founded, name: @beer_club.name }
    assert_redirected_to beer_club_path(assigns(:beer_club))
  end

  test "should destroy beer_club" do
    assert_difference('BeerClub.count', -1) do
      delete :destroy, id: @beer_club
    end

    assert_redirected_to beer_clubs_path
  end
end
