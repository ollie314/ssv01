class FixAdminAgencyNameForAgencyItems < ActiveRecord::Migration
  def up
    rename_column :agency_items, :agency_id, :admin_agency_id
  end

  def down
    rename_column :agency_items, :admin_agency_id, :agency_id
  end
end
