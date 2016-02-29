class AddActivityToBrewery < ActiveRecord::Migration
  def change
    add_column :breweries, :active, :boolean
  end
end
