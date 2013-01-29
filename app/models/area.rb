class Area < ActiveRecord::Base
  belongs_to :district
  has_many :cities

  attr_accessible :name
end
