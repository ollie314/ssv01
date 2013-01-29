require 'open-uri'

class Admin::Agency < ActiveRecord::Base
  has_one :agency_info
  has_many :agency_items, :foreign_key => :admin_agency_id
  has_many :item_groups, :foreign_key => :agency_id
  has_many :items, :through => :agency_items
  has_many :item_properties
  has_many :item_property_sets, :foreign_key => :agency_id

  has_and_belongs_to_many :item_properties

  validates :name, :presence => true, :uniqueness => true
  validates :mail, :presence => true, :uniqueness => true, :email => true
  validates :phone, :presence => true
  validates :website, :format => { :with => URI::regexp(%w(http https)), :message => "Invalid url specified." }

  attr_accessible :info, :name, :website, :mail, :phone, :logo
end