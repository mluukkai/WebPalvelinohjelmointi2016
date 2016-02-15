require 'rails_helper'

include Helpers

describe "User" do
  let!(:user) { FactoryGirl.create :user }

  describe "who has signed up" do
    it "can signin with right credentials" do
      visit signin_path
      fill_in('username', with:'Pekka')
      fill_in('password', with:'Foobar1')
      click_button('Log in')

      expect(page).to have_content 'Welcome back!'
      expect(page).to have_content 'Pekka'
    end

    it "is redirected back to signin form if wrong credentials given" do
      sign_in(username:"Pekka", password:"wrong")

      expect(current_path).to eq(signin_path)
      expect(page).to have_content 'Username and/or password mismatch'
    end
  end

  it "when signed up with good credentials, is added to the system" do
    visit signup_path
    fill_in('user_username', with:'Brian')
    fill_in('user_password', with:'Secret55')
    fill_in('user_password_confirmation', with:'Secret55')

    expect{
      click_button('Create User')
    }.to change{User.count}.by(1)
  end

  describe "have rated some beers" do
    before :each do
      @brewery = FactoryGirl.create :brewery, name:"Sierra Nevada"
      other_brewery = FactoryGirl.create :brewery
      create_beers_with_ratings(user, "lager", other_brewery, 10, 20, 15)
      create_beers_with_ratings(user, "IPA", @brewery, 25, 20)
      create_beers_with_ratings(user, "stout", other_brewery, 20, 23, 22)
    end

    it "the favorite style is shown at user's page" do
      visit user_path(user)
      expect(page).to have_content 'Favorite style IPA'
    end

    it "the favorite brewery is shown at user's page" do
      visit user_path(user)
      expect(page).to have_content 'Favorite brewery Sierra Nevada'
    end

  end
end