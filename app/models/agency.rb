class Agency < ActiveRecord::Base
  has_one :agency_info
  attr_accessible :mail, :name, :website, :agency_info_id
end
