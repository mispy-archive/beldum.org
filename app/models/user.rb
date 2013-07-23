require 'open-uri'
require 'geonames'

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  has_many :todo_items

  def timezone
    time_zone = nil

    ip = current_sign_in_ip || last_sign_in_ip
    memcache ip do 
      location = open("http://api.hostip.info/get_html.php?ip=#{ip}&position=true")
      if location.string =~ /Latitude: (.+?)\nLongitude: (.+?)\n/
        timezone = Geonames::WebService.timezone($1, $2)
        time_zone = ActiveSupport::TimeZone.new(timezone.timezone_id) unless timezone.nil?
      end
    end

    time_zone
  end
end
