class CreateStandings < ActiveRecord::Migration
  def change
    create_table :standings do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
