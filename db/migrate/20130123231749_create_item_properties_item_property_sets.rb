class CreateItemPropertiesItemPropertySets < ActiveRecord::Migration
  def up
    create_table :item_properties_item_property_sets do |t|
      t.integer :item_property_set_id
      t.integer :item_property_id
    end
  end

  def down
    drop_table :item_properties_item_property_sets
  end
end
