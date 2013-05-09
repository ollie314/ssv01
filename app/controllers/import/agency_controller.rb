require 'citi/citi_soap_loader'
require 'uploads/fs'

class Import::AgencyController < ApplicationController

  respond_to :xml, :json, :html

  DEFAULT_LANG                = 'fr'
  DEFAULT_REDO_CACHE_LIST     = true
  DEFAULT_REDO_CACHE_DETAILS  = true
  DEFAULT_REDO_CACHE_IMAGES   = true
  DEFAULT_REBUILD_INDEX       = true
  LOADER_DEBUG_MODE           = true

  @rentals_season_loader = nil
  @rentals_common_loder = nil
  @sales_loader = nil

  def do_fill_agency_info
    # TODO : add this part to the configuration settings
    channel_id = 3
    username = 'CITI_COURTAGE_PERSO'
    password = 'LetMeIn_Now_Courtage_Perso'

    redo_cache_list = params[:cache_list].nil? ? DEFAULT_REDO_CACHE_LIST : params[:cache_list] == 1
    redo_cache_details = params[:cache_details].nil? ? DEFAULT_REDO_CACHE_DETAILS : params[:cache_details] == 1
    redo_cache_image = params[:cache_image].nil? ? DEFAULT_REDO_CACHE_IMAGES : params[:cache_image] == 1
    rebuild_index = params[:rebuild_index].nil? ? DEFAULT_REBUILD_INDEX : params[:rebuild_index] == 1

    lang = params[:hl] || DEFAULT_LANG

    connection = CitiSoapLoader::Connection.new CitiSoapLoader::Connection::WSDL_API_V1
    session_id = connection.connect(channel_id, username, password)
    agency_id = params[:agency_id]
    cache = CitiSoapLoader::Cache.new(agency_id, 'sales')

    loader = CitiSoapLoader::Sales.new(session_id, agency_id)
    object_list = loader.load_list
    cache.store(lang + ' ' + 'list', 'json', object_list[:object_courtage_simple]) unless !redo_cache_list
    if object_list.nil? || !redo_cache_details
      @response = {:statusCode => 0, :statusMessage => 'Success', :content => {:agency_id => agency_id, :nb_objects => 0}}
    else
      object_list[:object_courtage_simple].each { |p|
        cache.delete_image_cache_rep_for_item_id p[:object_id]
        object_detail = loader.load_detail p[:object_id], lang
        cache.store(lang + ' ' + object_detail[:object_courtage][:object_id], 'json', object_detail[:object_courtage])
        if redo_cache_image
          o = cache.load(lang + ' ' + object_detail[:object_courtage][:object_id] + '.json')
          cache.store_image_for_list o[:thumb_nail_url].nil? ? o['thumb_nail_url'] : o[:thumb_nail_url]
          cache_images o, cache
        end
      }
      if rebuild_index
        begin
          indexer = CitiSoapLoader::Indexer.new
          indexer.create_index agency_id, 'sales', request, 'index_props'
          reindex_status = 1
        rescue Exception => ex
          reindex_status = 0
          reindex_error = ex.message
          reindex_error_details = ex.backtrace unless !LOADER_DEBUG_MODE
        end
      end
      @response = {:statusCode => 0, :statusMessage => 'Success', :content => {:agency_id => agency_id, :nb_objects => object_list[:object_courtage_simple].count, :reindex_status => reindex_status}}
      @response[:content][:reindex_error] = reindex_error unless reindex_error.nil?
      @response[:content][:reindex_error_details] = reindex_error_details unless reindex_error_details.nil?
    end
    @response
  end

  def fill_agency_info
    start = Time.new
    lang_to_fill = %w(fr en)

    params[:hl] = lang_to_fill.pop #params[:hl].nil? ? DEFAULT_LANG : params[:hl]
    @response = do_fill_agency_info
    last_reindex_status = @response[:content][:reindex_status]

    params[:hl] = lang_to_fill.pop
    @response = do_fill_agency_info
    reindex_status = last_reindex_status != 1 ? @response[:content][:reindex_status] : 1

    stop = Time.new
    duration = (stop - start) * 1000

    @response[:content][:duration] = duration
    @response[:content][:reindex_status] = reindex_status

    respond_with @response
  end

  def load_sales_details
    channel_id = 3
    username = 'CITI_COURTAGE_PERSO'
    password = 'LetMeIn_Now_Courtage_Perso'
    lang = params[:hl].nil? ? DEFAULT_LANG : params[:hl]
    agency_id = params[:agency_id]
    connection = CitiSoapLoader::Connection.new CitiSoapLoader::Connection::WSDL_API_V1
    session_id = connection.connect channel_id, username, password
    cache = CitiSoapLoader::Cache.new agency_id, 'sales'

    loader = CitiSoapLoader::Sales.new session_id, agency_id
    object_list = loader.load_list
    cache.clean_details object_list
    if object_list.nil?
      @response = {:statusCode => 0, :statusMessage => 'Success', :content => {:agency_id => agency_id, :nb_objects => 0}}
    else
      object_list[:object_courtage_simple].each { |p|
        object_detail = loader.load_detail p[:object_id], lang
        cache_images object_detail, cache
        cache.store(lang + ' ' + object_detail[:object_courtage][:object_id], 'json', object_detail[:object_courtage])
      }
      begin
        indexer = CitiSoapLoader::Indexer.new
        indexer.create_index agency_id, 'sales', 'index_props_sales'
        reindex_status = 1
      rescue
        reindex_status = 0
      end
      @response = {:statusCode => 0, :statusMessage => 'Success', :content => {:agency_id => agency_id, :nb_objects => object_list[:object_courtage_simple].count, :reindex_status => reindex_status}}
    end
    respond_with @response
  end

  def cache_images(item, cache, target = 'sales')
    return unless !item.nil?
    base_url = 'http://www.RentAlp.ch/ObjectImages/'
    images = item['object_images']['object_image']
    images = [images] if images.class != Array
    images.each{|img|
      next unless !img['unc_path_source'].nil?
      image_url = base_url + img['unc_path_source'].gsub('\\', '/')
      cache.cache_image_by_url item, image_url, target
    }
  end

  def cache_images_for_list(item_list, cache)
    0 unless !item_list.nil? or (item_list.class == Array and item_list.size > 0)
    cpt = 0
    item_list.each { |item|
      thumb = item[:thumb_nail_url].nil? ? item['thumb_nail_url'] : item[:thumb_nail_url]
      next unless !thumb.nil? and cache.store_image_for_list thumb
      cpt += 1
    }
    cpt
  end

  def fetch_season_objects(agency_id)
    channel_id = 3031
    username = 'CITI_BESSON_SAISON'
    password = 'Besson_Saison_1_rx'

    logger.debug 'Trying to connect to the service to fetch rentals objects for season'
    connection = CitiSoapLoader::Connection.new CitiSoapLoader::Connection::WSDL_API_V2
    session_id = connection.connect channel_id, username, password

    logger.debug 'Trying to load data from the service'
    @rentals_season_loader = CitiSoapLoader::Season.new session_id, agency_id
    @rentals_season_loader.channel_id = channel_id
    @rentals_season_loader.username = username
    @rentals_season_loader.password = password

    logger.debug 'Season list loading process done.'
    @rentals_season_loader.load_list
  end

  def fetch_rentals_objects(agency_id)
    channel_id = 1015
    username = 'CITI_VITTEL'
    password = 'Vittel_1_rx'

    logger.debug 'Trying to connect to the service to fetch common rentals objects'
    connection = CitiSoapLoader::Connection.new CitiSoapLoader::Connection::WSDL_API_V2
    session_id = connection.connect channel_id, username, password

    logger.debug 'Trying to load data from the service'
    @rentals_common_loder = CitiSoapLoader::Rentals.new session_id, agency_id
    @rentals_common_loder.channel_id = channel_id
    @rentals_common_loder.username = username
    @rentals_common_loder.password = password

    logger.debug 'Common list loading process done.'
    @rentals_common_loder.load_list
  end

  def do_load_rentals_list

    start = Time.new
    lang = params[:hl].nil? ? DEFAULT_LANG : params[:hl]
    rebuild_cache = params[:rebuild_cache].nil? ? false : params[:rebuild_cache]
    agency_id = params[:agency_id]
    cache = CitiSoapLoader::Cache.new agency_id, 'rentals'

    # load common rental
    object_list = fetch_rentals_objects agency_id
    # load season rentals
    season_list = fetch_season_objects agency_id

