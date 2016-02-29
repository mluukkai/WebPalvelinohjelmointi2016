class AddAccountStatusToUser < ActiveRecord::Migration
  def change
    add_column :users, :locked, :boolean
  end
end
