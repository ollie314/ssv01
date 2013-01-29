require 'uploads/fs'

class Admin::AgenciesController < ApplicationController

  layout "admin_agency"

  # GET /admin/agencies
  # GET /admin/agencies.json
  def index
    @admin_agencies = Admin::Agency.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @admin_agencies }
    end
  end

  # GET /admin/agencies/1
  # GET /admin/agencies/1.json
  def show
    @admin_agency = Admin::Agency.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @admin_agency }
    end
  end

  # GET /admin/agencies/new
  # GET /admin/agencies/new.json
  def new
    @admin_agency = Admin::Agency.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @admin_agency }
    end
  end

  # GET /admin/agencies/1/edit
  def edit
    @admin_agency = Admin::Agency.find(params[:id])

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @admin_agency }
    end
  end

  # POST /admin/agencies
  # POST /admin/agencies.json
  def create
    process_succeed = false
    agency_info = { :name => params[:admin_agency][:name], :website => params[:admin_agency][:website], :mail => params[:admin_agency][:mail], :phone => params[:admin_agency][:phone], :info => params[:admin_agency][:info]}

    @admin_agency = Admin::Agency.new(agency_info)

    if @admin_agency.save
      begin
        agency_root_path =  Uploads::Fs.create_agency_dir(@admin_agency)
        logo = Uploads::Fs.write_on_fs(params[:admin_agency][:logo], @admin_agency, agency_root_path)
        if @admin_agency.update_attributes({:logo => logo})
          process_succeed = true
          message = "Agency %s successfully complete" % [agency_info[:name]]
        else
          message = "Error during defining the logo for the agency"
        end

      rescue IOError => error
        message = "Cannot save logo into the path [%s]" % [error.message]
      end
    else
      message = "Cannot save agency information"
    end

    respond_to do |format|
      if process_succeed
        format.html { redirect_to @admin_agency, notice: message }
        format.json { render json: @admin_agency, status: :created, location: @admin_agency }
      else
        format.html { render action: "new" }
        format.json { render json: @admin_agency.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /admin/agencies/1
  # PUT /admin/agencies/1.json
  def update
    @admin_agency = Admin::Agency.find(params[:id])

    respond_to do |format|
      if @admin_agency.update_attributes(params[:admin_agency])
        format.html { redirect_to @admin_agency, notice: 'Agency was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @admin_agency.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/agencies/1
  # DELETE /admin/agencies/1.json
  def destroy
    @admin_agency = Admin::Agency.find(params[:id])
    @admin_agency.destroy

    respond_to do |format|
      format.html { redirect_to admin_agencies_url }
      format.json { head :no_content }
    end
  end
end
