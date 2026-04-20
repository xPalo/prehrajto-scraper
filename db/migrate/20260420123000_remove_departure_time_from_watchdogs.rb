class RemoveDepartureTimeFromWatchdogs < ActiveRecord::Migration[7.0]
  def change
    remove_column :watchdogs, :departure_time_from, :string
    remove_column :watchdogs, :departure_time_to, :string
  end
end
