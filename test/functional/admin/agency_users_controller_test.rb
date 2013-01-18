require 'test_helper'

class Admin::AgencyUsersControllerTest < ActionController::TestCase
  setup do
    @admin_agency_user = admin_agency_users(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:admin_agency_users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create admin_agency_user" do
    assert_difference('Admin::AgencyUser.count') do
      post :create, admin_agency_user: { email: @admin_agency_user.email, firstname: @admin_agency_user.firstname, lastname: @admin_agency_user.lastname, password: @admin_agency_user.password, rights: @admin_agency_user.rights }
    end

    assert_redirected_to admin_agency_user_path(assigns(:admin_agency_user))
  end

  test "should show admin_agency_user" do
    get :show, id: @admin_agency_user
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @admin_agency_user
    assert_response :success
  end

  test "should update admin_agency_user" do
    put :update, id: @admin_agency_user, admin_agency_user: { email: @admin_agency_user.email, firstname: @admin_agency_user.firstname, lastname: @admin_agency_user.lastname, password: @admin_agency_user.password, rights: @admin_agency_user.rights }
    assert_redirected_to admin_agency_user_path(assigns(:admin_agency_user))
  end

  test "should destroy admin_agency_user" do
    assert_difference('Admin::AgencyUser.count', -1) do
      delete :destroy, id: @admin_agency_user
    end

    assert_redirected_to admin_agency_users_path
  end
end
