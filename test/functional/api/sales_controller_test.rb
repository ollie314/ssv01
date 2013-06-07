require 'test_helper'

class Api::SalesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get search" do
    get :search
    assert_response :success
  end

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

  test "should get cache" do
    get :cache
    assert_response :success
  end

  test "should get check" do
    get :check
    assert_response :success
  end

  test "should get sync" do
    get :sync
    assert_response :success
  end

  test "should get resync" do
    get :resync
    assert_response :success
  end

end
