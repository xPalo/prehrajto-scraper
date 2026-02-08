class CreateVideos < ActiveRecord::Migration[7.0]
  def change
    create_table :videos do |t|
      t.references :user, null: false, foreign_key: true
      t.string :original_filename, null: false
      t.integer :status, default: 0, null: false
      t.string :error_message
      t.bigint :file_size
      t.float :duration
      t.timestamps
    end

    add_index :videos, [:user_id, :created_at]
  end
end
