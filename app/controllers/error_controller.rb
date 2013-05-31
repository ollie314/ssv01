class ErrorController < ApplicationController

  def page_not_found
    render :file => 'public/404_v2', :status => 404, :layout => true
  end
end
