class CreateItemAttachments < ActiveRecord::Migration
  def change
    create_table :item_attachments do |t|
      t.string :name
      t.string :label
      t.text :description
      t.string :path
      t.integer :item_id
      t.integer :item_attachment_kind_id

      t.timestamps
    end
  end
end
