class District < ActiveRecord::Base
  belongs_to :state
  has_many :areas

  attr_accessible :name
end
