class ItemPropertySet < ActiveRecord::Base
  belongs_to :admin_agency, :class_name => 'Admin::Agency'

  attr_accessible :description, :name
end
