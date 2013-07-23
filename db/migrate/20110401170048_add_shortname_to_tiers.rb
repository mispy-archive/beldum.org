class AddShortnameToTiers < ActiveRecord::Migration
  def self.up
    add_column :tiers, :shortname, :string
  end

  def self.down
    remove_column :tiers, :shortname
  end
end
