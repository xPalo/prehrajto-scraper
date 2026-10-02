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

  test "admin editing another user's watchdog keeps that user as the owner" do
    sign_in users(:admin)

    RyanairAirportLoader.stub(:airports, []) do
      get edit_watchdog_url(watchdogs(:alice_trip))
    end

    assert_select "input[type=hidden][name='watchdog[user_id]'][value=?]", users(:alice).id.to_s
  end

  test "new watchdog form assigns the current user as the owner" do
    sign_in users(:alice)

    RyanairAirportLoader.stub(:airports, []) do
      get new_watchdog_url
    end

    assert_select "input[type=hidden][name='watchdog[user_id]'][value=?]", users(:alice).id.to_s
  end
end
