require 'memcache'
require 'memcache_util'


CACHE   = MemCache.new 'localhost:11211', :namespace => "#{RAILS_ENV}_netdb", :debug => true, :compression => true

if __FILE__ == $0
  # TODO Generated stub
end