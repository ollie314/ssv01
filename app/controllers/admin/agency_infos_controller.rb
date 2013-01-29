class Admin::AgencyInfosController < ApplicationController
  def show
    @agency = Admin::Agency.find(params[:id])
    @response = {:statusCode => 0, :statusMessage => "Success", :content => { :agency => @agency, :info => @agency.agency_info } }
    respond_to do |format|
      format.html
      format.json { render json: @response }
    end
  end

  def edit
    #Fetch information and send it back to the client.
    #TODO For now, load all information (means agency and agency_info). May interesting to load certain data only ...
    show
  end

  def delete
    @agency = Admin::Agency.find(params[:id])
    # not implemented
    @response = {:statusCode => 2, :statusMessage => "Not Implemented", :content => { :message => "Operation not allowed yet" }}
    respond_to do |format|
        format.html { redirect_to @agency, notice: @response.content.message }
        format.json { render json: @response }
    end
  end

  def update
    @agency = Admin::Agency.find(params[:id])
    @info = AgencyInfo.find_by_agency_id(params[:id])
    summary = params[:summary]
    description = params[:description]
    to_update = {}
    if summary != info.summary
      to_update[:summary] = summary
    end
    if description != info.description
      to_update[:description] = description
    end

    respond_to do |format|
      if @info.update_attributes(to_update)
        format.html { redirect_to @agency, notice: 'Agency was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { redirect_to @agency, notice: 'Information have not been updated due to error' }
        format.json { render json: @agency.errors, status: :unprocessable_entity }
      end
    end

  end

  def fetch
    @agency_info = AgencyInfo.find_by_agency_id(params[:id])
    @response = {:statusCode => 0, :statusMessage => "Success", :content => { :info => @agency_info } }
    respond_to do |format|
      format.html
      format.json { render json: @response }
    end
  end
end
