# frozen_string_literal: true

module FastSerializer
  # Serializer implementation for serializing an array of objects.
  # This class allows taking advantage of a single SerializationContext
  # for caching duplicate serializers.
  class ArraySerializer
    include Serializer

    serialize :array

    def initialize(object, options = nil)
      @_array = nil
      super(Array(object), options)
    end

    # @return [String]
    def cache_key
      if option(:serializer)
        array.collect(&:cache_key)
      else
        super
      end
    end

    # @return [Boolean]
    def cacheable?
      if option(:cacheable) || self.class.cacheable?
        true
      elsif option(:serializer)
        option(:serializer).cacheable?
      else
        super
      end
    end

    # @return [Numeric, Boolean]
    def cache_ttl
      if option(:cache_ttl)
        true
      elsif option(:serializer)
        option(:serializer).cache_ttl
      else
        super
      end
    end

    # @return [FastSerializer::Cache, Boolean]
    def cache
      if option(:cache)
        true
      elsif option(:serializer)
        option(:serializer).cache
      else
        super
      end
    end

    # @return [Hash]
    def as_json(*args)
      if array.nil?
        nil
      elsif array.empty?
        []
      else
        super[:array]
      end
    end

    undef :to_hash
    undef :to_h
    alias_method :to_a, :as_json

    protected

    def load_from_cache
      if cache
        values = cache.fetch_all(array, cache_ttl) { |serializer| serializer.as_json }
        {array: values}
      else
        load_hash
      end
    end

    private

    def array
      if @_array.nil?
        serializer = option(:serializer)
        if serializer
          serializer_options = option(:serializer_options)
          @_array = object.collect { |obj| serializer.new(obj, serializer_options) }
        else
          @_array = object
        end
      end
      @_array
    end
  end
end
