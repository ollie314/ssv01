class ContactInfoKind < ActiveRecord::Base
  has_many :addresses
  attr_accessible :description, :internal_name, :name
end
