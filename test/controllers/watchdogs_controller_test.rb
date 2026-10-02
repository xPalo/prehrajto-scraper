require "test_helper"

class WatchdogsControllerTest < ActionDispatch::IntegrationTest
  test "admin sees other users' watchdogs below their own, with owner emails" do
    sign_in users(:admin)

    get watchdogs_url

    assert_response :success
    assert_select "#own-watchdogs li", count: 1
    assert_select "#own-watchdogs", text: /BTS/
    assert_select "#other-watchdogs li", count: 2
    assert_select "#other-watchdogs", text: /alice@example\.com/
    assert_select "#other-watchdogs", text: /bob@example\.com/
    assert_operator response.body.index('id="own-watchdogs"'), :<, response.body.index('id="other-watchdogs"')
  end

  test "admin's own watchdogs are not repeated in the others section" do
    sign_in users(:admin)

    get watchdogs_url

    assert_select "#other-watchdogs li", count: 2
    assert_select "#other-watchdogs li", text: /BTS/, count: 0
  end

  test "admin without watchdogs of their own sees the empty state and the others section" do
    watchdogs(:admin_trip).destroy
    sign_in users(:admin)

    get watchdogs_url

    assert_select "#own-watchdogs", count: 0
    assert_match I18n.t("watchdog.empty_state"), response.body
    assert_select "#other-watchdogs li", count: 2
  end

  test "non-admin sees only their own watchdogs" do
    sign_in users(:alice)

    get watchdogs_url

    assert_response :success
    assert_select "#own-watchdogs li", count: 1
    assert_select "#other-watchdogs", count: 0
    assert_no_match(/KSC|bob@example\.com|admin@example\.com/, response.body)
  end

  test "admin index skips watchdogs whose owner no longer exists" do
    users(:bob).delete
    sign_in users(:admin)

    get watchdogs_url

    assert_response :success
    assert_select "#other-watchdogs li", count: 1
    assert_select "#other-watchdogs", text: /alice@example\.com/
  end

  test "admin updating another user's watchdog keeps that user as the owner" do
    sign_in users(:admin)

    RyanairAirportLoader.stub(:airports, []) do
      patch watchdog_url(watchdogs(:alice_trip)),
            params: { watchdog: { max_price: 99, user_id: users(:admin).id } }
    end

    watchdog = watchdogs(:alice_trip).reload
    assert_equal 99, watchdog.max_price
    assert_equal users(:alice), watchdog.user
  end

  test "user cannot move their watchdog to another user" do
    sign_in users(:alice)

    RyanairAirportLoader.stub(:airports, []) do
      patch watchdog_url(watchdogs(:alice_trip)), params: { watchdog: { user_id: users(:bob).id } }
    end

    assert_equal users(:alice), watchdogs(:alice_trip).reload.user
  end

  test "new watchdog belongs to the current user even if another user_id is submitted" do
    sign_in users(:alice)

    assert_difference -> { users(:alice).watchdogs.count }, 1 do
      RyanairAirportLoader.stub(:airports, []) do
        post watchdogs_url, params: { watchdog: { from_airport: "VIE", to_airport: "STN",
                                                  date_watch_from: "2026-12-01", date_watch_to: "2026-12-02",
                                                  user_id: users(:bob).id } }
      end
    end
    assert_equal 1, users(:bob).watchdogs.count
  end

  test "watchdog form does not expose the owner as a field" do
    sign_in users(:admin)

    RyanairAirportLoader.stub(:airports, []) do
      get edit_watchdog_url(watchdogs(:alice_trip))
    end

    assert_response :success
    assert_select "input[name='watchdog[user_id]']", count: 0
  end
end
