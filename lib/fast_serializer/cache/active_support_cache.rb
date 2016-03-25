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
      keys = []
      key_map = {}
      serializers.each do |serializer|
        key = serializer.cache_key
        keys << key
        key_map[key] = serializer
      end
      values = @cache.fetch_multi(keys) do |key|
        serializer = key_map[key]
        yield(serializer)
      end
      keys.collect{|key| values[key]}
    end
  end
end
