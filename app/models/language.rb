class Language < ActiveRecord::Base
  attr_accessible :flag, :ietf, :iso2, :iso3, :name
end
