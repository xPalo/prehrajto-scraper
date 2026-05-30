class AddOtpToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :otp_code_digest, :string
    add_column :users, :otp_sent_at, :datetime
  end
end
