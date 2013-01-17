class Admin::AgencyUsersController < ApplicationController
  # GET /admin/agency_users
  # GET /admin/agency_users.json
  def index
    @admin_agency_users = Admin::AgencyUser.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @admin_agency_users }
    end
  end

  # GET /admin/agency_users/1
  # GET /admin/agency_users/1.json
  def show
    @admin_agency_user = Admin::AgencyUser.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @admin_agency_user }
    end
  end

  # GET /admin/agency_users/new
  # GET /admin/agency_users/new.json
  def new
    @admin_agency_user = Admin::AgencyUser.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @admin_agency_user }
    end
  end

  # GET /admin/agency_users/1/edit
  def edit
    @admin_agency_user = Admin::AgencyUser.find(params[:id])
  end

  # POST /admin/agency_users
  # POST /admin/agency_users.json
  def create
    @admin_agency_user = Admin::AgencyUser.new(params[:admin_agency_user])

    respond_to do |format|
      if @admin_agency_user.save
        format.html { redirect_to @admin_agency_user, notice: 'Agency user was successfully created.' }
        format.json { render json: @admin_agency_user, status: :created, location: @admin_agency_user }
      else
        format.html { render action: "new" }
        format.json { render json: @admin_agency_user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /admin/agency_users/1
  # PUT /admin/agency_users/1.json
  def update
    @admin_agency_user = Admin::AgencyUser.find(params[:id])

    respond_to do |format|
      if @admin_agency_user.update_attributes(params[:admin_agency_user])
        format.html { redirect_to @admin_agency_user, notice: 'Agency user was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @admin_agency_user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/agency_users/1
  # DELETE /admin/agency_users/1.json
  def destroy
    @admin_agency_user = Admin::AgencyUser.find(params[:id])
    @admin_agency_user.destroy

    respond_to do |format|
      format.html { redirect_to admin_agency_users_url }
      format.json { head :no_content }
    end
  end
end
