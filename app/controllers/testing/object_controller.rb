require 'securerandom'

class Testing::ObjectController < ApplicationController
  before_filter :check_for_format, :check_for_agency_id

  respond_to :xml, :json

  def index
    @object = JSON.parse(IO.read(File.dirname(__FILE__) + File::Separator + "samples" + File::Separator + "testing_sales_object.json"))
    request_id = SecureRandom.hex(32)
    session[:last_request_id] = request_id
    now = Time.new
    x = {}
    x["u_request_id"] = SecureRandom.hex(32)
    x["x_delta"] = "%.6f" % now.to_f
    @response = { :statusCode => 0, :statusMessage => "Success", :token => x, :content => { :object => @object } }
    respond_with @response
  end

  def summary
    @object = JSON.parse(IO.read(File.dirname(__FILE__) + File::Separator + "samples" + File::Separator + "testing_sales_object.json"))
    request_id = SecureRandom.hex(32)
    session[:last_request_id] = request_id
    now = Time.new
    x = {}
    x["u_request_id"] = SecureRandom.hex(32)
    x["x_delta"] = "%.6f" % now.to_f
    @response = { :statusCode => 0, :statusMessage => "Success", :token => x, :content => { :summary => @object["summary"] } }
    respond_with @response
  end

  def details
    @object = JSON.parse(IO.read(File.dirname(__FILE__) + File::Separator + "samples" + File::Separator + "testing_sales_object.json"))
    request_id = SecureRandom.hex(32)
    session[:last_request_id] = request_id
    now = Time.new
    x = {}
    x["u_request_id"] = SecureRandom.hex(32)
    x["x_delta"] = "%.6f" % now.to_f
    @response = { :statusCode => 0, :statusMessage => "Success", :token => x, :content => { :details => @object["details"] } }
    respond_with @response
  end

  def location
    @object = JSON.parse(IO.read(File.dirname(__FILE__) + File::Separator + "samples" + File::Separator + "testing_sales_object.json"))
    @info = {:address => @object["address"], :location => @object["location"]}
    request_id = SecureRandom.hex(32)
    session[:last_request_id] = request_id
    now = Time.new
    x = {}
    x["u_request_id"] = SecureRandom.hex(32)
    x["x_delta"] = "%.6f" % now.to_f
    @response = { :statusCode => 0, :statusMessage => "Success", :token => x, :content => { :location => @info } }
    respond_with @response
  end

  def pictures
    @object = JSON.parse(IO.read(File.dirname(__FILE__) + File::Separator + "samples" + File::Separator + "testing_sales_object.json"))
    kind_of_picture = 1
    @info = filter_for(@object["attachments"], kind_of_picture)
    request_id = SecureRandom.hex(32)
    session[:last_request_id] = request_id
    now = Time.new
    x = {}
    x["u_request_id"] = SecureRandom.hex(32)
    x["x_delta"] = "%.6f" % now.to_f
    @response = { :statusCode => 0, :statusMessage => "Success", :token => x, :content => { :pictures => @info } }
    respond_with @response
  end

  def videos
    @object = JSON.parse(IO.read(File.dirname(__FILE__) + File::Separator + "samples" + File::Separator + "testing_sales_object.json"))
    kind_of_video = 3
    @info = filter_for(@object["attachments"], kind_of_video)
    request_id = SecureRandom.hex(32)
    session[:last_request_id] = request_id
    now = Time.new
    x = {}
    x["u_request_id"] = SecureRandom.hex(32)
    x["x_delta"] = "%.6f" % now.to_f
    @response = { :statusCode => 0, :statusMessage => "Success", :token => x, :content => { :videos => @info } }
    respond_with @response
  end

  def pricing
    @response = { :statusCode => 1, :statusMessage => "Error", :token => x, :content => { :message => "Not available for now" } }
    respond_with @response
  end

  def availability
    @response = { :statusCode => 1, :statusMessage => "Error", :token => x, :content => { :location => "Not available for now" } }
    respond_with @response
  end

  private
  def filter_for(list, kind)
    results = []
    list.each { |item|
      results.push(item) if item["kind"] == kind
    }
    return results
  end
end
