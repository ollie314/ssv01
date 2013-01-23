class AddItemKindIdToItems < ActiveRecord::Migration
  def change
    add_column :items, :item_kind_id, :integer
  end
end
