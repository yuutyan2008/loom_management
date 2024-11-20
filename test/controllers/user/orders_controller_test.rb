require "test_helper"

class User::OrdersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get user_orders_index_url
    assert_response :success
  end

  test "should get show" do
    get user_orders_show_url
    assert_response :success
  end

  test "should get edit" do
    get user_orders_edit_url
    assert_response :success
  end

  test "should get update" do
    get user_orders_update_url
    assert_response :success
  end
end
