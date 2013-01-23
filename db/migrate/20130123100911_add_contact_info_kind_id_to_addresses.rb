class AddContactInfoKindIdToAddresses < ActiveRecord::Migration
  def change
    add_column :addresses, :contact_info_kind_id, :integer
  end
end
