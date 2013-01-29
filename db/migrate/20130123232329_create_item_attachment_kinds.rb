class CreateItemAttachmentKinds < ActiveRecord::Migration
  def change
    create_table :item_attachment_kinds do |t|
      t.string :name
      t.string :description

      t.timestamps
    end
  end
end
