require 'test_helper'

class Import::AgencyControllerTest < ActionController::TestCase
  test "should get load" do
    get :load
    assert_response :success
  end

  test "should get check" do
    get :check
    assert_response :success
  end

end
