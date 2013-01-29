class Admin::HomeController < ApplicationController

  respond_to :xml, :json

  def index

  end

  def home
    @objects = load_data
    #@response = { :statusCode => 0, :statusMessage => "Success", :token => x, :content => { :objects => @objects } }
    respond_with @objects
  end

  private
  def load_data
    @objects = JSON.parse(IO.read(File.dirname(__FILE__) + File::Separator + "samples" + File::Separator + "data.json"))
  end
end
