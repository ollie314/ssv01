require 'citi/citi_soap_loader'
require 'uploads/fs'

class Import::AgencyController < ApplicationController

  respond_to :xml, :json, :html

  DEFAULT_LANG = 'fr'
  DEFAULT_REDO_CACHE_LIST = true
  DEFAULT_REDO_CACHE_DETAILS = true
  DEFAULT_REDO_CACHE_IMAGES = true
  DEFAULT_REBUILD_INDEX = true
  LOADER_DEBUG_MODE = true

  @rentals_season_loader = nil
  @rentals_common_loder = nil
  @sales_loader = nil

  def reindex_item
    agency_id = params[:agency_id]
    endpoint = params[:endpoint]
    channel_id = params[:channel_id]
    username = params[:username]
    password = params[:password]
    item_id = params[:item_id]
    supported_endpoint = %w(rentals sales season)
    connection = nil
    @response = nil

    lang = params[:hl] || DEFAULT_LANG
    begin
      if supported_endpoint.include? endpoint
        case endpoint
          when 'sales' then
            connection = CitiSoapLoader::Connection.new CitiSoapLoader::Connection::WSDL_API_V1
            cache = CitiSoapLoader::Cache.new agency_id, 'sales'
          when 'rentals' then
            cache = CitiSoapLoader::Cache.new agency_id, 'rentals'
            connection = CitiSoapLoader::Connection.new CitiSoapLoader::Connection::WSDL_API_V2
          when 'season' then
            cache = CitiSoapLoader::Cache.new agency_id, 'rentals'
            connection = CitiSoapLoader::Connection.new CitiSoapLoader::Connection::WSDL_API_V2
          else
            raise ArgumentError, 'Feed is not supported by the api'
        end
        session_id = connection.connect channel_id, username, password
        logger.debug 'Session id is %s' % [session_id]
        case endpoint
          when 'sales' then
            loader = CitiSoapLoader::Sales.new session_id, agency_id
          when 'rentals' then
            loader = CitiSoapLoader::Rentals.new session_id, agency_id
          when 'season' then
            loader = CitiSoapLoader::Season.new session_id, agency_id
          else
            raise ArgumentError, 'Feed is not supported by the api'
        end
        item_details = loader.load_details item_id, lang
        json_item = nil
        case endpoint
          when 'sales' then
            cache.store(lang + '_' + item_details[:object_courtage][:object_id], 'json', item_details[:object_courtage])
            json_item = cache.load(lang + '_' + item_details[:object_courtage][:object_id] + '.json')
          when 'rentals' then
            cache.store(lang + '_' + item_details[:object_location][:id_object_location], 'json', item_details[:object_location])
            json_item = cache.load(lang + '_' + item_details[:object_location][:id_object_location] + '.json')
          when 'season' then
            cache.store(lang + '_' + item_details[:object_location][:id_object_location], 'json', item_details[:object_location])
            json_item = cache.load(lang + '_' + item_details[:object_location][:id_object_location] + '.json')
          else
            raise ArgumentError, 'Feed is not supported by the api'
        end
        if !json_item.nil?
          cache.store_image_for_list json_item[:thumb_nail_url].nil? ? json_item['thumb_nail_url'] : json_item[:thumb_nail_url]
          cache_images json_item, cache, endpoint
        end
        connection.disconnect session_id
        @response = {:statusCode => 0, :statusMessage => 'Success', :content => {:agency_id => agency_id, :object => item_details}}
      else
        @response = {:statusCode => 1, :statusMessage => 'Error', :content => {:agency_id => agency_id, :info => 'Wrong endpoint specified'}}
      end
    rescue Exception => exception
      @response = {:statusCode => 1, :statusMessage => 'Error', :content => {:agency_id => agency_id, :info => exception.message, :exception => exception}}
    end
    respond_with @response
  end

  def rebuild_index
    agency_id = params[:agency_id]
    endpoint = params[:endpoint]
    indexer = CitiSoapLoader::Indexer.new
    reindex_status = 1
    begin
      indexer.create_index agency_id, endpoint, request, 'index_props'
      reindex_status = 0
      reindex_message = 'Success'
      content = {:message => "Reindexation successfully made."}
    rescue Exception => e
      reindex_status = 1
      reindex_message = 'Failure'
      content = {:message => e.message, :ex => e}
    end
    @response = {:statusCode => reindex_status, :statusMessage => reindex_message, :content => content}
    respond_with @response
  end

  def do_fill_agency_info
    # TODO : add this part to the configuration settings
    channel_id = 3
    username = 'CITI_COURTAGE_PERSO'
    password = 'LetMeIn_Now_Courtage_Perso'
    @response = nil

    redo_cache_list = params[:cache_list].nil? ? DEFAULT_REDO_CACHE_LIST : params[:cache_list] == 1
    redo_cache_details = params[:cache_details].nil? ? DEFAULT_REDO_CACHE_DETAILS : params[:cache_details] == 1
    redo_cache_image = params[:cache_image].nil? ? DEFAULT_REDO_CACHE_IMAGES : params[:cache_image] == 1
    rebuild_index = params[:rebuild_index].nil? ? DEFAULT_REBUILD_INDEX : params[:rebuild_index] == 1

    lang = params[:hl] || DEFAULT_LANG

    connection = CitiSoapLoader::Connection.new CitiSoapLoader::Connection::WSDL_API_V1
    session_id = connection.connect channel_id, username, password
    agency_id = params[:agency_id]
    cache = CitiSoapLoader::Cache.new agency_id, 'sales'

    loader = CitiSoapLoader::Sales.new session_id, agency_id
    object_list = loader.load_list
    cache.store(lang + '_' + 'list', 'json', object_list[:object_courtage_simple]) unless !redo_cache_list
    if object_list.nil? || !redo_cache_details
      @response = {:statusCode => 0, :statusMessage => 'Success', :content => {:agency_id => agency_id, :nb_objects => 0}}
    else
      object_list[:object_courtage_simple].each { |p|
        cache.delete_image_cache_rep_for_item_id p[:object_id]
        object_detail = loader.load_detail p[:object_id], lang
        cache.store(lang + '_' + object_detail[:object_courtage][:object_id], 'json', object_detail[:object_courtage])
        if redo_cache_image
          o = cache.load(lang + '_' + object_detail[:object_courtage][:object_id] + '.json')
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

    url = get_callback_url 'sales'
    begin
      logger.info 'Fetching url [%s] to refresh picture' % [url]
      r = open(url).read()
    rescue Exception => e
      logger.error 'Problem during fetching url [%s] to refresh picture [%s]' % [url, e.message]
    end

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
        cache.store(lang + '_' + object_detail[:object_courtage][:object_id], 'json', object_detail[:object_courtage])
      }
      begin
        indexer = CitiSoapLoader::Indexer.new
        indexer.create_index agency_id, 'sales', 'index_props_sales'
        reindex_status = 1
      rescue
        reindex_status = 0
      end

      url = get_callback_url 'sales'
      begin
        logger.info 'Fetching url [%s] to refresh picture' % [url]
        r = open(url).read()
      rescue Exception => e
        logger.error 'Problem during fetching url [%s] to refresh picture [%s]' % [url, e.message]
      end

      @response = {:statusCode => 0, :statusMessage => 'Success', :content => {:agency_id => agency_id, :nb_objects => object_list[:object_courtage_simple].count, :reindex_status => reindex_status}}
    end
    respond_with @response
  end

  def select_image_name(img)
    names = %w(url_large url_medium url_small unc_path_source)
    img_name = nil
    names.each{|name|
      next if name.nil?
      img_name = img[name]
      break
    }
    img_name
  end

  def cache_images(item, cache, target = 'sales')
    return if item.nil? || item['object_images'].nil? || item['object_images']['object_image'].nil?
    base_url = 'http://www.RentAlp.ch/ObjectImages/'
    images = item['object_images']['object_image']
    images = [images] if images.class != Array
    images.each { |img|
      img_name = select_image_name img
      next if img_name.nil?
      match = /http:\/\/\w+/i.match(img_name)
      if match and match.size > 0
        clean_url = File.dirname(img_name) + '/' +  Uploads::Helper::clean_url(File.basename(img_name))
        cache.cache_image_from_url item, clean_url, File.basename(img_name), target
      else
        image_url = base_url + img[img_name].gsub('\\', '/')
        cache.cache_image_by_url item, image_url, target
      end

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

  def load_rentals_list
    lang_to_fill = %w(fr en)
    params[:rebuild_cache] = true

    params[:hl] = lang_to_fill.pop #params[:hl].nil? ? DEFAULT_LANG : params[:hl]
    @response = do_load_rentals_list
    last_reindex_status = @response[:content][:reindex_status]
    duration = @response[:content][:duration]

    params[:hl] = lang_to_fill.pop
    @response = do_load_rentals_list
    reindex_status = last_reindex_status != 1 ? @response[:content][:reindex_status] : 1

    url = get_callback_url 'rentals'
    begin
      logger.info 'Fetching url [%s] to refresh picture' % [url]
      r = open(url).read()
    rescue Exception => e
      logger.error 'Problem during fetching url [%s] to refresh picture [%s]' % [url, e.message]
    end

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
      object_list.each { |item|
        object_detail = loader.load_details item[:id_object_location], lang
        cache.store(lang + '_' + object_detail[:object_location][:id_object_location], 'json', object_detail[:object_location])
        obj = cache.load(lang + '_' + object_detail[:object_location][:id_object_location] + '.json')
        cache_images obj, cache, 'rentals'
      }

      url = get_callback_url 'rentals'
      begin
        logger.info 'Fetching url [%s] to refresh picture' % [url]
        r = open(url).read()
      rescue Exception => e
        logger.error 'Problem during fetching url [%s] to refresh picture [%s]' % [url, e.message]
      end

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

    logger.info 'Fetching url to refresh picture'
    url = get_callback_url 'sales'
    r = open(url).read()

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
    endpoint = params[:endpoint] || 'sales'
    callback_url_skel = "%s/api/update_cache.php?resource=%s"
    callback_request = callback_url_skel % ["#{request.protocol}#{request.host_with_port}", endpoint]
    params[:hl] = 'en_US'
    lang = params[:hl]
    url = "#{request.protocol}#{request.host_with_port}"
    full_path = "#{request.fullpath}"
    o_full_path = "#{request.original_fullpath}"
    domain = "#{request.domain}"
    remote_addr = "#{request.remote_ip}"
    @response = {:statusCode => 0, :statusMessage => 'Success', :content => {:lang => lang,
                                                                             :url => url,
                                                                             :full_path => full_path,
                                                                             :original_full_path => o_full_path,
                                                                             :domain => domain,
                                                                             :remote_addr => remote_addr,
                                                                             :callback_url => callback_request}}
    respond_with @response, :status => :ok
  end

  private
  def get_callback_url(endpoint)
    callback_url_skel = "%s/api/update_cache.php?resource=%s"
    callback_url_skel % ["#{request.protocol}#{request.host_with_port}", endpoint]
  end
end