class AddWatchdog < ActiveRecord::Migration[7.0]
  def change
    create_table :watchdogs do |t|
      t.string :from_airport, null: false
      t.string :to_airport
      t.string :to_country
      t.integer :max_price
      t.date :date_watch_from
      t.date :date_watch_to
      t.string :departure_time_from
      t.string :departure_time_to
      t.references :user, null: false
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end
  end
end
