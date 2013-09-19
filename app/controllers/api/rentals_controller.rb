require 'citi/citi_soap_loader'
require 'uploads/fs'

class Api::RentalsController < ApplicationController

  before_filter :check_for_format, :check_for_agency_id

  respond_to :xml, :json, :html

  DEFAULT_LANG = 'fr'

  def list
    #agency_id = params[:agency_id]
    #lang = params[:hl].nil? ? DEFAULT_LANG : params[:hl]
    #logger.info ("Lang is %s" % [lang])
    #cache = CitiSoapLoader::Cache.new agency_id, CitiSoapLoader::Target::RENTALS
    #
    #path = Uploads::Fs.get_cache_dir.join String(agency_id), CitiSoapLoader::Target::RENTALS
    #filename = path.to_s + File::SEPARATOR + lang + "_list.json"
    #
    #if File.exists? filename
    #  obj = JSON.parse(IO.read(filename))
    #  logger.info (obj.to_s)
    #  index = cache.load 'index_props_rentals.json' unless !cache.exists? 'index_props_rentals.json'
    #  logger.debug("Filename is %s" % [obj])
    #  translator = CitiSoapLoader::Translator.new request
    #  objs = []
    #  obj.each { |item|
    #    objs.push translator.translate_for_list_rentals item, index || nil, lang
    #  }
    #  @response = {:statusCode => 0, :statusMessage => "Success", :content => {:agency_id => agency_id, :object => objs}}
    #else
    #  @response = {:statusCode => 1, :statusMessage => "Error", :content => {:error_info => "File not exists"}}
    #end
    #respond_with @response
    search
  end

  def search

    agency_id = params[:agency_id]
    translator = CitiSoapLoader::Translator.new request
    lang = params[:hl]
    lang ||= DEFAULT_LANG
    cache = CitiSoapLoader::Cache.new agency_id, CitiSoapLoader::Target::RENTALS
    path = Uploads::Fs.get_cache_dir.join String(agency_id), CitiSoapLoader::Target::RENTALS
    filename = path.to_s + File::SEPARATOR + lang + "_list.json"
    price_worker = nil
    cpt = 0

    price_sensitivity = !(params[:min_price].nil? and params[:max_price].nil?)
    min_price = params[:min_price].nil? ? 0 : Float(params[:min_price])
    max_price = params[:max_price].nil? ? 999999999 : Float(params[:max_price])

    nb_rooms_sensitivity = !(params[:nb_rooms_min].nil? and params[:nb_rooms_max].nil?)
    nb_rooms_min = params[:nb_rooms_min].nil? ? 0 : Integer(params[:nb_rooms_min])
    nb_rooms_max = params[:nb_rooms_max].nil? ? 999 : Integer(params[:nb_rooms_max])

    date_sensitivity = !(params[:start_date].nil? and params[:end_date].nil?)
    start_date = params[:start_date].nil? ? '' : params[:start_date]
    end_date = params[:end_date].nil? ? '' : params[:end_date]

    if date_sensitivity
      price_worker = CitiSoapLoader::PriceListWorker.new agency_id, CitiSoapLoader::PriceListWorker::READING
      price_worker.init_filter start_date, end_date
    end

    if File.exists? filename
      @results = []
      index = cache.load 'index_props_rentals.json' unless !cache.exists? 'index_props_rentals.json'
      @objects = JSON.parse(IO.read(filename))
      index = cache.load 'index_props_rentals.json' unless !cache.exists? 'index_props_rentals.json'
      @objects.each { |obj|
        next if (price_sensitivity and !(obj["price"] >= min_price and obj["price"] <= max_price))
        next if (nb_rooms_sensitivity and !(obj["nb_rooms"] >= nb_rooms_min and obj["nb_rooms"] <= nb_rooms_max))
        next if (price_worker.nil? or !price_worker.accept obj)
        @results.push translator.translate_for_list_rentals obj, index || nil, lang
        cpt += 1
      }

      @response = {:statusCode => 0, :statusMessage => "Success", :content => {:cpt => cpt, :objects => @results}}
    else
      @response = {:statusCode => 1, :statusMessage => "Error", :content => {:error_info => "File not exists"}}
    end
    respond_with @response

  end

  def details
    object_id = params[:object_id]
    agency_id = params[:agency_id]
    lang = params[:hl].nil? ? DEFAULT_LANG : params[:hl]
    logger.info ("Lang is %s" % [lang])
    path = Uploads::Fs.get_cache_dir.join String(agency_id), CitiSoapLoader::Target::RENTALS
    filename = path.to_s + File::SEPARATOR + lang + "_" + String(object_id) + ".json"
    logger.info filename
    if File.exists? filename
      obj = JSON.parse(IO.read(filename))
      translator = CitiSoapLoader::Translator.new request
      obj_translated = translator.translate_for_details_rentals obj, nil, lang
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

  def pricing

  end

  def availability

  end

end