=begin
    if season_list.class == Hash
      object_list.merge season_list
    else
      if season_list.class == Array
        object_list.concat season_list
      end
    end
=end

    cache.store(lang + '_list', 'json', object_list)
    cache_images_for_list object_list, cache

    if object_list.nil?
      @response = {:statusCode => 0, :statusMessage => 'Success', :content => {:agency_id => agency_id, :nb_objects => 0}}
    else
      if rebuild_cache
        object_list.each { |item|
          object_detail = @rentals_common_loder.load_details item[:id_object_location], lang
          cache.store(lang + '_' + object_detail[:object_location][:id_object_location], 'json', object_detail[:object_location])
          obj = cache.load(lang + '_' + object_detail[:object_location][:id_object_location] + '.json')
          cache.store_image_for_list obj[:thumb_nail_url].nil? ? obj['thumb_nail_url'] : obj[:thumb_nail_url]
          cache_images obj, cache, 'rentals'
        }

        season_list.each { |item|
          object_detail = @rentals_season_loader.load_details item[:id_object_location], lang
          cache.store(lang + '_' + object_detail[:object_location][:id_object_location], 'json', object_detail[:object_location])
          obj = cache.load(lang + '_' + object_detail[:object_location][:id_object_location] + '.json')
          cache.store_image_for_list obj[:thumb_nail_url].nil? ? obj['thumb_nail_url'] : obj[:thumb_nail_url]
          cache_images obj, cache, 'rentals'
        }

      end
      begin
        indexer = CitiSoapLoader::Indexer.new
        indexer.create_index agency_id, 'rentals', request, 'index_props'
        reindex_status = 1
      rescue Exception => ex
        reindex_status = 0
        reindex_error = ex.message
        reindex_error_details = ex.backtrace if LOADER_DEBUG_MODE
      end
      @response = {:statusCode => 0, :statusMessage => 'Success', :content => {:agency_id => agency_id, :objects => object_list, :reindex_status => reindex_status}}
      @response[:content][:reindex_error] = reindex_error unless reindex_error.nil?
      @response[:content][:reindex_error_details] = reindex_error_details unless reindex_error_details.nil?
    end

    stop = Time.new
    duration = (stop - start) * 1000
    @response[:content][:duration] = duration

    @response
  end

  def  load_rentals_list
    lang_to_fill = %w(fr en)
    params[:rebuild_cache] = true

    params[:hl] = lang_to_fill.pop #params[:hl].nil? ? DEFAULT_LANG : params[:hl]
    @response = do_load_rentals_list
    last_reindex_status = @response[:content][:reindex_status]
    duration = @response[:content][:duration]

    params[:hl] = lang_to_fill.pop
    @response = do_load_rentals_list
    reindex_status = last_reindex_status != 1 ? @response[:content][:reindex_status] : 1
    duration += @response[:content][:duration]

    @response[:content][:duration] = duration
    @response[:content][:reindex_status] = reindex_status

    respond_with @response
  end

  def load_rentals_details
    channel_id = 1015
    username = 'CITI_VITTEL'
    password = 'Vittel_1_rx'

    lang = params[:hl].nil? ? DEFAULT_LANG : params[:hl]
    rebuild_cache = params[:rebuild_cache].nil? ? false : params[:rebuild_cache]

    connection = CitiSoapLoader::Connection.new CitiSoapLoader::Connection::WSDL_API_V2
    session_id = connection.connect(channel_id, username, password)
    agency_id = params[:agency_id]
    cache = CitiSoapLoader::Cache.new agency_id, 'rentals'

    loader = CitiSoapLoader::Rentals.new session_id, agency_id
    loader.channel_id = channel_id
    loader.username = username
    loader.password = password

    object_list = loader.load_list
    if object_list.nil?
      @response = {:statusCode => 0, :statusMessage => 'Success', :content => {:agency_id => agency_id, :nb_objects => 0}}
    else
      object_list.each{ |item|
        object_detail = loader.load_details item[:id_object_location], lang
        cache.store(lang + "_" + object_detail[:object_location][:id_object_location], 'json', object_detail[:object_location])
        obj = cache.load(lang + "_" + object_detail[:object_location][:id_object_location] + '.json')
        cache_images obj, cache, 'rentals'
      }
      begin
        indexer = CitiSoapLoader::Indexer.new
        indexer.create_index agency_id, 'rentals', 'index_props_rentals'
        reindex_status = 1
      rescue
        reindex_status = 0
      end
      @response = {:statusCode => 0, :statusMessage => 'Success', :content => {:agency_id => agency_id, :nb_objects => object_list.count, :reindex_status => reindex_status}}
    end

    respond_with @response
  end

  def load_agency_info
    # TODO : add this part to the configuration settings
    channel_id = 3
    username = 'CITI_COURTAGE_PERSO'
    password = 'LetMeIn_Now_Courtage_Perso'
    agency_id = params[:agency_id]
    connection = CitiSoapLoader::Connection.new CitiSoapLoader::Connection::WSDL_API_V1
    session_id = connection.connect(channel_id, username, password)

    lang = params[:hl].nil? ? DEFAULT_LANG : params[:hl]

    cache = CitiSoapLoader::Cache.new(agency_id, 'sales')

    loader = CitiSoapLoader::Sales.new(session_id, agency_id)
    loader.channel_id=channel_id
    loader.username = username
    loader.password = password

    object_list = loader.load_list
    cache.store(lang + '_list', 'json', object_list[:object_courtage_simple])
    cache_images_for_list object_list[:object_courtage_simple], cache

    @response = {:statusCode => 0, :statusMessage => 'Success', :content => {:agency_id => agency_id, :objects => object_list}}
    respond_with @response
  end

  def check
    object_id = params[:object_id]
    agency_id = params[:agency_id]

    lang = params[:hl].nil? ? DEFAULT_LANG : params[:hl]

    path = Uploads::Fs.get_cache_dir.join(agency_id, 'sales')
    filename = path.to_s + '/' + object_id + '.json'
    if File.exists? filename
      obj = JSON.parse(IO.read(filename))
      translator = CitiSoapLoader::Translator.new
      obj_translated = translator.translate_for_details obj
      @response = {:statusCode => 0, :statusMessage => 'Success', :content => {:agency_id => agency_id, :object => obj_translated}}
    else
      @response = {:statusCode => 1, :statusMessage => 'Error', :content => {:error_info => 'Sorry the item seems doesn\'t exist'}}
    end
    respond_with @response
  end

  def test
    agency_id = params[:agency_id]
    params[:hl] = 'en_US'
    lang = params[:hl]
    url = "#{request.protocol}#{request.host_with_port}"
    full_path = "#{request.fullpath}"
    o_full_path = "#{request.original_fullpath}"
    domain = "#{request.domain}"
    remote_addr = "#{request.remote_ip}"
    @response = {:statusCode => 0, :statusMessage => 'Success', :content => {:lang => lang, :url => url, :full_path => full_path, :original_full_path => o_full_path, :domain => domain, :remote_addr => remote_addr}}
    respond_with @response
  end
end
