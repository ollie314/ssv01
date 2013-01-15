class CreateAgencyLanguages < ActiveRecord::Migration
  def change
    create_table :agency_languages do |t|
      t.boolean :is_default

      t.timestamps
    end
  end
end
