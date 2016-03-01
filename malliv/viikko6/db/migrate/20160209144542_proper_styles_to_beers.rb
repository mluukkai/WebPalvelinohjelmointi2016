class ProperStylesToBeers < ActiveRecord::Migration
  def change
    add_column :beers, :style_id, :integer
    rename_column :beers, :style, :old_style

    Beer.all.map(&:old_style).uniq.each do |name|
      Style.create name:name
    end

    Beer.all.each do |beer|
      style = Style.find_by name: beer.old_style
      beer.style_id = style.id

      beer.save
    end

    remove_column :beers, :old_style
  end
end
