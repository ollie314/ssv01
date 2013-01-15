require 'test_helper'

class OauthControllerTest < ActionController::TestCase
  test "should get authorize" do
    get :authorize
    assert_response :success
  end

  test "should get request_token" do
    get :request_token
    assert_response :success
  end

  test "should get access_token" do
    get :access_token
    assert_response :success
  end

  test "should get authenticate" do
    get :authenticate
    assert_response :success
  end

end
