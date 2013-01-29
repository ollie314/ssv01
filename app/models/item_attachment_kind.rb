class ItemAttachmentKind < ActiveRecord::Base
  has_many :item_attachments

  attr_accessible :description, :name
end
