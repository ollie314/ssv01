require 'securerandom'

class Testing::SalesController < ApplicationController
  before_filter :check_for_format, :check_for_agency_id

  respond_to :xml, :json

  def list
    request_id = SecureRandom.hex(32)
    session[:last_request_id] = request_id
    @objects = load_objects
    now = Time.new
    x = {}
    x["u_request_id"] = SecureRandom.hex(32)
    x["x_delta"] = "%.6f" % now.to_f
    @response = { :statusCode => 0, :statusMessage => "Success", :token => x, :content => { :objects => @objects } }
    respond_with @response
  end

  def search
    price_sensitivity = !(params[:min_price].nil? and params[:max_price].nil?)
    min_price = !params[:min_price].nil? ? Float(params[Carri:min_price]) : 0
    max_price = !params[:max_price].nil? ? Float(params[:max_price]) : 999999999

    nb_rooms_sensitivity = !(params[:nb_rooms_min].nil? and params[:nb_rooms_max].nil?)
    nb_rooms_min = !params[:nb_rooms_min].nil? ? Integer(params[:nb_rooms_min]) : 0
    nb_rooms_max = !params[:nb_rooms_max].nil? ? Integer(params[:nb_rooms_max]) : 999

    @objects = load_objects
    @results = []
    @objects.each { |obj|
      if price_sensitivity and !(obj["price"] >= min_price and obj["price"] <= max_price)
        next
      end
      if nb_rooms_sensitivity and !(obj["nb_rooms"] >= nb_rooms_min and obj["nb_rooms"] <= nb_rooms_max)
        next
      end
      @results.push(obj)
    }

    @response = { :statusCode => 0, :statusMessage => "Success", :content => { :objects => @results } }
    respond_with @response
  end

  private

  def load_objects
    @objects = JSON.parse(IO.read(File.dirname(__FILE__) + File::Separator + "samples" + File::Separator + "testing_sales.list.json"))
  end

end
