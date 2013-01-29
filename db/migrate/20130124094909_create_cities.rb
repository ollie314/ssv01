class CreateCities < ActiveRecord::Migration
  def change
    create_table :cities do |t|
      t.string :name
      t.string :zipcode
      t.integer :area_id

      t.timestamps
    end
  end
end
