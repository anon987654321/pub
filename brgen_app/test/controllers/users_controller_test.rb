require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get users_show_url
    assert_response :success
  end

  test "should get edit" do
    get users_edit_url
    assert_response :success
  end

  test "should get update" do
    get users_update_url
    assert_response :success
  end

  test "should get follow" do
    get users_follow_url
    assert_response :success
  end

  test "should get unfollow" do
    get users_unfollow_url
    assert_response :success
  end
end
