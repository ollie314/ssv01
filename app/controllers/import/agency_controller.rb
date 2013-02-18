require 'citi/citi_soap_loader'
require 'uploads/fs'

class Import::AgencyController < ApplicationController

  respond_to :xml, :json, :html

  def fill_agency_info
    # TODO : add this part to the configuration settings
    channel_id = 3
    username = "CITI_COURTAGE_PERSO"
    password = "LetMeIn_Now_Courtage_Perso"

    connection = CitiSoapLoader::Connection.new
    session_id = connection.connect(channel_id, username, password)
    agency_id = params[:agency_id]
    cache = CitiSoapLoader::Cache.new(agency_id, "sales")

    loader = CitiSoapLoader::Sales.new(session_id, params[:agency_id])
    object_list = loader.load_list
    if object_list.nil?
      @response = {:statusCode => 0, :statusMessage => "Success", :content => {:agency_id => agency_id, :nb_objects => 0}}
    else
      object_list[:object_courtage_simple].each { |p|
        object_detail = loader.load_detail(p[:object_id])
        cache.store(object_detail[:object_courtage][:object_id], 'json', object_detail[:object_courtage])
      }
      @response = {:statusCode => 0, :statusMessage => "Success", :content => {:agency_id => agency_id, :nb_objects => object_list[:object_courtage_simple].count}}
    end
    respond_with @response
  end

  def load_agency_info

    # TODO : add this part to the configuration settings
    channel_id = 3
    username = "CITI_COURTAGE_PERSO"
    password = "LetMeIn_Now_Courtage_Perso"
    agency_id = params[:agency_id]
    connection = CitiSoapLoader::Connection.new
    session_id = connection.connect(channel_id, username, password)

    cache = CitiSoapLoader::Cache.new(agency_id, "sales")

    loader = CitiSoapLoader::Sales.new(session_id, agency_id)
    object_list = loader.load_list
    cache.store('list', 'json', object_list[:object_courtage_simple])
    @response = {:statusCode => 0, :statusMessage => "Success", :content => {:agency_id => agency_id, :objects => object_list}}
    respond_with @response
  end

  def check
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
end
