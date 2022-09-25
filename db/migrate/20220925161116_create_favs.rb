class CreateFavs < ActiveRecord::Migration[7.0]
  def change
    create_table :favs do |t|
      t.string :title
      t.string :duration
      t.string :size
      t.string :link

      t.timestamps
    end
  end
end
