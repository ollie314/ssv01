class Api::AccountController < ApplicationController
  before_filter :check_for_format, :check_for_agency_id

  respond_to :xml, :json

  # show the list of accessible accounts by the current account.
  def list
  end

  # view the summary of the account
  def summary
    view
  end

  # view details of the agency.
  def view
    @agency = Agency.find(params[:id])
    @response = { :statusCode => 0, :statusMessage => "Success", :content => { :agency => @agency } }
    logger.debug "This is a simple message from the logger placed in the view template"
    logger.debug @response
    respond_with @response
  end
-
  # show all supported languages supported by the account.
  def languages
  end

  # show the kind of the account
  def kind
  end

  # show stat for the account
  def trends
  end

end
