class AddAddressableIdToAddresses < ActiveRecord::Migration
  def change
    add_column :addresses, :addressable_id, :integer
  end
end
