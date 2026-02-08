class AddRecordedAtToVideos < ActiveRecord::Migration[7.0]
  def change
    add_column :videos, :recorded_at, :datetime
  end
end
