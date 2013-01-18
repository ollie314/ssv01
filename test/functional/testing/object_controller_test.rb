require 'test_helper'

class Testing::ObjectControllerTest < ActionController::TestCase
  test "should get summary" do
    get :summary
    assert_response :success
  end

  test "should get details" do
    get :details
    assert_response :success
  end

  test "should get location" do
    get :location
    assert_response :success
  end

  test "should get pictures" do
    get :pictures
    assert_response :success
  end

  test "should get videos" do
    get :videos
    assert_response :success
  end

  test "should get princing" do
    get :princing
    assert_response :success
  end

  test "should get availability" do
    get :availability
    assert_response :success
  end

end
