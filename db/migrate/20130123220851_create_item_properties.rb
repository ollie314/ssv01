class CreateItemProperties < ActiveRecord::Migration
  def change
    create_table :item_properties do |t|
      t.string :name
      t.integer :agency_id
      t.integer :item_property_kind_id

      t.timestamps
    end
  end
end
