class Standing < ActiveRecord::Base
  has_many :items
  has_many :agency_items
  attr_accessible :description, :name
end
