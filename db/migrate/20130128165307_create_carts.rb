class CreateCarts < ActiveRecord::Migration
  def change
    create_table :carts do |t|
      t.string :name
      t.float :amount
      t.boolean :checked_out
      t.integer :client_id
      t.datetime :checkout_date

      t.timestamps
    end
  end
end
