class State < ActiveRecord::Base
  belongs_to :country
  has_many :districts

  attr_accessible :name
end
