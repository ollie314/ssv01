class AgencyInfo < ActiveRecord::Base
  belongs_to :Agency
  attr_accessible :agency_id, :description, :logo, :summary
end
