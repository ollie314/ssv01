class CreateAdminAgencies < ActiveRecord::Migration
  def change
    create_table :admin_agencies do |t|
      t.string :name
      t.string :website
      t.string :mail
      t.string :logo
      t.text :info

      t.timestamps
    end
  end
end
