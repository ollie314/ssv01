class AgencyLanguage < ActiveRecord::Base
  belongs_to :language
  belongs_to :agency_info
  attr_accessible :is_default
end
