class CreateAgencyItems < ActiveRecord::Migration
  def change
    create_table :agency_items do |t|
      t.string :name
      t.integer :standing_id
      t.integer :agency_id
      t.integer :item_id

      t.timestamps
    end
  end
end
