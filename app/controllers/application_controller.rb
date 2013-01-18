class ApplicationController < ActionController::Base
  protect_from_forgery

  # private methods
  protected

  # check about the validity of the format of the content to send back. Restrict html
  def check_for_format
    if params[:format].nil? or
        params[:format] == 'html'
      render :template => "shared/error_404/message", :layout => "application", :status => "404 Not Found"
    end
  end

  # check about the presence of the agency_id. If not exists, the request is considered as not valid.
  def check_for_agency_id
    @agency_id = params[:id]
    if @agency_id.nil?
      @agency_id = params[:agency_id]
      if @agency_id.nil?
        @response = { :statusCode => 1, :statusMessage => "No agency id defined", :content => nil }
        respond_with @response
      end
    else
      # fetch information for the agency
      @agency = Agency.find(@agency_id)
      if @agency.nil?
        @response = { :statusCode => 1, :statusMessage => "Agency not found", :content => nil }
        respond_with @response
      end
    end
  end
end
