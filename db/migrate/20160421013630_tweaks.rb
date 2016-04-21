class Tweaks < ActiveRecord::Migration
  def change
    add_index :items, :published
    change_column_null :users, :username, false
    change_column_default :metadata_profiles, :default, false
  end
end
