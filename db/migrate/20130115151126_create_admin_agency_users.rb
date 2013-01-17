class CreateAdminAgencyUsers < ActiveRecord::Migration
  def change
    create_table :admin_agency_users do |t|
      t.string :email
      t.string :password
      t.string :firstname
      t.string :lastname
      t.integer :rights

      t.timestamps
    end
  end
end
