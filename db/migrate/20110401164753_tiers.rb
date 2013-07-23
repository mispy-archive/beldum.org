class Tiers < ActiveRecord::Migration
  def self.up
    create_table :tiers do |t|
      t.integer :id
      t.string :identifier
    end

    create_table :pokemon_tiers do |t|
      t.integer :tier_id
      t.integer :pokemon_id
    end
  end

  def self.down
    drop_table :tiers
    drop_table :pokemon_tiers
  end
end
