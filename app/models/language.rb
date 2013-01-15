class Language < ActiveRecord::Base
  has_many :agency_languages, :dependent => :destroy
  has_many :agency_infos, :through => :agency_languages
  attr_accessible :flag, :ietf, :iso2, :iso3, :name
end
