require 'json'
require 'time'
require 'date'

module FastSerializer
  require_relative 'fast_serializer/cache'
  require_relative 'fast_serializer/cache/active_support_cache'
  require_relative 'fast_serializer/serialization_context'
  require_relative 'fast_serializer/serialized_field'
  require_relative 'fast_serializer/serializer'
  require_relative 'fast_serializer/array_serializer'
  
  class << self
    # Get the global cache implementation used for storing cacheable serializers.
    def cache
      @cache if defined?(@cache)
    end
  
    # Set the global cache implementation used for storing cacheable serializers.
    # The cache implementation should implement the +fetch+ method as defined in 
    # FastSerializer::Cache. By default no cache is set so caching won't do anything.
    #
    # In a Rails app, you can initialize the cache by simply passing in the value :rails
    # to use the default Rails.cache.
    def cache=(cache)
      cache = Cache::ActiveSupportCache.new(Rails.cache) if cache == :rails
      @cache = cache
    end
  end
end
