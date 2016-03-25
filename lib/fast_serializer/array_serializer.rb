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
    
    def as_json(*args)
      super[:array]
    end
    
    undef :to_hash
    undef :to_h
    alias :to_a :as_json
    
    private
    
    def array
      serializer = option(:serializer)
      if serializer
        serializer_options = option(:serializer_options)
        object.collect{|obj| serializer.new(obj, serializer_options)}
      else
        object
      end
    end
  end
end
