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
      #
      # @return [Object] The return value of the block.
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
      #
      # @return [FastSerializer::SerializationContext, nil]
      def current
        Thread.current[:fast_serializer_context]
      end
    end

    def initialize
      @cache = nil
      @references = nil
    end

    # Returns a serializer from the context cache if one has already
    # been created. Otherwise creates the serializer and adds it to the
    # cache.
    #
    # @param serializer_class [Class] The serializer class to create.
    # @param object [Object] The object to serialize.
    # @param options [Hash] The options to pass to the serializer.
    # @return [FastSerializer::Serializer] The serializer.
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
    #
    # @param object [Object] The object to check for circular references.
    # @yield The block to execute.
    # @return The return value of the block.
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
