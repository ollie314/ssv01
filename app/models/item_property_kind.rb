class ItemPropertyKind < ActiveRecord::Base
  has_many :item_properties

  attr_accessible :description, :internal_name, :name
end
