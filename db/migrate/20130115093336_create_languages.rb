class CreateLanguages < ActiveRecord::Migration
  def change
    create_table :languages do |t|
      t.string :iso2
      t.string :iso3
      t.string :ietf
      t.string :name
      t.string :flag

      t.timestamps
    end
  end
end
