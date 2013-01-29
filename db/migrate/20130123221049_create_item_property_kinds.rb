class CreateItemPropertyKinds < ActiveRecord::Migration
  def change
    create_table :item_property_kinds do |t|
      t.string :name
      t.string :internal_name
      t.text :description

      t.timestamps
    end
  end
end
