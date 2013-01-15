class CreateAgencyInfos < ActiveRecord::Migration
  def change
    create_table :agency_infos do |t|
      t.string :logo
      t.text :summary
      t.text :description
      t.integer :agency_id

      t.timestamps
    end
  end
end
