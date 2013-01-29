class AddFksToAddresses < ActiveRecord::Migration
  def change
    add_column :addresses, :city_id, :integer
    add_column :addresses, :area_id, :integer
    add_column :addresses, :district_id, :integer
    add_column :addresses, :state_id, :integer
    add_column :addresses, :country_id, :integer

    remove_column :addresses, :city
    remove_column :addresses, :country
    remove_column :addresses, :state
  end
end
