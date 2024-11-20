require "test_helper"

class User::MachinesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get user_machines_index_url
    assert_response :success
  end

  test "should get show" do
    get user_machines_show_url
    assert_response :success
  end
end
