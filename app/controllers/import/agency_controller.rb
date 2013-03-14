require 'citi/citi_soap_loader'
require 'uploads/fs'

class Import::AgencyController < ApplicationController

  respond_to :xml, :json, :html

  DEFAULT_LANG = 'fr'

  def fill_agency_info
    # TODO : add this part to the configuration settings
    channel_id = 3
    username = "CITI_COURTAGE_PERSO"
    password = "LetMeIn_Now_Courtage_Perso"
    redo_cache_list ||= params[:cache_all].nil? ? true : params[:cache_all] == 1
    lang = params[:hl] || DEFAULT_LANG
    start = Time.new

    connection = CitiSoapLoader::Connection.new CitiSoapLoader::Connection::WSDL_API_V1
    session_id = connection.connect(channel_id, username, password)
    agency_id = params[:agency_id]
    cache = CitiSoapLoader::Cache.new(agency_id, "sales")

    loader = CitiSoapLoader::Sales.new(session_id, agency_id)
    object_list = loader.load_list
    cache.store(lang + "_" + 'list', 'json', object_list[:object_courtage_simple]) unless !redo_cache_list
    if object_list.nil?
      @response = {:statusCode => 0, :statusMessage => "Success", :content => {:agency_id => agency_id, :nb_objects => 0}}
    else
      object_list[:object_courtage_simple].each { |p|
        cache.delete_image_cache_rep_for_item_id p[:object_id]
        object_detail = loader.load_detail p[:object_id], lang
        cache.store(lang + "_" + object_detail[:object_courtage][:object_id], 'json', object_detail[:object_courtage])
        o = cache.load(lang + "_" + object_detail[:object_courtage][:object_id] + ".json")
        cache_images o, cache
      }
      @response = {:statusCode => 0, :statusMessage => "Success", :content => {:agency_id => agency_id, :nb_objects => object_list[:object_courtage_simple].count}}
    end
    stop = Time.new
    duration = (stop - start) * 1000
    @response[:content][:duration] = duration
    respond_with @response
  end

  def load_sales_details
    channel_id = 3
    username = "CITI_COURTAGE_PERSO"
    password = "LetMeIn_Now_Courtage_Perso"
    lang = params[:hl].nil? ? DEFAULT_LANG : params[:hl]
    agency_id = params[:agency_id]
    connection = CitiSoapLoader::Connection.new(CitiSoapLoader::Connection::WSDL_API_V1)
    session_id = connection.connect(channel_id, username, password)
    cache = CitiSoapLoader::Cache.new agency_id, "sales"

    loader = CitiSoapLoader::Sales.new(session_id, agency_id)
    object_list = loader.load_list
    cache.clean_details object_list
    if object_list.nil?
      @response = {:statusCode => 0, :statusMessage => "Success", :content => {:agency_id => agency_id, :nb_objects => 0}}
    else
      object_list[:object_courtage_simple].each { |p|
        object_detail = loader.load_detail p[:object_id], lang
        cache_images object_detail, cache
        cache.store(lang + "_" + object_detail[:object_courtage][:object_id], 'json', object_detail[:object_courtage])
      }
      @response = {:statusCode => 0, :statusMessage => "Success", :content => {:agency_id => agency_id, :nb_objects => object_list[:object_courtage_simple].count}}
    end
    respond_with @response
  end

  def cache_images(item, cache, target = 'sales')
    return unless !item.nil?
    base_url = "http://www.RentAlp.ch/ObjectImages/"
    images = item["object_images"]["object_image"]
    if images.class != Array
      images = [images]
    end
    images.each{|img|
      next unless !img["unc_path_source"].nil?
      image_url = base_url + img["unc_path_source"].gsub("\\", "/")
      cache.cache_image_by_url item, image_url, target
    }
  end

  def cache_images_for_list(item_list, cache)
    0 unless !item_list.nil? or (item_list.class == Array and item_list.size > 0)
    cpt = 0
    item_list.each { |item|
      thumb = item[:thumb_nail_url].nil? ? item["thumb_nail_url"] : item[:thumb_nail_url]
      next unless !thumb.nil? and cache.store_image_for_list thumb
      cpt += 1
    }
    cpt
  end

  def  load_rentals_list
    channel_id = 1015
    username = "CITI_VITTEL"
    password = "Vittel_1_rx"

    lang = params[:hl].nil? ? DEFAULT_LANG : params[:hl]
    rebuild_cache = params[:rebuild_cache].nil? ? false : params[:rebuild_cache]

    connection = CitiSoapLoader::Connection.new CitiSoapLoader::Connection::WSDL_API_V2
    session_id = connection.connect channel_id, username, password
    agency_id = params[:agency_id]
    cache = CitiSoapLoader::Cache.new agency_id, "rentals"
    loader = CitiSoapLoader::Rentals.new session_id, agency_id
    loader.channel_id = channel_id
    loader.username = username
    loader.password = password

    object_list = loader.load_list

    cache.store(lang + '_list', 'json', object_list)
    cache_images_for_list object_list, cache

    if object_list.nil?
      @response = {:statusCode => 0, :statusMessage => "Success", :content => {:agency_id => agency_id, :nb_objects => 0}}
    else
      if rebuild_cache
        object_list.each { |item|
          object_detail = loader.load_detail item[:object_id], lang
          cache.store(lang + "_" + object_detail[:object_location][:object_id], 'json', object_detail[:object_location])
          obj = cache.load(lang + "_" + object_detail[:object_location][:object_id] + '.json')
          cache_images obj, cache
        }
      end
      @response = {:statusCode => 0, :statusMessage => "Success", :content => {:agency_id => agency_id, :objects => object_list}}
    end
    respond_with @response
  end

  def load_rentals_details
    channel_id = 1015
    username = "CITI_VITTEL"
    password = "Vittel_1_rx"

    lang = params[:hl].nil? ? DEFAULT_LANG : params[:hl]
    rebuild_cache = params[:rebuild_cache].nil? ? false : params[:rebuild_cache]

    connection = CitiSoapLoader::Connection.new CitiSoapLoader::Connection::WSDL_API_V2
    session_id = connection.connect(channel_id, username, password)
    agency_id = params[:agency_id]
    cache = CitiSoapLoader::Cache.new agency_id, "rentals"

    loader = CitiSoapLoader::Rentals.new session_id, agency_id
    loader.channel_id = channel_id
    loader.username = username
    loader.password = password

    object_list = loader.load_list
    if object_list.nil?
      @response = {:statusCode => 0, :statusMessage => "Success", :content => {:agency_id => agency_id, :nb_objects => 0}}
    else
      object_list.each{ |item|
        object_detail = loader.load_details item[:id_object_location], lang
        cache.store(lang + "_" + object_detail[:object_location][:id_object_location], 'json', object_detail[:object_location])
        obj = cache.load(lang + "_" + object_detail[:object_location][:id_object_location] + '.json')
        cache_images obj, cache, 'rentals'
      }
      @response = {:statusCode => 0, :statusMessage => "Success", :content => {:agency_id => agency_id, :nb_objects => object_list.count}}
    end

    respond_with @response
  end

  def load_agency_info
    # TODO : add this part to the configuration settings
    channel_id = 3
    username = "CITI_COURTAGE_PERSO"
    password = "LetMeIn_Now_Courtage_Perso"
    agency_id = params[:agency_id]
    connection = CitiSoapLoader::Connection.new CitiSoapLoader::Connection::WSDL_API_V1
    session_id = connection.connect(channel_id, username, password)

    lang = params[:hl].nil? ? DEFAULT_LANG : params[:hl]

    cache = CitiSoapLoader::Cache.new(agency_id, "sales")

    loader = CitiSoapLoader::Sales.new(session_id, agency_id)
    loader.channel_id=channel_id
    loader.username = username
    loader.password = password

    object_list = loader.load_list
    cache.store(lang + '_list', 'json', object_list[:object_courtage_simple])
    cache_images_for_list object_list[:object_courtage_simple], cache

    @response = {:statusCode => 0, :statusMessage => "Success", :content => {:agency_id => agency_id, :objects => object_list}}
    respond_with @response
  end

  def check
    object_id = params[:object_id]
    agency_id = params[:agency_id]

    lang = params[:hl].nil? ? DEFAULT_LANG : params[:hl]

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

  def test
    agency_id = params[:agency_id]
    url = "#{request.protocol}#{request.host_with_port}"
    full_path = "#{request.fullpath}"
    o_full_path = "#{request.original_fullpath}"
    domain = "#{request.domain}"
    remote_addr = "#{request.remote_ip}"
    @response = {:statusCode => 0, :statusMessage => "Success", :content => {:url => url, :full_path => full_path, :original_full_path => o_full_path, :domain => domain, :remote_addr => remote_addr}}
    respond_with @response
  end
end
