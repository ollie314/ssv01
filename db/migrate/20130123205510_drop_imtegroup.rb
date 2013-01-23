class DropImtegroup < ActiveRecord::Migration
  def up
    drop_table :imte_groups
  end

  def down
  end
end
