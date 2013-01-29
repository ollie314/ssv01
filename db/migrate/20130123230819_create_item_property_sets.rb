class CreateItemPropertySets < ActiveRecord::Migration
  def change
    create_table :item_property_sets do |t|
      t.string :name
      t.text :description
      t.integer :agency_id

      t.timestamps
    end
  end
end
