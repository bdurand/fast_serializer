# frozen_string_literal: true

module FastSerializer
  # Base class for cache implementations for storing cacheable serializers.
  # Implementations must implement the +fetch+ method.
  class Cache
    # Fetch a serialized value from the cache. If the value is not cached, the
    # block will be yielded to to generate the value.
    #
    # @param serializer [FastSerializer::Serializer] The serializer to fetch the value for.
    # @param ttl [Numeric] The time to live for the cached value.
    # @yieldparam serializer [FastSerializer::Serializer] The serializer to generate the value for.
    # @return [Object] The serialized value.
    def fetch(serializer, ttl, &block)
      raise NotImplementedError
    end

    # Fetch multiple serializers from the cache. The default behavior is just
    # to call +fetch+ with each serializer. Implementations may optimize this
    # if the cache can return multiple values at once.
    #
    # The block to this method will be yielded to with each uncached serializer.
    #
    # @param serializers [Array<FastSerializer::Serializer>] The serializers to fetch the values for.
    # @param ttl [Numeric] The time to live for the cached values.
    # @yieldparam serializer [FastSerializer::Serializer] A serializer to generate the value for.
    # @return [Array<Object>] The serialized values.
    def fetch_all(serializers, ttl)
      serializers.collect do |serializer|
        fetch(serializer, ttl) do
          yield(serializer)
        end
      end
    end
  end
end
