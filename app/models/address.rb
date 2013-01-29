class Address < ActiveRecord::Base
  belongs_to :addressable, :polymorphic => true
  belongs_to :contact_info_kind
  belongs_to :city
  belongs_to :area
  belongs_to :district
  belongs_to :state
  belongs_to :country

  attr_accessible :street_address1, :street_address2, :zip_code
end
