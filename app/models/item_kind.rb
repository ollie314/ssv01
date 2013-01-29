class ItemKind < ActiveRecord::Base
  has_many :items
  attr_accessible :description, :internal_name, :name
end
