class ItemProperty < ActiveRecord::Base
  belongs_to :admin_agency, :class_name => 'Admin::Agency'
  belongs_to :item_property_kind
  has_many :item_property_values
  has_many :items, :through => :item_property_values

  has_and_belongs_to_many :item_property_sets

  attr_accessible :name
end
