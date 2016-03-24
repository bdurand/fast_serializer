module FastSerializer
  # Base class for cache implementations for storing cacheable serializers.
  # Implementations must implement the +fetch+ method.
  class Cache
    def fetch(serializer, ttl, &block)
      raise NotImplementedError
    end
  end
end
