class ItemAttachment < ActiveRecord::Base
  belongs_to :item_attachment_kind
  belongs_to :item

  attr_accessible :description, :label, :name, :path
end
