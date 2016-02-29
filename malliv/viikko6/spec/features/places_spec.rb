require 'rails_helper'

describe "Places" do
  it "if one is returned by the API, it is shown at the page" do
    allow(BeermappingApi).to receive(:places_in).with("kumpula").and_return(
      [ Place.new( name:"Oljenkorsi", id: 1 ) ]
    )

    visit places_path
    fill_in('city', with: 'kumpula')
    click_button "Search"

    expect(page).to have_content "Oljenkorsi"
  end

  it "if many are returned by the API, all are shown at the page" do
    allow(BeermappingApi).to receive(:places_in).with("eira").and_return(
      [
        Place.new( name:"Brewdog", id: 1 ),
        Place.new( name:"Black Door", id: 2 ),
        Place.new( name:"Tommy Knocker", id: 3 )
      ]
    )

    visit places_path
    fill_in('city', with: 'eira')
    click_button "Search"

    expect(page).to have_content "Brewdog"
    expect(page).to have_content "Black Door"
    expect(page).to have_content "Tommy Knocker"
  end

  it "if none is returned by the API, user is informed" do
    allow(BeermappingApi).to receive(:places_in).with("käpylä").and_return(
      [ ]
    )

    visit places_path
    fill_in('city', with: 'käpylä')
    click_button "Search"

    expect(page).to have_content "No locations in käpylä"
  end
end