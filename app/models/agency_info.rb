class AgencyInfo < ActiveRecord::Base
  has_many :agency_languages, :dependent => :destroy
  has_many :languages, :through => :agency_languages
  has_many :addresses, :as => :addressable

  attr_accessible :admin_agency_id, :description, :logo, :summary

end
