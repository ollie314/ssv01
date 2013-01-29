class CreateItemPropertyValues < ActiveRecord::Migration
  def change
    create_table :item_property_values do |t|
      t.text :value
      t.integer :item_property_id
      t.integer :item_id

      t.timestamps
    end
  end
end
