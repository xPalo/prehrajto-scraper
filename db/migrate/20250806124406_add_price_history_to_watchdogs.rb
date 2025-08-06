class AddPriceHistoryToWatchdogs < ActiveRecord::Migration[7.0]
  def change
    add_column :watchdogs, :price_history, :jsonb, default: [], null: false
  end
end
