class SynergyController < ApplicationController
  caches_action :index, :cache_path => proc { |c| c.params }, :if => proc { |c| c.params[:species] }

  def index
    if params[:species].nil? || params[:species].empty?
      # If a species isn't specified, show a random one.
      @subject = Pokedex::Pokemon.fully_evolved.sample
    else
      @subject = Pokedex::Pokemon.find_by_identifier(params[:species])
    end

    if params[:form] && !params[:form].empty?
      # Form data can be a bit tricky. Don't use a form relation if it doesn't have a unique_pokemon_id.
      @form = Pokedex::PokemonForm.find_by_identifier_and_form_base_pokemon_id(params[:form], @subject.id)
      @subject = @form.unique_pokemon if @form.unique_pokemon
    end

    @gen = params[:gen] ? params[:gen].to_i : 5

    @ability = params[:ability] && Pokedex::Ability.find_by_identifier(params[:ability])

    if @ability.nil? && @subject.has_type_modifier_ability?
      @ability = @subject.abilities_by_gen(@gen).first
    end

    @tier = Tier.find_by_identifier_and_generation_id(params[:tier], @gen)

    if @tier
      pokemon = @tier.pokemon
    else
      pokemon = Pokedex::Pokemon.scoped
    end

    pokemon = pokemon.gen(@gen)

    pokemon = pokemon.fully_evolved unless @tier || params[:nfe] == 'on'

    pokemon = pokemon.find(:all, :include => [{ :abilities => [:text, :ability_names] }, :types, :text, :form])

    synergies = Synergy.all(@subject, :ability => @ability, :against => pokemon, :gen => @gen)
    
    # We use this to aggregate common results.
    @table = {}

    synergies.each do |result|
      result[:reasons] = result[:reasons].map { |r| spanify_reasons(r) }

      key = [result[:reasons][1], result[:scores][1].round, ((result[:scores][1]+result[:scores][0])/2).round, result[:scores][0].round, result[:reasons][0]]

      if @table[key]
        pokes_by_abil = @table[key][0]
      else
        pokes_by_abil = {}
        newrow = [pokes_by_abil] + key + [result[:pokemon][0]]
        @table[key] = newrow
      end

      pokes_by_abil[result[:abilities][1]] ||= []
      pokes_by_abil[result[:abilities][1]] << result[:pokemon][1]
    end

    @form = @subject.form
  end

  def spritesheet_test
  end

  private

  def spanify_reasons(reasons)
      reasons.map do |reason|
        factor = reason[:factor]
        factor = factor.round if factor.is_a? Float
        type = reason[:type].capitalize

        case factor
          when 0 then "<span class='immunity'>Immune to #{type}</span>"
          when 25 then "<span class='compound-resist'>4x Resists #{type}</span>"
          when 50 then "<span class='resist'>Resists #{type}</span>"
          when 200 then "<span class='weakness'>Weak to #{type}</span>"
          when 400 then "<span class='compound-weakness'>4x Weak to #{type}</span>"
          when 'Absorb' then "<span class='absorb'>Absorbs #{type}</span>"
          when 'Power Up' then "<span class='power-up'>Powers Up with #{type}</span>"
          else "<span class='#{factor > 100.0 ? 'weakness' : 'resist'}'>#{factor}% Damage from #{type}</span>"
        end
      end
  end
end
