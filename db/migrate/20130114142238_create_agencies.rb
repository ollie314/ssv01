class CreateAgencies < ActiveRecord::Migration
  def change
    create_table :agencies do |t|
      t.string :name
      t.string :website
      t.text :mail
      t.integer :agency_info_id

      t.timestamps
    end
  end
end
