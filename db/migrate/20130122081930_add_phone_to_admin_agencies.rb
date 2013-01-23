class AddPhoneToAdminAgencies < ActiveRecord::Migration
  def change
    add_column :admin_agencies, :phone, :string
  end
end
