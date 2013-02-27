require 'savon/client'
require 'uploads/fs'

module CitiSoapLoader

  class Target
    SALES = 'sales'
    RENTALS = 'rentals'
    ORPHANS = 'orphans'
  end

  class Indexer

    def initialize(path = nil)
      path ||= Uploads::Fs.get_cache_dir
      if path.class == String
        path = Pathname.new(path)
      end
      @path = path
    end

    def create_index(agency_id, target)
      index_filename = 'index_props'
      index_filename_ext = 'json'
      index_pathname = "%s.%s" % [index_filename, index_filename_ext]
      index = {}
      translator = Translator.new
      case target
        when Target::SALES
          leaf_container = 'sales'
        when Target::RENTALS
          leaf_container = 'rentals'
        else
          leaf_container = Target::ORPHANS
      end
      cache = Cache.new agency_id, leaf_container
      parent_path = @path.join(String(agency_id), target)
      files = parent_path.children false
      file_to_exclude =  ['list.json', 'en_list.json', index_pathname]

      files.each{ |f|
        next unless !file_to_exclude.include? f.to_s and is_valid_file? f.to_s
        _fname = f.absolute? ? f.to_s : parent_path.to_s + File::SEPARATOR + f.to_s
        cur_obj = JSON.parse(IO.read(_fname))
        index[cur_obj['object_id']] = get_props cur_obj, translator
      }

      cache.store index_filename, index_filename_ext, index
      true
    end

    private
    def get_props(obj, translator)
      props = {}
      props['images'] = translator.list_image(obj).size
      props['plans'] = translator.list_plans(obj).size
      props['docs'] = translator.list_docs(obj).size
      props['videos'] = translator.list_videos(obj).size
      props
    end

    def is_valid_file?(filename)
      r = /^en_(?<id>\d+)\.json$/
      md = r.match filename
      md.nil?
    end
  end

  class Cache
    # constructor for the cache object
    def initialize(agency_id, endpoint)
      path = Uploads::Fs.setup_cache_dir(agency_id)
      Uploads::Fs.create_if_not_exists(path, endpoint)
      @rep = path.join(endpoint)
    end

    # store data into the cache
    def store(filename, extension, data)
      f_cache = File.new("%s/%s.%s" % [@rep.to_s, filename, extension], 'w')
      JSON.dump(data, f_cache)
      f_cache.flush
      f_cache.close
      true
    end

    # load a specific file from the cache
    def load(filename)
      _fname = @rep.to_s + File::SEPARATOR + filename
      {} unless File.exists? _fname
      JSON.parse(IO.read _fname)
    end

    # drop a specific file from the cache
    def drop(filename)
      _fname = @rep.to_s + File::SEPARATOR + filename
      false unless File.exists? _fname
      begin
        if File.directory? _fname
          FileUtils.rmtree _fname
        else
          File.delete _fname
        end
        true
      rescue
        false
      end
    end

    # clear first level files from the cache
    def clear_files
      cpt = 0
      @rep.children(false).each{ |file|
        next unless drop @rep.to_s + File::SEPARATOR + file
        cpt += 1
      }
      cpt
    end

    # clear all files from the cache and keep agency root path in place
    def clear_all
      cpt = 0
      @rep.children.each{ |file|
        next unless drop @rep.to_s + File::SEPARATOR + file
        cpt += 1
      }
      cpt
    end

    # check if a specific file exists into the cache
    def exists?(filename)
      File.exists? @rep.to_s + File::SEPARATOR + filename
    end

  end

  class Translator

    def initialize
      # nothing to do right now
    end

    def get_kind(obj_kind_label)
      case obj_kind_label
        when "appartement"
          return 1
        when "chalet"
          return 2
        when "terrain"
          return 3
        when "place de parc"
          return 4
        else
          return 0
      end
    end

    def translate_for_list(obj, index = nil, lang = nil)
      lang ||= 'fr'
      result = {}
      ###
      # Entry format ...
      #{
      #    "id": "b8295852-3b4c-4bbf-960a-c8d57d4677b8",
      #    "name": "Falaise 26",
      #    "kind" : "2",
      #    "kind_description" : {
      #         "en" : "Appartment",
      #         "fr" : "Appartement"
      #       },
      #    "attachments" : {
      #       images : 8,
      #       plans : 1,
      #       videos : 0,
      #       docs : 1
      #     },
      #    "price" : 240000.00,
      #    "nb_rooms" : 1,
      #    "nb_floor" : "1",
      #    "picture" : "http://toopixel.ch/clients/sites/besson/assets/apartments/room_1.jpg"
      #},
      ###
      result[:id]                     = obj["object_id"]
      result[:name]                   = obj["object_name"]
      result[:nb_room]                = obj["object_number_of_rooms"]
      result[:nb_floor]               = obj["object_number_of_rooms"]
      result[:picture]                = obj["thumb_nail_url"]
      result[:price]                  = obj["object_courtage_selling_price"]
      result[:new]                    = obj["object_courtage_is_new"]
      result[:reserved]               = obj["object_courtage_reserved"]
      result[:sellable_to_foreigner]  = obj["object_courtage_sellable_to_foreigners"]
      result[:reserved]               = obj["object_courtage_reserved"]
      result[:kind]                   = get_kind obj["object_type_label"]
      result[:kind_description]       = {lang => obj["object_type_label"]}
      result[:attachments]            = index[obj["object_id"]]
      result
    end

    def translate_for_summary(obj, lang = mil)
      lang ||= 'fr'
      result = {}

      result
    end

    def translate_for_details(obj, lang = nil)
      lang ||= 'fr'
      result = {}
      result[:id] = obj["object_id"]
      result[:name] = obj["object_name"]
      result[:nb_room] = obj["object_number_of_rooms"]
      result[:nb_floor] = obj["object_number_of_rooms"]
      result[:main_picture] = obj["thumb_nail_url"]


      result[:sellable_cat] = 1 # TODO : Find out the correct value

      result[:summary] = {
          lang => obj["object_courtage_promo"]
      }
      result[:description] = {
          lang => obj["object_descriptions"]["object_description"]["translated_description"]
      }

      result[:properties] = list_properties obj
      result[:attachments] = create_list_attachments obj

      result[:price] = obj["object_courtage_selling_price"]
      result[:new] = obj["object_courtage_is_new"]
      result[:reserved] = obj["object_courtage_reserved"]
      result[:sellable_to_foreigner] = obj["object_courtage_sellable_to_foreigners"]
      result[:reserved] = obj["object_courtage_reserved"]
      result[:kind] = get_kind(obj["object_type_label"])
      result[:kind_description] = {"fr" => obj["object_type_label"]}
      result[:address] = create_address obj
      result[:location] = create_location obj
      result
    end

    def create_address(item)
      address = {
          :street1 => item["object_location_label"],
          :zipcode => item["object_resort_zip_code"],
          :city => item["object_resort_label"],
          :state => {
              :fr => "Valais"
          },
          :country => {
              :iso => item["object_country_iso_number_code"],
              :name => {
                  :fr => item["object_country_label"]
              }
          }
      }
      address
    end

    def create_location(item)
      coords = item["object_gps_coordinates"] # example : #46#05#29.25|#7#13#53.63"
      parts = coords.split(/([^#\|]+)/)
      long = []
      lat = []
      parts.each { |it|
        if it == "#" || it == "|#"
          next
        end
        if lat.length < 3
          lat.push Float(it)
        else
          long.push Float(it)
        end
      }

      location = {
          :lat => lat[0] + (lat[1] + (lat[2] / 60)) / 60,
          :long => long[0] + (long[1] + (long[2] / 60)) / 60
      }
    end

    def create_image_info(img)
      image = {
          url: "http://www.rentalp.ch/ObjectImages/" + img["unc_path_source"].gsub(/\\+/, '/'),
          caption: img["label_title"],
          description: img["label_description"],
          kind: img["object_image_courtage_type"],
          ext: File.extname(img["unc_path_source"])
      }
    end

    def list_properties(item)
      properties = []
      handled = [
          'regie_rent_amount_net',
          'regie_rent_amount_extra',
          'regie_rent_amount_duration',
          'tbc_nb_of_rooms_nb_of_rooms',
          'object_number_of_floors',
          'object_number_of_full_bathrooms',
          'object_number_of_half_bathrooms',
          'object_number_of_shower_only',
          'object_separated_toilet',
          'object_property_surface',
          'object_living_space',
          'object_volume',
          'object_wheel_chair_access',
          'object_fire_place',
          'object_parking',
          'object_garage',
          'object_sauna',
          'object_laundry_room',
          'object_balcony',
          'object_terrasse',
          'object_ramp',
          'object_internal_plan_situation',
          'object_courtage_land_surface',
          'object_courtage_living_space_surface',
          'object_courtage_lawn_surface',
          'object_courtage_storage_room_space',
          'object_courtage_balcony_surface',
          'object_courtage_half_balcony_surface',
          'object_courtage_half_balcony_surface_included',
          'object_courtage_suppl_furniture_price',
          'object_courtage_park_price_included',
          'object_courtage_charges',
          'object_courtage_renovation_date',
          'object_courtage_renovation_funds',
          'object_courtage_renovation_funds_desc',
          'object_courtage_is_new',
          'object_courtage_square_meter_price',
          'object_courtage_number_of_storage_rooms',
          'object_courtage_coefficient',
          'object_courtage_parcelle_number',
          'object_courtage_acquisition_date',
          'object_courtage_construction_date',
          'object_courtage_sellable_to_foreigners',
          'object_courtage_reserved',
          'object_cable_net_work',
          'object_courtage_cable',
          'object_courtage_elevator',
          'object_courtage_internet',
          'object_courtage_water_supply',
          'object_courtage_sewage_supply',
          'object_courtage_power_supply',
          'object_courtage_gas_supply',
          'object_courtage_sold',
          'object_courtage_ppe_thousanth',
          'object_courtage_years_charges',
          'object_courtage_years_funds',
          'object_courtage_ppe_number',
          'object_poles_location_label',
          'object_resort_altitude',
          'object_resort_population',
          'object_resort_access_data',
          'object_floor_type_label',
          'object_heat_type_label',
          'object_type_label',
          'object_type_label_french',
          'object_number_of_rooms_label',
          'object_object_access_label',
          'object_courtage_charges_note',
          'object_courtage_price_notes',
          'object_courtage_general_remarks',
          'object_courtage_zoning',
          'object_courtage_parking_notes',
          'object_courtage_reference',
          'object_courtage_ppe_info',
          'object_courtage_furniture_info',
          'object_add_number',
          'object_courtage_selling_price',
          'object_courtage_selling_price_object_only',
      ]

      booleans = [FalseClass, TrueClass]
      item.keys.each { |k|
        if !handled.include? k
          next
        end
        v = item[k]
        t = item[k].class
        if nil === v
          t = "null"
        else
          if booleans.include? t
            t = "boolean"
          else
            if !nan? v
              t = (Float(v).nan? || v.index('.').nil?) ? "number" : "float"
            else
              t = t.to_s.downcase
            end

          end
        end
        _prop = {
            :key => k,
            :value => v,
            :type => t
        }
        properties.push _prop
      }
      properties
    end

    def nan?(val)
      val !~ /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/
    end

    def list_image(obj)
      images = []
      exts = ['.jpg', '.png', '.jpeg', '.gif']
      if obj["object_images"]["object_image"].class == Array
        obj["object_images"]["object_image"].each { |img|
          _img = create_image_info img
          if exts.include? _img[:ext] || img[:kind] == 1
            images.push _img
          end
        }
      else
        _img = create_image_info obj["object_images"]["object_image"]
        if exts.include? _img[:ext] || img[:kind] == 1
          images.push _img
        end
      end
      images
    end

    def list_docs(obj)
      plans = []
      exts = ['.pdf']

      if obj["object_images"]["object_image"].class == Array
        obj["object_images"]["object_image"].each { |item|
          _img = create_image_info item
          if exts.include? _img[:ext]
            _img[:kind] = 4
            plans.push _img
          end
        }
      else
        _img = create_image_info obj["object_images"]["object_image"]
        if exts.include? _img[:ext]
          _img[:kind] = 4
          plans.push _img
        end
      end
      plans
    end

    def list_plans(obj)
      plans = []
      if obj["object_images"]["object_image"].class == Array
        obj["object_images"]["object_image"].each { |item|
          _img = create_image_info item
          if _img[:kind] == 1
            plans.push _img
          end
        }
      else
        _img = create_image_info obj["object_images"]["object_image"]
        if _img[:kind] == 1
          plans.push _img
        end
      end
      plans
    end

    def list_videos(obj)
      videos = []

      if obj["object_images"]["object_image"].class == Array
        obj["object_images"]["object_image"].each { |item|
          #video_url = 'http://www.youtube.com/embed/'
          video = create_image_info item
          if video[:kind] == 3
            videos.push video
          end
        }
      else
        video = create_image_info obj["object_images"]["object_image"]
        if video[:kind] == 3
          videos.push video
        end
      end
      videos
    end

    def create_list_attachments(obj)
      plans = list_plans obj
      images = list_image obj
      videos = list_videos obj
      docs = list_docs obj
      attachments = {
          :summary => {
              :pictures => images.length,
              :plans => plans.length,
              :videos => videos.length,
              :docs => docs.length
          },
          :content => plans + images + videos + docs
      }
    end
  end

  class Connection

    # constructor
    def initialize
      @wsdl = "http://wspublication.rentalp.ch/CITI_WS_SESSION_Channel.asmx?WSDL"
      @client = Savon.client(logger: Rails.logger, log_level: :debug, wsdl: @wsdl)
    end

    #connection
    def connect(channelId, username, password)
      message = {
          "channelId" => 3,
          "channelUserName" => username,
          "channelUserPwd" => password}
      response = @client.call(:connect_channel, message: message)

      session_id = response.to_hash[:connect_channel_response][:connect_channel_result];
    end

    # check connection
    def is_connected(session_id)
      message = {"sessionKey" => session_id}
      response = @client.call(:is_connected, message)

      is_connected = response.to_hash[:is_connected_response][:is_connected_result]
    end

    # disconnection
    def disconnect(session_id)
      message = {"sessionKey" => session_id}
      response = @client.call(:dis_connect, message)

      result = response.to_hash[:dis_connect_response][:dis_connect_result]
    end

    #obtain default language
    def get_default_language(session_id)
      message = {"sessionKey" => session_id}
      response = @client.call(:get_default_language, message)

      result = response.to_hash[:get_default_language_response][:get_default_language_result]
    end

    #define default language for next transaction
    def set_default_language(session_id, lang)
      message = {"sessionKey" => session_id, "languageId" => lang}
      response = @client.call(:set_default_language, message)

      result = response.to_hash[:set_default_language_response][:set_default_language_result]
    end
  end

  # sales client
  class Sales

    #constructor
    def initialize(session_id, agency_id, thumbnail_width = 640, thumbnail_height = 480)
      super()
      @session_id = session_id
      @thumbnail_width = thumbnail_width
      @thumbnail_height = thumbnail_height
      @agency_id = agency_id
      @default_lang = 'fr'
      @wsdl = "http://wspublication.rentalp.ch/CITI_WS_OBJECTCOURTAGE.asmx?WSDL"
      @client = Savon.client(logger: Rails.logger, log_level: :debug, wsdl: @wsdl)
    end

    # ... Courtage ...

    #GetObjectCourtageListSimple
    def load_list(lang = nil)
      lang ||= @default_lang

      search_param = {
          "ResortId" => -1,
          "PolesLocationId" => -1,
          "FloorTypeId" => -1,
          "SellingPriceMini" => 0,
          "SellingPriceMaxi" => 9999999999,
          "LivingSpaceMini" => 0,
          "LivingSpaceMaxi" => 9999999,
          "NbOfRoomsMaxi" => 999999,
          "IsNew" => -1,
          "IsCourtage" => -1,
          "IsRegie" => 0,
          "Orderby" => "Price",
          "AgencyId" => @agency_id,
          "IsPromoEyeCatcher" => -1,
          "IsPromoNewlyAdded" => -1,
          "ObjectTypeId" => -1,
          "ObjectLocationId" => -1,
          "NbOfRoomsMini" => 0,
          "SellableToForeigners" => -1,
          "IsPromoInternet" => -1,
          "AddNumber" => ""
      }

      message = {
          "sessionKey" => @session_id,
          "ThumbNailWidth" => @thumbnail_width,
          "ThumNailHeight" => @thumbnail_height,
          "bSearchParametersCourtage" => search_param
      }

      response = @client.call(:get_object_courtage_list_simple, message: message)

      # Array of [:object_courtage_simple]
      response.to_hash[:get_object_courtage_list_simple_response][:get_object_courtage_list_simple_result]
    end

    #load object details
    def load_detail(object_id, lang = nil)
      lang ||= @default_lang

      message = {"sessionKey" => @session_id,
                 "objectId_Origin" => object_id,
                 "agencyId" => @agency_id,
                 "ThumbNailWidth" => @thumbnail_width,
                 "ThumNailHeight" => @thumbnail_height, }
      response = @client.call(:get_object_courtage, message: message)

      result = response.to_hash[:get_object_courtage_response][:get_object_courtage_result]
    end

    #load promotion
    def load_promotion
      lang ||= @default_lang

      search_param = {
          "ResortId" => -1,
          "PolesLocationId" => -1,
          "FloorTypeId" => -1,
          "SellingPriceMini" => 0,
          "SellingPriceMaxi" => 9999999999,
          "LivingSpaceMini" => 0,
          "LivingSpaceMaxi" => 9999999,
          "NbOfRoomsMaxi" => 999999,
          "IsNew" => -1,
          "IsCourtage" => -1,
          "IsRegie" => 0,
          "Orderby" => "Price",
          "AgencyId" => @agency_id,
          "IsPromoEyeCatcher" => -1,
          "IsPromoNewlyAdded" => 1, # search param overriding
          "ObjectTypeId" => -1,
          "ObjectLocationId" => -1,
          "NbOfRoomsMini" => 0,
          "SellableToForeigners" => -1,
          "IsPromoInternet" => -1,
          "AddNumber" => ""
      }

      message = {
          "sessionKey" => @session_id,
          "ThumbNailWidth" => @thumbnail_width,
          "ThumNailHeight" => @thumbnail_height,
          "srchParam" => search_param
      }

      response = @client.call(:get_object_courtage_list_simple_on_promotion, message: message)

      # Array of [:object_courtage_simple]
      response.to_hash[:get_object_courtage_list_simple_on_promotion_response][:get_object_courtage_list_simple_on_promotion_result]
    end

    # load eye catcher objects.
    def load_eyecatcher
      lang ||= @default_lang

      search_param = {
          "ResortId" => -1,
          "PolesLocationId" => -1,
          "FloorTypeId" => -1,
          "SellingPriceMini" => 0,
          "SellingPriceMaxi" => 9999999999,
          "LivingSpaceMini" => 0,
          "LivingSpaceMaxi" => 9999999,
          "NbOfRoomsMaxi" => 999999,
          "IsNew" => -1,
          "IsCourtage" => -1,
          "IsRegie" => 0,
          "Orderby" => "Price",
          "AgencyId" => @agency_id,
          "IsPromoEyeCatcher" => 1, # search param overriding
          "IsPromoNewlyAdded" => -1,
          "ObjectTypeId" => -1,
          "ObjectLocationId" => -1,
          "NbOfRoomsMini" => 0,
          "SellableToForeigners" => -1,
          "IsPromoInternet" => -1,
          "AddNumber" => ""
      }

      message = {
          "sessionKey" => @session_id,
          "ThumbNailWidth" => @thumbnail_width,
          "ThumNailHeight" => @thumbnail_height,
          "srchParam" => search_param
      }

      response = @client.call(:get_object_courtage_list_simple_on_promotion, message: message)

      # Array of [:object_courtage_simple]
      response.to_hash[:get_object_courtage_list_simple_on_promotion_response][:get_object_courtage_list_simple_on_promotion_result]
    end
  end
end