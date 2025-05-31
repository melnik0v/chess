require "test_helper"

class Api::V1::ProtectedControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_protected_index_url
    assert_response :success
  end
end
