require 'test_helper'

class RentalsControllerTest < ActionController::TestCase
  test "should get list" do
    get :list
    assert_response :success
  end

  test "should get search" do
    get :search
    assert_response :success
  end

  test "should get object_summary" do
    get :object_summary
    assert_response :success
  end

  test "should get object_details" do
    get :object_details
    assert_response :success
  end

  test "should get object_pictures" do
    get :object_pictures
    assert_response :success
  end

  test "should get object_location" do
    get :object_location
    assert_response :success
  end

  test "should get object_pricing" do
    get :object_pricing
    assert_response :success
  end

  test "should get object_video" do
    get :object_video
    assert_response :success
  end

  test "should get object_availability" do
    get :object_availability
    assert_response :success
  end

end
