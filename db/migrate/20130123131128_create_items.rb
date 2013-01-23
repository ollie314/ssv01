class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :internal_name
      t.integer :standing_id

      t.timestamps
    end
  end
end
