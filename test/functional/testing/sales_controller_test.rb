require 'test_helper'

class Testing::SalesControllerTest < ActionController::TestCase
  test "should get list" do
    get :list
    assert_response :success
  end

  test "should get seach" do
    get :seach
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

  test "should get object_location" do
    get :object_location
    assert_response :success
  end

  test "should get object_pictures" do
    get :object_pictures
    assert_response :success
  end

  test "should get object_video" do
    get :object_video
    assert_response :success
  end

end
