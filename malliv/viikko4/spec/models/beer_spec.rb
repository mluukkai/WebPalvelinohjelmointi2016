require 'rails_helper'

RSpec.describe Beer, type: :model do
  it "is created if proper name and style set" do
    beer = Beer.create name:"iso 3", style: "lager"

      expect(beer).to be_valid
      expect(Beer.count).to eq(1)
  end

  it "is not created if no name set" do
    beer = Beer.create style: "lager"

      expect(beer).not_to be_valid
      expect(Beer.count).to eq(0)
  end

  it "is not created if no style set" do
    beer = Beer.create name:"iso 3"

      expect(beer).not_to be_valid
      expect(Beer.count).to eq(0)
  end
end
