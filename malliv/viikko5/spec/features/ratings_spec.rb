require 'rails_helper'

include Helpers

describe "Ratings" do
  let!(:brewery) { FactoryGirl.create :brewery, name:"Koff" }
  let!(:beer1) { FactoryGirl.create :beer, name:"iso 3", brewery:brewery }
  let!(:beer2) { FactoryGirl.create :beer, name:"Karhu", brewery:brewery }
  let!(:user) { FactoryGirl.create :user }

  before :each do
    sign_in(username:"Pekka", password:"Foobar1")
  end

  it "when created, is registered to the beer and user who is signed in" do
    visit new_rating_path
    select('iso 3', from:'rating[beer_id]')
    fill_in('rating[score]', with:'15')

    expect{
      click_button "Create Rating"
    }.to change{Rating.count}.from(0).to(1)

    expect(user.ratings.count).to eq(1)
    expect(beer1.ratings.count).to eq(1)
    expect(beer1.average_rating).to eq(15.0)
  end

  describe "when some are given" do
    before :each do
      FactoryGirl.create :rating, user: user, beer: beer1, score:10
      FactoryGirl.create :rating, user: user, beer: beer2, score:20
      FactoryGirl.create :rating, user: user, beer: beer2, score:30
    end

    it "those and their count are shown at the ratings page" do
      visit ratings_path
      expect(page).to have_content "Number of ratings 3"
      expect(page).to have_content "iso 3 10"
      expect(page).to have_content "Karhu 20"
      expect(page).to have_content "Karhu 20"
    end

    it "are shown on raters page" do
      arto = FactoryGirl.create :user, username: "arto"
      FactoryGirl.create :rating, user: arto, beer: beer1, score:40

      visit user_path(user)
      expect(page).to have_content "iso 3 10"
      expect(page).to have_content "Karhu 20"
      expect(page).to have_content "Karhu 20"
      expect(page).not_to have_content "iso 3 40"
    end

    it "and the rater deletes one, it is removed from database" do
      visit user_path(user)
      expect{
        page.all('a', text:'delete')[1].click
      }.to change{Rating.count}.by(-1)
    end
  end


end