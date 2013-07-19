require 'savon/client'
require 'uploads/fs'
require 'open-uri'

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

    def create_index(agency_id, target, request, index_filename = 'index_props', index_filename_ext = 'json')
      index_pathname = '%s_%s.%s' % [index_filename, target, index_filename_ext]
      index = {}
      translator = Translator.new request
      case target
        when Target::SALES
          leaf_container = Target::SALES
        when Target::RENTALS
          leaf_container = Target::RENTALS
        else
          leaf_container = Target::ORPHANS
      end
      cache = Cache.new agency_id, leaf_container
      parent_path = @path.join(String(agency_id), target)
      files = parent_path.children false
      file_to_exclude = ['fr_list.json', 'en_list.json', index_pathname]

      files.each { |f|
        next if f.to_s == 'images'
        next unless !f.directory? and !file_to_exclude.include? f.to_s and is_valid_file? f.to_s
        _fname = f.absolute? ? f.to_s : parent_path.to_s + File::SEPARATOR + f.to_s
        cur_obj = JSON.parse(IO.read(_fname))
        case target
          when Target::RENTALS
            id_key = 'id_object_location'
          when Target::SALES
            id_key = 'object_id'
        end
        index[cur_obj[id_key]] = get_props cur_obj, translator
      }

      cache.store '%s_%s' % [index_filename, target], index_filename_ext, index
      true
    end

    private

    #
    # The index is based on relevant properties to summarize in the object list.
    # For now, those one are external link information (youtube video, rentalp
    # photo, ...
    #
    def get_props(obj, translator)
      props = {}
      props['images'] = translator.list_image(obj).size
      props['plans'] = translator.list_plans(obj).size
      props['docs'] = translator.list_docs(obj).size
      props['videos'] = translator.list_videos(obj).size
      props['virtual_visits'] = translator.list_virtual_visits(obj).size
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
      f_cache = File.new('%s/%s.%s' % [@rep.to_s, filename, extension], 'w')
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

    def load_image(filename)
      _fname = @rep.join('images').to_s + File::SEPARATOR + filename
      {} unless File.exists? _fname
      _fname
    end

    def drop_image(filename)
      _fname = @rep.join('images').to_s + File::SEPARATOR + filename
      false unless File.exists? _fname
      begin
        if File.directory? _fname
          false
        else
          File.delete _fname
          true
        end
      rescue
        false
      end
    end

    def store_image_for_list(thumb)
      # return if thumb is not a valid document.
      return if /.*?\.(jpg|png|jpeg||gif|pdf|doc|xls|docx|xslx)/i.match(thumb).nil?

      # trying to store image in the cache ...
      # TODO : add logging information right here ...
      begin
        path = Uploads::Fs.create_path_if_not_exists @rep.join('images', 'list')
        _th = Uploads::Helper::clean_url File.basename thumb
        f_name = File.dirname(thumb) + '/' + _th
        open(f_name) { |f|
          image_name = path.to_s + File::SEPARATOR + File.basename(thumb)
          File.open(image_name, 'wb') do |file|
            file.puts f.read
          end
        }
        true
      rescue
        false
      end
    end

    #
    # Drop the whole directory for a specific object. This directory
    # may contains doc and images.
    #
    def delete_image_cache_rep_for_item_id(item_id)
      begin
        path = @rep.join('images', item_id).to_s
        false unless Dir.exists path
        FileUtils.rmtree path
        true
      rescue
        false
      end
    end

    #
    # Smae of previous but woking on an item instead of his id.
    #
    def delete_image_cache_rep_for_item(item)
      return delete_image_cache_rep_for_item_id item[:object_id]
    end

    def cache_image_by_url(item, url, target = 'sales')
      # be sure about the document format.
      return if /.*?\.(jpg|png|jpeg|gif|pdf|doc|xls|docx|xslx)/i.match(url).nil?
      begin
        case target
          when 'rentals' # TODO : change for constants (Target)
            id_key = 'id_object_location'
          when 'sales' # TODO : change for constants (Target)
            id_key = 'object_id'
        end
        path = Uploads::Fs.create_if_not_exists @rep.join('images'), item[id_key]
        _th = Uploads::Helper::clean_url File.basename url

        # be sure the url cleaning process is OK.
        return false if _th.nil?

        # open uri and try to store uri data in a local file
        open(File.dirname(url) + '/' + _th) { |f|
          # generate the local absolute path for the image to store
          image_name = path.to_s + File::SEPARATOR + File.basename(url)
          raise Exception("Unable to create the image with the name %s" %(image_name)) if image_name.nil?
          # write info into this image.
          File.open(image_name, 'wb') do |file|
            file.puts f.read
          end
          # TODO : log success
        }
        true
      rescue Exception => e
        e.message
        false
      end
    end

    def cache_image_from_url(item, url, img_name, target = 'sales')
      return if /.*?\.(jpg|png|jpeg|gif|pdf|doc|xls|docx|xslx)/i.match(url).nil?
      begin
        case target
          when 'rentals'
            id_key = 'id_object_location'
          when 'sales'
            id_key = 'object_id'
        end
        path = Uploads::Fs.create_if_not_exists @rep.join('images'), item[id_key]
        open(url) { |f|
          image_name = path.to_s + File::SEPARATOR + img_name
          File.open(image_name, 'wb') do |file|
            file.puts f.read
          end
        }
        true
      rescue Exception => e
        e.message
        false
      end
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
      @rep.children(false).each { |file|
        next unless drop @rep.to_s + File::SEPARATOR + file
        cpt += 1
      }
      cpt
    end

    # clear all files from the cache and keep agency root path in place
    def clear_all
      cpt = 0
      @rep.children.each { |file|
        next unless drop @rep.to_s + File::SEPARATOR + file
        cpt += 1
      }
      cpt
    end

    # clean details files for an object from the cache. delete json file and images
    def clean_details(object_list)
      0 unless !(object_list.nil? or object_list.length == 0)
      ids = []
      object_list.each { |item|
        ids.push item['object_id']
      }
      cpt = 0
      @rep.children.each { |file|
        basename = File.basename(file, '.json')
        next unless !File.directory? file or ids.includes? basename
        begin
          File.delete file
          delete_image_cache_rep_for_item_id basename
          cpt += 1
        rescue
          next
        end
      }
      cpt
    end

    # check if a specific file exists into the cache
    def exists?(filename)
      File.exists? @rep.to_s + File::SEPARATOR + filename
    end
  end

  class Translator

    def initialize(request = nil)
      @request = request
    end

    def get_kind(obj_kind_label)
      case obj_kind_label
        when 'appartement'
          return 1
        when 'chalet'
          return 2
        when 'terrain'
          return 3
        when 'place de parc'
          return 4
        else
          return 0
      end
    end

    #
    # Translate informations provided by the webservice to return a list
    # of object.
    # it return an object formatted to be put in a list
    #
    def translate_for_list(obj, index = nil, lang = nil, use_cache = false)
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
      result[:id] = obj['object_id']
      result[:name] = obj['object_name']
      result[:nb_room] = obj['object_number_of_rooms']
      result[:nb_floor] = obj['object_number_of_rooms']

      # if system use cache to provide image information, then use local data, use remote otherwise
      if use_cache
        result[:main_picture] = '%s%s/cache/%s/sales/images/list/%s' % [@request.protocol, @request.host_with_port, obj['agency_info']['id_agency'], File.basename(obj['thumb_nail_url'].gsub(/\\+/, '/'))]
      else
        result[:main_picture] = obj['thumb_nail_url']
      end
      result[:price] = obj['object_courtage_selling_price']
      result[:new] = obj['object_courtage_is_new']
      result[:reserved] = obj['object_courtage_reserved']
      result[:sellable_to_foreigner] = obj['object_courtage_sellable_to_foreigners']
      result[:reserved] = obj['object_courtage_reserved']
      result[:kind] = get_kind obj['object_type_label']
      result[:kind_description] = {lang => obj['object_type_label']}
      result[:attachments] = index[obj['object_id']] unless index.nil?
      result
    end

    def translate_for_list_rentals(obj, index = nil, lang = nil)
      lang = lang.nil? ? 'fr' : lang
      result = {}
      result[:id] = obj['id_object_location']
      result[:name] = obj['object_name']
      result[:floor_size] = obj['floor_size']
      result[:number_of_rooms] = obj['number_of_rooms']
      result[:number_of_bedrooms] = obj['number_of_bedrooms']
      result[:number_of_bathrooms] = obj['number_of_bathrooms']
      result[:main_picture] = '%s%s/cache/%s/rentals/images/list/%s' % [@request.protocol, @request.host_with_port, obj['agency_info']['id_agency'], File.basename(obj['thumb_nail_url'].gsub(/\\+/, '/'))]
      result[:kind] = obj['id_object_type']
      result[:kind_description] = get_kind obj['object_type_name']
      result[:attachments] = index[obj['id_object_location']] unless index.nil?
      result
    end

    def translate_for_details_rentals(obj, index = nil, lang = nil)
      lang = lang.nil? ? 'fr' : lang
      result = {}
      result[:id] = obj['id_object_location']
      result[:name] = obj['object_name']
      result[:floor_size] = obj['floor_size']
      result[:number_of_rooms] = obj['number_of_rooms']
      result[:main_picture] = obj['thumb_nail_url']
      #result[:main_picture] = "%s%s/cache/%s/rentals/images/list/%s" % [@request.protocol, @request.host_with_port, obj["agency_info"]["id_agency"], File.basename(obj["thumb_nail_url"].gsub(/\\+/, '/')).gsub(/70/, '230').gsub(/640/,'300')]
      result[:kind] = obj['id_object_type']
      result[:kind_description] = get_kind obj['object_type_name']
      result[:external_info] = 'http://vittel.rentalp.ch/rentalp.aspx?ID_Object=%s&ObjectName=&ID_Agency=%s&lng=%s&callbackUrl=%s&backgroundUrl=%s' % [
          obj['object_remote_id'],
          obj['agency_info']['id_agency'],
          lang,
          @request.referer.nil? ? obj['agency_info']['website'] : @request.referer,
          @request.referer.nil? ? obj['agency_info']['website'] : @request.referer,
      ]

      result[:promotion] = {
          lang => obj['object_courtage_promo']
      }

      begin
        if obj['object_descriptions']['object_description'].class == Array
          summary = nil
          description = nil
          obj['object_descriptions']['object_description'].each { |descr|
            if Integer(descr['sort_order']) == 0
              summary = descr['translated_description']
            else
              description = descr['translated_description']
            end
          }
          result[:summary] = {
              lang => summary
          }
          result[:description] = {
              lang => description
          }
        else
          result[:summary] = {
              lang => nil
          }
          result[:description] = {
              lang => obj['object_descriptions']['object_description']['translated_description']
          }
        end
      rescue
        result[:summary] = {
            lang => nil
        }
        result[:description] = {
            lang => nil
        }
      end
      result[:price_range] = {
          :lowest => obj['lowest_price_for_period'],
          :highest => obj['highest_price_for_period'],
          :avg_daily_price => obj['avg_daily_price']
      }

      result[:properties] = list_properties_rentals obj

      # Add floor
      floor = {
          :key => 'floor',
          :value => obj['floor_type_enum']['translated_label_enum'],
          :type => 'string'
      }
      result[:properties].push(floor)

      # Add category
      cat = {
          :key => 'category',
          :value => obj['self_assessement_enum']['translated_label_enum'],
          :type => 'string'
      }
      result[:properties].push(cat)

      # Add parking
      park_type = obj['parking_enum']['code_enum']
      case park_type
        when 'MULTI_STOREY'
          supported_types = ['Covered', 'shared parking']
          types = String(obj['parking_enum']['translated_label_enum']).split(",")
          indoor_park = types.include? supported_types[0]
          shared_park = types.include? supported_types[1]
          outdoor_park = FALSE
        when 'COVERED_LOT'
          indoor_park = TRUE
          shared_park = TRUE
          outdoor_park = FALSE
        when 'OPEN_LOT'
          indoor_park = FALSE
          shared_park = TRUE
          outdoor_park = TRUE
        when 'GARAGE'
          indoor_park = TRUE
          shared_park = FALSE
          outdoor_park = FALSE

        else
          # known NO_INFORMATION, null
          indoor_park = FALSE
          shared_park = FALSE
          outdoor_park = FALSE
      end

      # Add balcony
      balcony = {
          :key => 'balcony',
          :value => (!obj['extended_availability_balcony_enum'].nil? and obj['extended_availability_balcony_enum']['id_enum'] != 0),
          :type => 'boolean'
      }
      result[:properties].push(balcony)

      # Add terrace
      balcony = {
          :key => 'terrace',
          :value => (!obj['extended_availability_terrace_enum'].nil? and obj['extended_availability_terrace_enum']['id_enum'] != 0),
          :type => 'boolean'
      }
      result[:properties].push(balcony)

      # Add Internet connection indication
      internet = {
          :key => 'internet',
          :value => (!obj['internet_enum'].nil? and obj['internet_enum']['id_enum'] != 0),
          :type => 'boolean'
      }
      result[:properties].push(internet)


      result[:attachments] = create_list_attachments obj, 'rentals'

      result[:address] = create_address_rental obj
      result[:location] = create_location obj

      result
    end

    def list_properties_rentals(item)
      properties = []
      handled = %w(has_washingmachine has_drying_room has_dryer has_heating has_air_condition has_elevator has_recreational_room has_storage has_sauna has_sun_bed has_indoor_pool has_whirlpool has_steam_bath floor_size number_of_rooms number_of_bedrooms number_of_bathrooms number_of_toilets max_number_of_babies min_number_of_babies max_number_of_children min_number_of_children max_number_of_adults min_number_of_adults max_number_of_seniors min_number_of_seniors max_number_of_persons min_number_of_persons additional_number_of_children has_snow_cleaning has_gardener has_separate_garbage_collection has_compost has_quality_seal is_protected_building year has_additional_room has_tv_receiver is_family_friendly has_kitchen_material is_windows_intact is_furniture_intact is_devices_intact is_floor_and_walls_intact is_bathtube_and_washbasin_intact is_lighting_intact is_temperature_ok is_inscription_intact is_mattresses_intact is_hot_water_intact is_place_without_cars has_laundry_service has_eu_environtment_seal has_farm_holiday_seal has_lost_item_return has_welcome_gift price_bed_sheets price_kitchen_towel price_bath_towels price_final_cleaning price_parking price_bail price_handling_charge is_tourist_tax_included has_response_to_inquiries_within2_working_days has_everything_on_the_offer has_information_about_information_center is_the_contracts_in_writing has_important_phone_number_list has_personal_contact_in_the_first24_hours has_noise label_route_description label_detail_url label_booking_url label_availability_url label_promo_internet label_remark label_final_cleaning label_kitchen_towels label_bath_towels label_tourist_tax label_parking label_pets label_annulation_insurance label_bail label_handling_charge has_ski_area_access label_wet_room_specials label_kitchen_specials label_special_services label_price_specials has_video has_dvd has_cd has_telephone is_pet_allowed is_non_smoking is_sleeping_room has_dining_table has_arm_chair has_fire_place number_of_hotplates has_oven has_vent has_microwave has_dish_washer has_fridge has_private_beach has_jetty has_playground has_garden_furniture has_barbecue)

      booleans = [FalseClass, TrueClass]
      item.keys.each { |k|
        next if !handled.include? k
        v = item[k]
        t = item[k].class
        if nil === v
          t = 'null'
        else
          if booleans.include? t
            t = 'boolean'
          else
            if !nan? v
              t = (Float(v).nan? || v.index('.').nil?) ? 'number' : 'float'
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

    def translate_for_summary(obj, lang = mil)
      lang ||= 'fr'
      result = {}

      result
    end

    def translate_for_details(obj, lang = nil, use_cache = false)
      lang ||= 'fr'
      result = {}
      result[:id] = obj['object_id']
      result[:name] = obj["object_name"]
      result[:nb_room] = obj["object_number_of_rooms"]
      result[:nb_floor] = obj["object_number_of_rooms"]
      if use_cache
        result[:main_picture] = "%s%s/cache/%s/sales/images/list/%s" % [@request.protocol, @request.host_with_port, obj["agency_info"]["id_agency"], File.basename(obj["thumb_nail_url"].gsub(/\\+/, '/'))]
      else
        result[:main_picture] = obj['thumb_nail_url']
      end

      result[:sellable_cat] = 1 # TODO : Find out the correct value

      result[:summary] = {
          lang => obj["object_courtage_promo"]
      }

      # TODO : check if we have to do the same job as the previous one
      begin
        if obj["object_descriptions"]["object_description"].class == Array
          #descriptions = Array.new
          last = nil
          obj["object_descriptions"]["object_description"].each { |descr|
            retains = last.nil? ? true : (descr["sort_order"] > last["sort_order"])
            last = descr if retains
          }
          result[:description] = {
              lang => last["translated_description"]
          }
        else
          result[:description] = {
              lang => obj["object_descriptions"]["object_description"]["translated_description"]
          }
        end
      rescue
        result[:description] = {
            lang => nil
        }
      end

      result[:properties] = list_properties obj
      result[:attachments] = create_list_attachments obj, 'sales', use_cache

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

    def create_address_rental(item)
      address = {
          :street1 => item["address1"],
          :zipcode => item["qddress2"],
          :city => item["place"],
          :state => {
              :fr => item["state_translated_label"]
          },
          :country => {
              :iso => item["country_code"],
              :name => {
                  :fr => item["coutry"]
              }
          }
      }
      address
    end

    def create_location(item)
      coords = item["object_gps_coordinates"].nil? ? item["gps_coordinates"] : item["object_gps_coordinates"] # example : #46#05#29.25|#7#13#53.63"
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

    def create_image_info(img, index = nil)
      img_url = (img["unc_path_source"].nil? ? img[:unc_path_source] : img["unc_path_source"])
      img_url = img_url.gsub(/\\+/, '/') unless img_url.nil?
      img_url = "http://www.rentalp.ch/ObjectImages/" + img_url unless img_url.nil?
      image = {
          url: img_url.nil? ? "" : img_url,
          caption: img["label_title"].nil? ? img[:label_title] : img["label_title"],
          description: img["label_description"].nil? ? img[:label_description] : img["label_description"],
          kind: img["object_image_courtage_type"].nil? ? img[:object_image_courtage_type] : img["object_image_courtage_type"],
          ext: img_url.nil? ? "" : File.extname(img_url)
      }
      image['cover'] = 1 unless !index.nil? and index != 0
      image
    end

    def create_image_info_from_cache(img, item, endpoint = 'sales')
      _img = img['unc_path_source'].nil? ? img[:unc_path_source] : img['unc_path_source']
      item_id = endpoint == 'sales' ? "object_id" : "id_object_location"
      img_url = '%s%s/cache/%s/%s/images/%s/%s' % [@request.protocol,
                                                   @request.host_with_port,
                                                   item['agency_info']['id_agency'],
                                                   endpoint,
                                                   item[item_id],
                                                   File.basename(_img.gsub(/\\+/, '/'))] unless _img.nil?
      if !_img.nil?
        ck = img['object_image_courtage_type'].nil? ? img[:object_image_courtage_type] : img['object_image_courtage_type']
        k = (ck == 0 and File.extname(_img) == '.pdf') ? 3 : ck
      end
      image = {
          url: img_url,
          caption: img['label_title'].nil? ? img[:label_title] : img['label_title'],
          description: img['label_description'].nil? ? img[:label_description] : img['label_description'],
          kind: ck,
          ext: _img.nil? ? '' : File.extname(_img)
      }
    end

    def list_properties(item)
      properties = []
      handled = %w(regie_rent_amount_net regie_rent_amount_extra regie_rent_amount_duration tbc_nb_of_rooms_nb_of_rooms object_number_of_floors object_number_of_full_bathrooms object_number_of_half_bathrooms object_number_of_shower_only object_separated_toilet object_property_surface object_living_space object_volume object_wheel_chair_access object_fire_place object_parking object_garage object_sauna object_laundry_room object_balcony object_terrasse object_ramp object_internal_plan_situation object_courtage_land_surface object_courtage_living_space_surface object_courtage_lawn_surface object_courtage_storage_room_space object_courtage_balcony_surface object_courtage_half_balcony_surface object_courtage_half_balcony_surface_included object_courtage_suppl_furniture_price object_courtage_park_price_included object_courtage_charges object_courtage_renovation_date object_courtage_renovation_funds object_courtage_renovation_funds_desc object_courtage_is_new object_courtage_square_meter_price object_courtage_number_of_storage_rooms object_courtage_coefficient object_courtage_parcelle_number object_courtage_acquisition_date object_courtage_construction_date object_courtage_sellable_to_foreigners object_courtage_reserved object_cable_net_work object_courtage_cable object_courtage_elevator object_courtage_internet object_courtage_water_supply object_courtage_sewage_supply object_courtage_power_supply object_courtage_gas_supply object_courtage_sold object_courtage_ppe_thousanth object_courtage_years_charges object_courtage_years_funds object_courtage_ppe_number object_poles_location_label object_resort_altitude object_resort_population object_resort_access_data object_floor_type_label object_heat_type_label object_type_label object_type_label_french object_number_of_rooms_label object_object_access_label object_courtage_charges_note object_courtage_price_notes object_courtage_general_remarks object_courtage_zoning object_courtage_parking_notes object_courtage_reference object_courtage_ppe_info object_courtage_furniture_info object_add_number object_courtage_selling_price object_courtage_selling_price_object_only)

      booleans = [FalseClass, TrueClass]
      item.keys.each { |k|
        if !handled.include? k
          next
        end
        v = item[k]
        t = item[k].class
        if nil === v
          t = 'null'
        else
          if booleans.include? t
            t = 'boolean'
          else
            if !nan? v
              t = (Float(v).nan? || v.index('.').nil?) ? 'number' : 'float'
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

    def list_image(obj, endpoint = 'sales', use_cache = false)
      return [] unless !(obj['object_images'].nil? or obj['object_images']['object_image'].nil?)
      images = []
      exts = %w(.jpg .png .jpeg .gif)
      if obj['object_images']['object_image'].class == Array
        obj['object_images']['object_image'].each { |img|
          #_img = use_cache ? create_image_info_from_cache(img, obj, endpoint) : create_image_info(img)
          _img = create_image_info(img)
          images.push _img if exts.include? _img[:ext].downcase || img[:kind] == 1
        }
      else
        #_img = create_image_info_from_cache obj['object_images']['object_image'], obj, endpoint
        _img = create_image_info obj['object_images']['object_image']
        images.push _img unless !exts.include? _img[:ext].downcase || img[:kind] != 1
      end
      images
    end

    def list_docs(obj, endpoint = 'sales')
      return [] unless !(obj['object_images'].nil? or obj['object_images']['object_image'].nil?)
      plans = []
      exts = ['.pdf']

      if obj['object_images']['object_image'].class == Array
        obj['object_images']['object_image'].each { |item|
          #_img = create_image_info_from_cache item, obj, endpoint
          _img = create_image_info item
          if exts.include? _img[:ext]
            _img[:kind] = 2
            plans.push _img
          end
        }
      else
        _img = create_image_info obj['object_images']['object_image'], endpoint
        if exts.include? _img[:ext]
          _img[:kind] = 2
          plans.push _img
        end
      end
      plans
    end

    def list_plans(obj, endpoint = 'sales')
      return [] unless !(obj['object_images'].nil? or obj['object_images']['object_image'].nil?)
      plans = []
      if obj['object_images']['object_image'].class == Array
        obj['object_images']['object_image'].each { |item|
          #_img = create_image_info_from_cache item, obj, endpoint
          _img = create_image_info item
          plans.push _img if _img[:kind] == 1 #or _img[:ext].sub(/\./,"") == "pdf"
        }
      else
        #_img = create_image_info_from_cache obj['object_images']['object_image'], obj, endpoint
        _img = create_image_info obj['object_images']['object_image']
        if _img[:kind] == 1
          plans.push _img
        end
      end
      plans
    end

    def list_videos(obj, endpoint = 'sales')
      return [] unless !(obj['object_images'].nil? or obj['object_images']['object_image'].nil?)
      videos = []

      if obj['object_images']['object_image'].class == Array
        obj['object_images']['object_image'].each { |item|
          next unless has_video? item
          #video_url = 'http://www.youtube.com/embed/'
          video = create_video_object item
          if video[:kind] == 3
            videos.push video
          end
        }
      else
        item = obj['object_images']['object_image']
        if has_video? item
          video = create_video_object item
          if video[:kind] == 3
            videos.push video
          end
        end
      end
      videos
    end

    def list_virtual_visits(obj, endpoint = 'sales')
      return [] unless !(obj['object_images'].nil? or obj['object_images']['object_image'].nil?)
      visits = []
      if obj['object_images']['object_image'].class == Array
        obj['object_images']['object_image'].each { |item|
          next if item['url_small'].nil? or is_picture?(item['url_small']) or is_video(item) or is_pdf? item
          visit = create_visit_object item
          visits.push visit if visit[:kind] == 4
        }
      else
        item = obj['object_images']['object_image']
        if item['url_small'].nil? or is_picture?(item['url_small']) or is_video(item) or is_pdf? item
          visits = []
        else
          visit = create_visit_object item
          visits.push visit if visit[:kind] == 4
        end
      end
      visits
    end

    def create_list_attachments(obj, endpoint = 'sales', use_cache = false)
      virtual_visits = list_virtual_visits obj, endpoint
      plans = list_plans obj, endpoint
      images = list_image obj, endpoint, use_cache
      videos = list_videos obj, endpoint
      docs = list_docs obj, endpoint
      attachments = {
          :summary => {
              :pictures => images.length,
              :plans => plans.length,
              :videos => videos.length,
              :docs => docs.length,
              :virtual_visits => virtual_visits.length
          },
          :content => virtual_visits + plans + images + videos + docs
      }
    end

    private
    def is_video(item)
      return false if item['url_small'].nil?
      url = item['url_small']
      video_url_rx = /^.*youtube.*/.match url
      return false if video_url_rx.nil?
      video_url_rx.size > 0
    end

    def is_pdf item
      return false if item['url_large'].nil?
      m = item['url_large'].match(/\,pdf/)
      m.nil? or m.size > 0
    end

    def nan?(val)
      val !~ /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/
    end

    def is_pdf? item
      return false if item['url_large'].nil?
      m = item['url_large'].match(/\,pdf/)
      return false if m.nil?
      m.size > 0
    end

    def is_picture?(url)
      m = /^(http:\/\/).+\.(jpg|jpeg|png|gif)$/.match url
      return false if m.nil?
      m.size > 0
    end

    def has_video?(item)
      return false if item['url_small'].nil?
      is_video item
    end

    def create_video_object(item)
      video = {
          url: item['url_small'],
          caption: item['label_title'].nil? ? item[:label_title] : item['label_title'],
          description: item['label_description'].nil? ? item[:label_description] : item['label_description'],
          kind: 3,
          ext: nil
      }
    end

    def create_visit_object(item)
      visit = {
          url: item['url_small'],
          caption: item['label_title'].nil? ? item[:label_title] : item['label_title'],
          description: item['label_description'].nil? ? item[:label_description] : item['label_description'],
          kind: 4,
          ext: nil
      }
    end

  end

  class Connection

    WSDL_API_V1 = 'http://wspublication.rentalp.ch/CITI_WS_SESSION_Channel.asmx?WSDL'
    WSDL_API_V2 = 'http://wspublicationv2.rentalp.ch/CITI_WS_SESSION_Channel.asmx?WSDL'

    # constructor
    def initialize(endpoint_wsdl)
      endpoint_wsdl ||= WSDL_API_V1
      @wsdl = endpoint_wsdl
      @client = Savon.client(logger: Rails.logger, log_level: :debug, wsdl: @wsdl)
    end

    #connection
    def connect(channel_id, username, password)
      channel_id ||= 3
      message = {
          'channelId' => channel_id,
          'channelUserName' => username,
          'channelUserPwd' => password}
      response = @client.call(:connect_channel, message: message)

      session_id = response.to_hash[:connect_channel_response][:connect_channel_result]
    end

    # check connection
    def is_connected(session_id)
      message = {'sessionKey' => session_id}
      response = @client.call(:is_connected, message: message)

      is_connected = response.to_hash[:is_connected_response][:is_connected_result]
    end

    # disconnection
    def disconnect(session_id)
      message = {'sessionKey' => session_id}
      response = @client.call(:dis_connect, message: message)

      result = response.to_hash[:dis_connect_response][:dis_connect_result]
    end

    #obtain default language
    def get_default_language(session_id, channel_id, username, password)
      if !is_connected session_id
        connect channel_id, username, password
      end
      message = {'sessionKey' => session_id}
      response = @client.call(:get_default_language, message: message)

      result = response.to_hash[:get_default_language_response][:get_default_language_result]
      result
    end

    #define default language for next transaction
    def set_default_language(session_id, lang, channel_id, username, password)
      if !is_connected session_id
        connection channel_id, username, password
      end
      message = {'sessionKey' => session_id, 'languageId' => lang}
      response = @client.call(:set_default_language, message: message)

      result = response.to_hash[:set_default_language_response][:set_default_language_result]
    end
  end

  class Season
    attr_accessor :channel_id, :username, :password, :default_lang

    DEFAULT_LANG = 'fr'
    WSDL_API_V2 = 'http://wspublicationv2.rentalp.ch/CITI_WS_OBJECTLOCATION.asmx?WSDL'

    def initialize(session_id, agency_id, lang = nil, thumbnail_width = 640, thumbnail_height = 480)
      lang ||= DEFAULT_LANG
      @session_id = session_id
      @thumbnail_width = thumbnail_width
      @thumbnail_height = thumbnail_height
      @agency_id = agency_id
      @default_lang = lang || DEFAULT_LANG
      @wsdl = WSDL_API_V2
      @client = Savon.client(logger: Rails.logger, log_level: :debug, wsdl: @wsdl)
    end

    def load_list(lang = nil)
      lang ||= @default_lang

      set_default_lang lang

      message = {
          'sessionKey' => @session_id,
          'ThumbNailWidth' => @thumbnail_width,
          'ThumNailHeight' => @thumbnail_height,
          'lShowOccupiedAsWell' => 1,
          'nIdMainObjectType' => 1,
          'nIdObjectType' => -1
      }

      response = @client.call(:get_object_location_list_simple, message: message)

      # Array of [:object_location_simple]
      response.to_hash[:get_object_location_list_simple_response][:get_object_location_list_simple_result][:object_location_simple]
    end

    def load_details(obj_id, lang = nil)
      lang ||= @default_lang

      set_default_lang lang

      message = {
          "sessionKey" => @session_id,
          "objectLocationId" => obj_id,
          "ThumbNailWidth" => @thumbnail_width,
          "ThumNailHeight" => @thumbnail_height
      }

      response = @client.call(:get_object_location, message: message)
      response.to_hash[:get_object_location_response][:get_object_location_result]
    end

    private
    def set_default_lang(lang)
      if lang != @default_lang
        case lang
          when 'fr'
            lang_id = 1
          else
            lang_id = 2
        end
        @default_lang = lang
        connection = Connection.new Connection::WSDL_API_V2
        connection.set_default_language @session_id, lang_id, @channel_id, @username, @password
      end
      lang
    end
  end

  class Rentals

    attr_accessor :channel_id, :username, :password, :default_lang

    DEFAULT_LANG = 'fr'
    WSDL_API_V2 = "http://wspublicationv2.rentalp.ch/CITI_WS_OBJECTLOCATION.asmx?WSDL"

    # constructor
    def initialize(session_id, agency_id, lang = nil, thumbnail_width = 640, thumbnail_height = 480)
      lang ||= DEFAULT_LANG
      @session_id = session_id
      @thumbnail_width = thumbnail_width
      @thumbnail_height = thumbnail_height
      @agency_id = agency_id
      @default_lang = lang || DEFAULT_LANG
      @wsdl = WSDL_API_V2
      @client = Savon.client(logger: Rails.logger, log_level: :debug, wsdl: @wsdl)
    end

    def load_list(lang = nil)
      lang ||= @default_lang

      set_default_lang lang

      message = {
          'sessionKey' => @session_id,
          'ThumbNailWidth' => @thumbnail_width,
          'ThumNailHeight' => @thumbnail_height,
          'lShowOccupiedAsWell' => 1,
          'nIdMainObjectType' => 1,
          'nIdObjectType' => -1
      }

      response = @client.call(:get_object_location_list_simple, message: message)

      # Array of [:object_location_simple]
      response.to_hash[:get_object_location_list_simple_response][:get_object_location_list_simple_result][:object_location_simple]
    end

    def load_details(obj_id, lang = nil)
      lang ||= @default_lang

      set_default_lang lang

      message = {
          'sessionKey' => @session_id,
          'objectLocationId' => obj_id,
          'ThumbNailWidth' => @thumbnail_width,
          'ThumNailHeight' => @thumbnail_height
      }

      response = @client.call(:get_object_location, message: message)
      response.to_hash[:get_object_location_response][:get_object_location_result]
    end

    private
    def set_default_lang(lang)
      if lang != @default_lang
        case lang
          when 'fr'
            lang_id = 1
          else
            lang_id = 2
        end
        @default_lang = lang
        connection = Connection.new Connection::WSDL_API_V2
        connection.set_default_language @session_id, lang_id, @channel_id, @username, @password
      end
      lang
    end
  end

  # sales client
  class Sales

    WSDL_API_V1 = "http://wspublication.rentalp.ch/CITI_WS_OBJECTCOURTAGE.asmx?WSDL"

    attr_accessor :channel_id, :username, :password, :default_lang

    #constructor
    def initialize(session_id, agency_id, thumbnail_width = 640, thumbnail_height = 480)
      super()
      @session_id = session_id
      @thumbnail_width = thumbnail_width
      @thumbnail_height = thumbnail_height
      @agency_id = agency_id
      @default_lang = 'fr'
      @wsdl = WSDL_API_V1
      #@client = Savon.client(logger: Rails.logger, log_level: :debug, wsdl: @wsdl)
      @client = Savon.client(wsdl: @wsdl, log: false)
      @channel_id = 3
      @username = "CITI_COURTAGE_PERSO"
      @password = "LetMeIn_Now_Courtage_Perso"
    end

    # ... Courtage ...

    #GetObjectCourtageListSimple
    def load_list(lang = nil)
      lang ||= @default_lang

      set_default_lang lang

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

      set_default_lang lang

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

      set_default_lang lang

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

      set_default_lang lang

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

    private
    def set_default_lang(lang)
      if lang != @default_lang
        case lang
          when 'fr'
            lang_id = 1
          else
            lang_id = 2
        end
        connection = Connection.new Connection::WSDL_API_V1
        connection.set_default_language @session_id, lang_id, @channel_id, @username, @password
      end
      lang
    end

  end
end
