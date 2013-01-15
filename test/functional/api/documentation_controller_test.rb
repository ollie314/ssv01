require 'test_helper'

class Api::DocumentationControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get list" do
    get :list
    assert_response :success
  end

  test "should get resources" do
    get :resources
    assert_response :success
  end

  test "should get streams" do
    get :streams
    assert_response :success
  end

end
