class Country < ActiveRecord::Base
  has_many :districts

  attr_accessible :code, :iso, :name
end
