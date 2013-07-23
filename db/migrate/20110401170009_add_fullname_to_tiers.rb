class AddFullnameToTiers < ActiveRecord::Migration
  def self.up
    add_column :tiers, :fullname, :string
  end

  def self.down
    remove_column :tiers, :fullname
  end
end
