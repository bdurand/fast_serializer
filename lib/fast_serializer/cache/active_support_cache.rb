# frozen_string_literal: true

module FastSerializer
  # ActiveSupport compatible cache implementation.
  class Cache::ActiveSupportCache < Cache
    attr_reader :cache
    
    def initialize(cache)
      @cache = cache
    end
    
    def fetch(serializer, ttl)
      @cache.fetch(serializer.cache_key, :expires_in => ttl) do
        yield(serializer)
      end
    end
    
    def fetch_all(serializers, ttl)
      results = @cache.fetch_multi(*serializers){|serializer| yield(serializer)}
      if results.is_a?(Hash)
        serializers.collect{|serializer| results[serializer]}
      else
        results
      end
    end
  end
end
