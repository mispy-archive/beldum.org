# Contains the many readonly models which provide access to veekun's Pokedex data
module Pokedex

  # Helper methods
  class << self

    def calc_damage_factors(types, ability, gen=5)
      factors = {}

      types.each do |type|
        Pokedex::TypeEfficacy.where(target_type_id: type.id).includes(:damage_type).each do |efficacy|
          dtype = efficacy.damage_type
          dfactor = efficacy.damage_factor

          if factors[dtype.identifier].nil?
            factors[dtype.identifier] = dfactor
          else
            factors[dtype.identifier] *= (dfactor/100.0) # Compound effectiveness
          end
        end
      end

      # Abilities. Absorptions are strings rather than negative values since they are specially handled anyway.
      case (ability && ability.identifier)
        when 'dry-skin' then 
          factors['water'] = 'Absorb'
          factors['fire'] *= 1.25
        when 'water-absorb' then 
          factors['water'] = 'Absorb'
        when 'flash-fire' then 
          factors['fire'] = 'Power Up'
        when 'heatproof' then 
          factors['fire'] *= 0.5
        when 'levitate' then 
          factors['ground'] = 0.0
        when 'motor-drive' then 
          factors['electric'] = 'Power Up'
        when 'thick-fat' then 
          factors['fire'] *= 0.5
          factors['ice'] *= 0.5
        when 'volt-absorb' then 
          factors['electric'] = 'Absorb'
      end

      if gen >= 5
        case (ability && ability.identifier)
          when 'lightningrod' then
            factors['electric'] = 'Power Up'
          when 'storm-drain' then
            factors['water'] = 'Power Up'
          when 'sap-sipper' then
            factors['grass'] = 'Power Up'
        end
      end

      factors
    end

    # Cached damage factor map calculator for complex sitautions (dual-types and abilities)
    # Form is { Pokedex::Type => damage_factor }
    def damage_factors(types, ability, gen)
      ability = nil unless ability && ability.type_modifier? # Ignore irrelevant abilities

      specifier = types.map { |type| type.id } + [ability ? ability.id : nil] + [gen]

      @@factor_cache ||= Cache.read 'damage_factors'
      @@factor_cache ||= {}

      factors = @@factor_cache[specifier]

      if factors.nil?
        factors = calc_damage_factors(types, ability, gen)

        @@factor_cache[specifier] = factors
        Cache.write 'damage_factors', @@factor_cache
      end

      factors
    end
  end

  # Mixin
  module Pokedata
    def readonly?
      true
    end

    def self.included(receiver)
      receiver.establish_connection "pokedex"
    end
  end

  class GamePokedex < ActiveRecord::Base
    include Pokedata
    self.table_name =  "pokedexes"
    
  end

  class PokemonDexNumber < ActiveRecord::Base
    include Pokedata
    belongs_to :pokemon
    belongs_to :pokedex, :class_name => "Pokedex::GamePokedex"
  end

  # Main Pokemon species model
  class Pokemon < ActiveRecord::Base
    include Pokedata

    def self.gen(num)
      where('generation_id <= ?', num)
    end

    def self.not_fully_evolved
      where('id in (select distinct from_pokemon_id from pokemon_evolution)')
    end

    def self.fully_evolved
      where('id not in (select distinct from_pokemon_id from pokemon_evolution)')
    end

    def self.default_forms
      where('id < 10000')
    end

    belongs_to :generation 
    belongs_to :evolution_chain
    belongs_to :pokemon_color, :foreign_key => 'color_id'
    belongs_to :pokemon_shape
    belongs_to :pokemon_habitat, :foreign_key => 'habitat_id'

    has_many :pokemon_stats

    has_and_belongs_to_many :egg_groups, :join_table => 'pokemon_egg_groups'
    has_and_belongs_to_many :types, :join_table => 'pokemon_types'
    has_and_belongs_to_many :abilities, -> { includes(:text).select("DISTINCT abilities.*") }, :join_table => 'pokemon_abilities'
    has_many :forms, :class_name => "Pokedex::PokemonForm", :foreign_key => "form_base_pokemon_id"
    has_one :form, :class_name => "Pokedex::PokemonForm", :foreign_key => "unique_pokemon_id"
    has_one :evolution, :foreign_key => 'from_pokemon_id'
    has_many :texts, :class_name => "Pokedex::PokemonName"
    has_one :text, -> { where(local_language_id: 9) }, :class_name => "Pokedex::PokemonName"
    has_many :dex_numbers, :class_name => "Pokedex::PokemonDexNumber"


    def abilities_by_gen(gen)
      if gen < 5
        self.abilities.gen(gen).where("pokemon_abilities.is_dream" => false)
      else
        self.abilities.gen(gen)
      end
    end

    def types_by_gen(gen)
      if gen < 5 && self.identifier == 'rotom'
        # Special type-change case for Rotom.
        Pokedex::Pokemon.find_by_identifier('rotom').types
      else
        self.types
      end
    end

    def name
      text.name
    end

    def shape; self.pokemon_shape; end

    # Generates a friendly hash of form { "Stat Name" => base_value }
    def base_stats
      bases = {}

      pokemon_stats.each do |pokestat|
        bases[pokestat.stat.identifier] = pokestat.base_stat
      end

      bases
    end

    def highest_base_stat
      base_stats.invert[base_stats.values.max]
    end

    def number(pokedex_id=1)
      if self.id >= 10000
        real_id = self.form ? self.form.form_base_pokemon_id : self.id
        PokemonDexNumber.where(pokemon_id: real_id, pokedex_id: pokedex_id).first.pokedex_number
      else
        self.dex_numbers.where(pokedex_id: pokedex_id).first.pokedex_number
      end
    end

    def icon
      bw_icon
    end

    def sugimori_path
      form = (self.form && self.form.identifier)
      "/assets/sugimori_art/%.3d#{form ? '-'+form : ''}.png" % self.number
    end

    def sugimori
      "<img class='sugimori' title='#{self.name}' src='#{sugimori_path}' />"
    end

    def bw_sprite_path
      "/assets/bw_sprites/#{self.number}#{self.form&&self.form.identifier&&"-#{self.form.identifier}"}.png"
    end

    def bw_sprite
      "<img class='pokesprite' title='#{self.name}' src='#{bw_sprite_path}' />"
    end

    def bw_icon
      if self.form && self.form.identifier
        "<img title='#{self.name}' src='/assets/bw_icons/#{self.number}-#{self.form.identifier}.png'>"
      else
        xpos = (self.id-1)%26
        ypos = (self.id-1)/26
        "<span title=\"#{self.name}\" class='pokeicon' style='background-position: #{-xpos*32}px #{-ypos*32}px;'></span>"
      end
    end

    # Returns path to the DP party icon for this species
    def dp_icon
      "dp_icons/%.3d.gif" % id
    end

    # Returns hash of HGSS overworld sprite frames paths
    def overworlds
      paths = {} 
      [:down, :up, :left, :right].each do |dir|
        paths[dir] = ["overworld/#{dir}/#{id}.png", "overworld/#{dir}/frame2/#{id}.png"]
      end
      paths
    end 

    def can_evolve?
      !Pokedex::Evolution.find_by_from_pokemon_id(self.id).nil?
    end

    def previous_evolution
      evo = Pokedex::Evolution.find_by_to_pokemon_id(id)
      evo.nil? ? nil : evo.from_pokemon
    end

    def can_breed?
      !is_baby && egg_groups.length > 0 && !egg_groups.include?(Pokedex::EggGroup.find_by_identifier('No Eggs'))
    end

    def can_breed_with?(species)
      return true if id == 132 || species.id == 132
      can_breed? && species.can_breed? && (egg_groups - species.egg_groups).length < egg_groups.length
    end

    ### Type stuff

    def has_type_modifier_ability?
      self.abilities.each.find { |abil| abil.type_modifier? }
    end

    def damage_factors(ability=nil, gen=5)
      Pokedex.damage_factors(self.types_by_gen(gen), ability, gen)
    end
  end

  # Defines an individual type of stat, e.g "HP"
  class Stat < ActiveRecord::Base
    include Pokedata

    belongs_to :damage_class
  end

  class PokemonShape < ActiveRecord::Base
    include Pokedata

    has_many :pokemon
  end

  class PokemonForm < ActiveRecord::Base
    include Pokedata

    belongs_to :form_base_pokemon, :class_name => "Pokedex::Pokemon"
    belongs_to :unique_pokemon, :class_name => "Pokedex::Pokemon"
    has_many :texts, :class_name => "Pokedex::PokemonFormName"
    has_one :text, -> { where(local_language_id: 9) }, :class_name => "Pokedex::PokemonFormName"

    def name; self.text.name; end
  end

  # Join table for Pokemon and Stats
  class PokemonStat < ActiveRecord::Base
    include Pokedata

    belongs_to :pokemon
    belongs_to :stat
  end

  # Join table for Pokemon and Abilities
  class PokemonAbility < ActiveRecord::Base
    include Pokedata

    belongs_to :pokemon
    belongs_to :ability
  end

  class PokemonFormName < ActiveRecord::Base
    include Pokedata

    def self.english
      where(local_language_id: 9)
    end

    belongs_to :pokemon
  end

  class PokemonName < ActiveRecord::Base
    include Pokedata

    def self.english
      where(local_language_id: 9)
    end

    belongs_to :pokemon
  end

  class AbilityName < ActiveRecord::Base
    include Pokedata

    belongs_to :ability
    #belongs_to :language
  end

  TYPE_MODIFIERS = ['dry-skin', 'water-absorb', 'flash-fire', 'heatproof', 'levitate', 'motor-drive', 'thick-fat', 'volt-absorb', 'lightningrod', 'storm-drain', 'sap-sipper']

  class Ability < ActiveRecord::Base
    include Pokedata

    def self.gen(num)
      where('generation_id <= ?', num)
    end

    has_many :ability_names
    has_one :text, :class_name => "Pokedex::AbilityName", :conditions => { :local_language_id => 9 }

    def self.type_modifiers
      where("identifier in ('#{TYPE_MODIFIERS.join("', '")}')")
    end

    def type_modifier?
      TYPE_MODIFIERS.include?(self.identifier)
    end

    def name
      self.text.name
    end

    has_and_belongs_to_many :pokemon, :join_table => 'pokemon_abilities'    
  end

  # Defines a Pokemon egg group
  class EggGroup < ActiveRecord::Base
    include Pokedata

    has_and_belongs_to_many :pokemon, :join_table => 'pokemon_egg_groups'
  end

  # Defines evolutionary transitions between Pokemon and their properties.
  class Evolution < ActiveRecord::Base
    include Pokedata

    self.table_name =  "pokemon_evolution"

    belongs_to :from_pokemon, :class_name => "Pokedex::Pokemon"
    belongs_to :to_pokemon, :class_name => "Pokedex::Pokemon"
  end

  # Defines a Pokemon evolution chain.
  class EvolutionChain < ActiveRecord::Base
  end

  # Defines a Pokemon type
  class Type < ActiveRecord::Base
    include Pokedata

    belongs_to :generation
    belongs_to :damage_class

    has_and_belongs_to_many :pokemon, :join_table => 'pokemon_types'

    def weaknesses
      Pokedex::TypeEfficacy.where(:target_type_id => self.id, :damage_factor => 200)
    end

    def resistances
      Pokedex::TypeEfficacy.where(:target_type_id => self.id, :damage_factor => 50)
    end

    def immunities
      Pokedex::TypeEfficacy.where(:target_type_id => self.id, :damage_factor => 0)
    end

    def damage_to(type)
      if type.is_a? String
        type = Pokedex::Type.find_by_identifier(type) || Pokedex::Type.find_by_abbreviation(type)
      end

      Pokedex::TypeEfficacy.where(:damage_type_id => self.id, :target_type_id => type.id).first
    end
  end

  # Defines the efficacy relationships among types
  class TypeEfficacy < ActiveRecord::Base
    include Pokedata

    self.table_name =  "type_efficacy"
    belongs_to :damage_type, :class_name => "Pokedex::Type"
    belongs_to :target_type, :class_name => "Pokedex::Type"
  end

  # Defines a generation of pokemon games
  class Generation < ActiveRecord::Base
    include Pokedata
  end

  class Nature < ActiveRecord::Base
    include Pokedata
  end

  class MoveName < ActiveRecord::Base
    include Pokedata
  end

  class Move < ActiveRecord::Base
    include Pokedata

    belongs_to :generation
    belongs_to :type
    belongs_to :effect, :class_name => "Pokedex::MoveEffect"

    has_many :names, :class_name => "Pokedex::MoveName"

    def name
      names.where(:local_language_id => 9).first.name
    end
  end

  class MoveEffect < ActiveRecord::Base
    include Pokedata


    has_many :moves
  end
end
