require 'memcache'

Cache = MemCache.new('127.0.0.1')

def memcache(key=nil, &b)
  caller_file = caller[0].split(':')[0]
  fullkey = Digest::SHA1.hexdigest("#{caller[0]}-#{File.mtime(caller_file).to_i}-#{key.nil? ? '' : Marshal.dump(key)}")
  cached = Cache.get(fullkey)
  return cached if cached
  val = yield
  Cache.set fullkey, val
  val
end

# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Beldumlabs::Application.initialize!
