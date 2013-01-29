class AgencyItem < ActiveRecord::Base
  belongs_to :standing
  belongs_to :admin_agency
  belongs_to :item

  attr_accessible :name
end
