module Synergy
  class << self
    def calculate(pokes, abilities=[], opts={})
        gen = opts[:gen] || 5

        scores = [0, 0]
        reasons = [[], []]

        matches = pokes.each_with_index.map { |poke, i| poke.damage_factors(abilities[i], gen) }

        needed = matches.map { |dfs|
          total = 0.0
          dfs.each do |type, fac|
            if !fac.is_a?(String) && fac > 100.0
              total += (Math.log(fac/25)/Math.log(2) - 2)
            end
          end
          total
        }

        matches[0].keys.each do |type|
          factors = [matches[0][type], matches[1][type]]

          # Compound resistance scale 
          compfacs = factors.map { |fac|
            if fac == 0; 3.0
            elsif fac == 'Absorb'; 4.0
            elsif fac == 'Power Up'; 4.0
            else
              (Math.log(fac/25)/Math.log(2) - 2)*-1
            end / 2.0
          }

          changes = [nil, nil]

          if compfacs[0] < 0 && compfacs[1] > 0
            changes[1] = ((compfacs[0]-compfacs[1]).abs/needed[0])*100 # Bonus for weakness/resistance
          elsif compfacs[1] < 0 && compfacs[0] > 0
            changes[0] = ((compfacs[1]-compfacs[0]).abs/needed[1])*100 # Bonus for resistance/weakness
          elsif compfacs[0] < 0 && compfacs[1] < 0
            changes[0] = ((-(compfacs[0]+compfacs[1]).abs)/needed[1])*100 # Penalty for weakness/weakness
            changes[1] = ((-(compfacs[1]+compfacs[0]).abs)/needed[0])*100
          end

          changes.each_with_index do |change, i|
            unless change.nil?
              scores[i] += change
              reasons[i] << { :type => type, :factor => factors[i] }
            end
          end
        end

        return { :pokemon => pokes, :abilities => abilities, :scores => scores, :reasons => reasons }
    end

    def all(subject, opts={})
      synergies = []

      opts[:gen] ||= 5
      opts[:against] ||= Pokedex::Pokemon.gen(opts[:gen]).find(:all, :include => [:abilities, :types])
      
      opts[:against].each do |poke|
        (poke.has_type_modifier_ability? ? poke.abilities_by_gen(opts[:gen]) : [nil]).each do |pabil|
            synergies << Synergy.calculate([subject, poke], [opts[:ability], pabil], opts)
        end
      end

      synergies
    end
  end
end
