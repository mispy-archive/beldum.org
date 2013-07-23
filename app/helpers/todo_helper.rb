module TodoHelper
  def appropriate_greeting
    timezone = current_user.timezone
    
    return "Greetings" if timezone.nil?

    hour = timezone.now.hour
    
    if (1..4).include?(hour)
      "A strange hour indeed"
    elsif (4..12).include?(hour)
      "Good morning"
    elsif (12..17).include?(hour)
      "Good afternoon"
    elsif (17..23).include?(hour) || (0..1).include?(hour)
      "Good evening"
    end
      
  end
end
