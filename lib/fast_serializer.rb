# frozen_string_literal: true

require "json"
require "time"
require "date"

module FastSerializer
  require_relative "fast_serializer/cache"
  require_relative "fast_serializer/cache/active_support_cache"
  require_relative "fast_serializer/serialization_context"
  require_relative "fast_serializer/serialized_field"
  require_relative "fast_serializer/serializer"
  require_relative "fast_serializer/array_serializer"

  class << self
    @cache = nil

    # Get the global cache implementation used for storing cacheable serializers.
    attr_reader :cache

    # Set the global cache implementation used for storing cacheable serializers.
    # The cache implementation should implement the +fetch+ method as defined in
    # FastSerializer::Cache. By default no cache is set so caching won't do anything.
    #
    # In a Rails app, you can initialize the cache by simply passing in the value :rails
    # to use the default Rails.cache. You can also directly pass in an ActiveSupportCache::Store.
    #
    # @param cache [FastSerializer::Cache, ActiveSupport::Cache::Store, Symbol] the cache to use
    def cache=(cache)
      if cache == :rails
        cache = Cache::ActiveSupportCache.new(Rails.cache)
      elsif defined?(ActiveSupport::Cache::Store) && cache.is_a?(ActiveSupport::Cache::Store)
        cache = Cache::ActiveSupportCache.new(cache)
      end
      if cache && !cache.is_a?(FastSerializer::Cache)
        raise ArgumentError.new("The cache must be a FastSerializer::Cache or ActiveSupport::Cache::Store")
      end
      @cache = cache
    end
  end

  # Exception raised when there is a circular reference serializing a model dependent on itself.
  class CircularReferenceError < StandardError
    def initialize(model)
      super("Circular refernce on #{model.inspect}")
    end
  end
end
