module CitiInfoConverter

  class << self

    def agency_cleanup(src)

    end

    def get_agency_info(array_of_items)
      ci = array_of_items[0][0];
      agency_info = {}
      agency_info[:name] = ci[:AgencyName]
      agency_info[:phone] = ci[:ContactTel]
      agency_info[:mobile] = ci[:ContactMobile]
      agency_info[:fax] = ci[:ContactFax]
      agency_info[:website] = ci[:Website]
      agency_info[:email] = ci[:Email]
      agency_info[:address] = {:street1 => ci[:AdminStreet1], :street2 => ci[:AdminStreet2], :zipcode => ci[:AdminZipCode], :city => ci[:AdminCity], :country => ci[:AdminCountry]}

      agency_info
    end

  end

end