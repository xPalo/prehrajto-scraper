class AddImageSrcToFavs < ActiveRecord::Migration[7.0]
  def change
    add_column :favs, :image_src, :string
  end
end
