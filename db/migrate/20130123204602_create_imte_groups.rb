class CreateImteGroups < ActiveRecord::Migration
  def change
    create_table :imte_groups do |t|
      t.string :name
      t.text :description
      t.integer :agency_id

      t.timestamps
    end
  end
end
