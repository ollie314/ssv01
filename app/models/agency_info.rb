class AgencyInfo < ActiveRecord::Base
  has_many :agency_languages, :dependent => :destroy
  has_many :languages, :through => :agency_languages
  attr_accessible :agency_id, :description, :logo, :summary
end
