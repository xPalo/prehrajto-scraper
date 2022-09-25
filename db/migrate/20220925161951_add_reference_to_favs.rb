class AddReferenceToFavs < ActiveRecord::Migration[7.0]
  def change
    add_column :favs, :user_id, :integer
    add_foreign_key :favs, :users
  end
end
