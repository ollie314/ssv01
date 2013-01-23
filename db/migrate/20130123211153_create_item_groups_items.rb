class CreateItemGroupsItems < ActiveRecord::Migration
  def up
    create_table :item_groups_items do |t|
      t.integer :item_group_id
      t.integer :item_id
    end
  end

  def down
    drop_table :item_groups_items
  end
end
