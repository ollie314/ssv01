require 'test_helper'

class Documentation::HomesControllerTest < ActionController::TestCase
  setup do
    @documentation_home = documentation_homes(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:documentation_homes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create documentation_home" do
    assert_difference('Documentation::Home.count') do
      post :create, documentation_home: {  }
    end

    assert_redirected_to documentation_home_path(assigns(:documentation_home))
  end

  test "should show documentation_home" do
    get :show, id: @documentation_home
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @documentation_home
    assert_response :success
  end

  test "should update documentation_home" do
    put :update, id: @documentation_home, documentation_home: {  }
    assert_redirected_to documentation_home_path(assigns(:documentation_home))
  end

  test "should destroy documentation_home" do
    assert_difference('Documentation::Home.count', -1) do
      delete :destroy, id: @documentation_home
    end

    assert_redirected_to documentation_homes_path
  end
end
