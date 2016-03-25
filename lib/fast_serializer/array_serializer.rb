module FastSerializer
  # Serializer implementation for serializing an array of objects.
  # This class allows taking advantage of a single SerializationContext
  # for caching duplicate serializers.
  class ArraySerializer
    include Serializer
    
    serialize :array
    
    def initialize(object, options = nil)
      super(Array(object), options)
    end
    
    def cache_key
      if option(:serializer)
        array.collect(&:cache_key)
      else
        super
      end
    end
    
    def cacheable?
      if option(:cacheable) || self.class.cacheable?
        true
      elsif option(:serializer)
        option(:serializer).cacheable?
      else
        super
      end
    end
    
    def cache_ttl
      if option(:cache_ttl)
        true
      elsif option(:serializer)
        option(:serializer).cache_ttl
      else
        super
      end
    end
    
    def cache
      if option(:cache)
        true
      elsif option(:serializer)
        option(:serializer).cache
      else
        super
      end
    end
    
    def as_json(*args)
      super[:array]
    end
    
    undef :to_hash
    undef :to_h
    alias :to_a :as_json
    
    private
    
    def array
      unless defined?(@_array)
        serializer = option(:serializer)
        if serializer
          serializer_options = option(:serializer_options)
          @_array = object.collect{|obj| serializer.new(obj, serializer_options)}
        else
          @_array = object
        end
      end
      @_array
    end
  end
end
