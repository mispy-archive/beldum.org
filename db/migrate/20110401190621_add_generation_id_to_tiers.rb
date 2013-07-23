class AddGenerationIdToTiers < ActiveRecord::Migration
  def self.up
    add_column :tiers, :generation_id, :integer
  end

  def self.down
    remove_column :tiers, :generation_id
  end
end
