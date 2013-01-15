require 'test_helper'

class HelpControllerTest < ActionController::TestCase
  test "should get configuration" do
    get :configuration
    assert_response :success
  end

  test "should get languages" do
    get :languages
    assert_response :success
  end

  test "should get privacy" do
    get :privacy
    assert_response :success
  end

  test "should get term_of_service" do
    get :term_of_service
    assert_response :success
  end

  test "should get tos" do
    get :tos
    assert_response :success
  end

  test "should get term_of_use" do
    get :term_of_use
    assert_response :success
  end

  test "should get tou" do
    get :tou
    assert_response :success
  end

end
