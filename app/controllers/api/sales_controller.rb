require 'citi/citi_soap_loader'
require 'uploads/fs'

class Api::SalesController < ApplicationController

  before_filter :check_for_format, :check_for_agency_id

  respond_to :xml, :json, :html

  def index
    details
  end

  def list
    agency_id = params[:agency_id]

    path = Uploads::Fs.get_cache_dir.join(String(agency_id), 'sales')
    filename = path.to_s + "/list.json"
    if File.exists? filename
      obj = JSON.parse(IO.read(filename))
      logger.debug("Filename is %s" % [obj])
      translator = CitiSoapLoader::Translator.new
      objs = []
      obj.each{ |item|
        objs.push translator.translate_for_list item
      }
      @response = {:statusCode => 0, :statusMessage => "Success", :content => {:agency_id => agency_id, :object => objs}}
    else
      @response = {:statusCode => 1, :statusMessage => "Error", :content => {:error_info => "File not exists"}}
    end
    respond_with @response
  end

  def search
    agency_id = params[:agency_id]
    translator = CitiSoapLoader::Translator.new

    price_sensitivity = !(params[:min_price].nil? and params[:max_price].nil?)
    min_price = !params[:min_price].nil? ? Float(params[:min_price]) : 0
    max_price = !params[:max_price].nil? ? Float(params[:max_price]) : 999999999

    nb_rooms_sensitivity = !(params[:nb_rooms_min].nil? and params[:nb_rooms_max].nil?)
    nb_rooms_min = !params[:nb_rooms_min].nil? ? Integer(params[:nb_rooms_min]) : 0
    nb_rooms_max = !params[:nb_rooms_max].nil? ? Integer(params[:nb_rooms_max]) : 999

    @objects = load_objects agency_id
    @results = []
    @objects.each { |obj|
      if price_sensitivity and !(obj["price"] >= min_price and obj["price"] <= max_price)
        next
      end
      if nb_rooms_sensitivity and !(obj["nb_rooms"] >= nb_rooms_min and obj["nb_rooms"] <= nb_rooms_max)
        next
      end
      obj_translated = translator.translate_for_list obj
      @results.push(obj_translated)
    }

    @response = { :statusCode => 0, :statusMessage => "Success", :content => { :objects => @results } }
    respond_with @response
  end

  def summary
    agency_id = params[:agency_id]
    object_id = params[:object_id]

    path = Uploads::Fs.get_cache_dir.join(agency_id, 'sales')
    filename = path.to_s + "/" + object_id + ".json"
    if File.exists? filename
      obj = JSON.parse(IO.read(filename))
      translator = CitiSoapLoader::Translator.new
      obj_translated = translator.translate_for_summary obj
      @response = {:statusCode => 0, :statusMessage => "Success", :content => {:agency_id => agency_id, :object => obj_translated}}
    else
      @response = {:statusCode => 1, :statusMessage => "Error", :content => {:error_info => "File not exists"}}
    end
    respond_with @response
  end

  def details
    object_id = params[:object_id]
    agency_id = params[:agency_id]

    path = Uploads::Fs.get_cache_dir.join(agency_id, 'sales')
    filename = path.to_s + "/" + object_id + ".json"
    if File.exists? filename
      obj = JSON.parse(IO.read(filename))
      translator = CitiSoapLoader::Translator.new
      obj_translated = translator.translate_for_details obj
      @response = {:statusCode => 0, :statusMessage => "Success", :content => {:agency_id => agency_id, :object => obj_translated}}
    else
      @response = {:statusCode => 1, :statusMessage => "Error", :content => {:error_info => "File not exists"}}
    end
    respond_with @response
  end

  def location
  end

  def pictures
  end

  def videos
  end

  def cache
  end

  def check
  end

  def sync
  end

  def resync
    sync
  end

  private

  def load_objects(agency_id)
    path = Uploads::Fs.get_cache_dir.join(agency_id, 'sales')
    filename = path.to_s + "/list.json"
    @objects = JSON.parse(IO.read(filename))
  end

end
