require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "destroying a user destroys their watchdogs" do
    watchdog = watchdogs(:bob_trip)

    users(:bob).destroy

    assert_not Watchdog.exists?(watchdog.id)
  end
end
