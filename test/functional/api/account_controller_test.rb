require 'test_helper'

class Api::AccountControllerTest < ActionController::TestCase
  test "should get list" do
    get :list
    assert_response :success
  end

  test "should get summary" do
    get :summary
    assert_response :success
  end

  test "should get view" do
    get :view
    assert_response :success
  end

  test "should get languages" do
    get :languages
    assert_response :success
  end

  test "should get kind" do
    get :kind
    assert_response :success
  end

  test "should get trends" do
    get :trends
    assert_response :success
  end

end
