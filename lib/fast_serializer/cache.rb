module FastSerializer
  # Base class for cache implementations for storing cacheable serializers.
  # Implementations must implement the +fetch+ method.
  class Cache
    def fetch(serializer, ttl, &block)
      raise NotImplementedError
    end
    
    # Fetch multiple serializers from the cache. The default behavior is just
    # to call +fetch+ with each serializer. Implementations may optimize this
    # if the cache can return multiple values at once.
    # 
    # The block to this method will be yielded to with each uncached serializer.
    def fetch_all(serializers, ttl)
      serializers.collect do |serializer|
        fetch(serializer, ttl) do
          yield(serializer)
        end
      end
    end
  end
end
