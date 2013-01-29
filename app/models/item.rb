class Item < ActiveRecord::Base
  belongs_to :standing
  belongs_to :item_kind

  has_many :agency_items
  has_many :admin_agencies, :class_name => 'Admin::Agency', :through => :agency_items

  has_and_belongs_to_many :item_groups

  has_many :item_property_values
  has_many :item_properties, :through => :item_property_values

  has_many :addresses, :as => :addressable

  has_many :item_attachments

  attr_accessible :internal_name
end
