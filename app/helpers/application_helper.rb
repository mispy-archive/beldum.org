module ApplicationHelper
  def pokemon_selector(opts={})
    html = "<select class='pokeselect' name='species'>"
    html += memcache do
      pokemon = Pokedex::Pokemon.default_forms(:include => :text)
      pokemon.map do |poke|
        "<option value=\"#{poke.identifier}\">#{poke.name}</option>"
      end.join
    end
    html += "</select>"

    if opts[:selected]
      doc = Nokogiri(html)
      doc.css("option[value=#{opts[:selected]}]")[0].set_attribute('selected', '')
      html = doc.serialize(:save_with => Nokogiri::XML::Node::SaveOptions::AS_HTML)
    end

    raw html
  end

  def gender_symbol(gender) 
    if gender == 'female'
      raw "&#9792;"
    elsif gender == 'male'
      raw "&#9794;"
    else
      raw ""
    end
  end
end
