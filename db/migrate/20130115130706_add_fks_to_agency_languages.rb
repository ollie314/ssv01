class AddFksToAgencyLanguages < ActiveRecord::Migration
  def up
    add_column :agency_languages, :agency_info_id, :integer
    add_column :agency_languages, :language_id, :integer
  end

  def down
    remove_column :agency_languages, :agency_info_id
    remove_column :agency_languages, :language_id
  end
end
