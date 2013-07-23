# Load the rails application.
require File.expand_path('../application', __FILE__)

# Initialize the rails application.
BeldumOrg::Application.initialize!

Cache = Rails.cache

def memcache(key=nil, &b)
  caller_file = caller[0].split(':')[0]
  fullkey = Digest::SHA1.hexdigest("#{caller[0]}-#{File.mtime(caller_file).to_i}-#{key.nil? ? '' : Marshal.dump(key)}")
  cached = Cache.read(fullkey)
  return cached if cached
  val = yield
  Cache.write fullkey, val
  val
end
