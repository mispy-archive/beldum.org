class Tier < ActiveRecord::Base
  has_many :pokemon_tiers

  scope :gen,
    lambda { |num| { :conditions => { :generation_id => num } } }

  def pokemon
    Pokedex::Pokemon.scoped(:conditions => ["id IN (?)", pokemon_tiers.map { |pt| pt.pokemon_id }])
  end

  def add(poke)
    tier = PokemonTier.find_by_tier_id_and_pokemon_id(self.id, poke.id)
    PokemonTier.create(:tier_id => self.id, :pokemon_id => poke.id) unless tier
  end

  def populate(names)
    names.each do |name|
      form_map = { 'Deoxys-A' => 10001, 'Deoxys-D' => 10002, 'Deoxys-S' => 10003, 'Giratina-O' => 10007, 'Shaymin-S' => 10006, 'Rotom-H' => 10008, 'Rotom-W' => 10009, 'Rotom-F' => 10010, 'Rotom-S' => 10011, 'Rotom-C' => 10012, 'Wormadam' => 413, 'Wormadam-G' => 10004, 'Wormadam-S' => 10005, "Farfetch'd" => 83, "Mr. Mime" => 122, "Mime Jr." => 439 }
      if form_map[name]
        poke = Pokedex::Pokemon.find(form_map[name])
      else
        poke = Pokedex::Pokemon.find_by_identifier(name.downcase)
      end

      p name
      
      add(poke)
    end
  end
end

class PokemonTier < ActiveRecord::Base
  belongs_to :tier
end

Pokedex::Pokemon.class_eval do
  def tier
    PokemonTier.find_by_pokemon_id(self.id).tier
  end
end
