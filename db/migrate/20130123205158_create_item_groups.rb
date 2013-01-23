class CreateItemGroups < ActiveRecord::Migration
  def change
    create_table :item_groups do |t|
      t.string :name
      t.string :internal_name
      t.text :description
      t.integer :agency_id

      t.timestamps
    end
  end
end
