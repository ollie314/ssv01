class ItemGroup < ActiveRecord::Base
  belongs_to :admin_agency, :class_name => 'Admin::Agency'
  has_and_belongs_to_many :items

  attr_accessible :description, :internal_name, :name
end
