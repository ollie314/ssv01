class ErrorController < ApplicationController

  def page_not_found
    respond_to do |format|
      format.html {render :file => 'public/404_v2', :status => 404, :layout => true}
      format.xml {render :file => 'public/404.xml', :status => 404}
      format.json {render :json =>{}, :status => 404}
    end
  end
end
