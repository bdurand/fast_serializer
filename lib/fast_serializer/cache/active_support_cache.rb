module FastSerializer
  # ActiveSupport compatible cache implementation.
  class Cache::ActiveSupportCache < Cache
    attr_reader :cache
    
    def initialize(cache)
      @cache = cache
    end
    
    def fetch(serializer, ttl, &block)
      exists = !!@cache.read(serializer.cache_key)
      @cache.fetch(serializer.cache_key, :expires_in => ttl, &block)
    end
    
    def fetch_all(serializers, ttl)
      @cache.fetch_multi(*serializers) do |serializer|
        yield(serializer)
      end
    end
  end
end
