class ItemPropertyValue < ActiveRecord::Base
  belongs_to :item
  belongs_to :item_property

  attr_accessible :value
end
