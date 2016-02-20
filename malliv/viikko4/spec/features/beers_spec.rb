require 'rails_helper'

include Helpers

describe "Beer" do
  before :each do
    FactoryGirl.create :brewery, name:"testbrew"
  end

  describe "if a user logged in" do
    before :each do
      FactoryGirl.create :user
      sign_in(username:"Pekka", password:"Foobar1")
    end

    it "a new beer is created if a valid name specified" do
      visit new_beer_path
      fill_in('beer_name', with:'CrapIPA')
      select('Lager', from:'beer[style]')
      expect{
        click_button "Create Beer"
      }.to change{Beer.count}.from(0).to(1)
    end

    it "is not created if name not valid" do
      visit new_beer_path
      click_button "Create Beer"
      expect(Beer.count).to be(0)
      expect(page).to have_content 'prohibited this beer from being saved'
      expect(page).to have_content "Name can't be blank"
    end

  end

end
