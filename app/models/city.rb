class City < ActiveRecord::Base
  belongs_to :area

  attr_accessible :name, :zipcode
end
