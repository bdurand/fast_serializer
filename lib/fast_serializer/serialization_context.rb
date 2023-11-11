# frozen_string_literal: true

module FastSerializer
  # This class provides a context for creating serializers that allows
  # duplicate serializers to be re-used within the context. This then
  # short circuits the serialization process on the duplicates.
  class SerializationContext
    class << self
      # Use a context or create one for use within a block. Any serializers
      # based on the same object with the same options within the block will be
      # re-used instead of creating duplicates.
      def use
        if Thread.current[:fast_serializer_context]
          yield
        else
          begin
            Thread.current[:fast_serializer_context] = new
            yield
          ensure
            Thread.current[:fast_serializer_context] = nil
          end
        end
      end

      # Return the current context or nil if none is in use.
      def current
        Thread.current[:fast_serializer_context]
      end
    end

    def initialize
      @cache = nil
      @references = nil
    end

    # Returns a serializer from the context cache if a duplicate has already
    # been created. Otherwise creates the serializer and adds it to the
    # cache.
    def load(serializer_class, object, options = nil)
      key = [serializer_class, object, options]
      serializer = nil
      if @cache
        serializer = @cache[key]
      end

      unless serializer
        serializer = serializer_class.allocate
        serializer.send(:initialize, object, options)
        @cache = {}
        @cache[key] = serializer
      end

      serializer
    end

    # Maintain reference stack to avoid circular references.
    def with_reference(object)
      if @references
        raise CircularReferenceError.new(object) if @references.include?(object)
      else
        @references = []
      end

      begin
        @references.push(object)
        yield
      ensure
        @references.pop
      end
    end
  end
end
