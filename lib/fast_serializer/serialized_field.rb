# frozen_string_literal: true

module FastSerializer
  # Data structure used internally for maintaining a field to be serialized.
  class SerializedField
    attr_reader :name, :condition

    # Create a new serialized field.
    #
    # @param name [Symbol] the name of the field
    # @param optional [Boolean] whether the field is optional
    # @param serializer [Class] the serializer to use for the field
    # @param serializer_options [Hash] the options to pass to the serializer
    # @param enumerable [Boolean] whether the field is enumerable
    # @param condition [Proc] a condition to determine whether the field should be serialized
    def initialize(name, optional: false, serializer: nil, serializer_options: nil, enumerable: false, condition: nil)
      @name = name.to_sym
      @optional = !!optional
      @condition = condition
      if serializer
        @serializer = serializer
        @serializer_options = serializer_options
        @enumerable = enumerable
      end
    end

    # @return [Boolean] true if the field is optional
    def optional?
      @optional
    end

    # Wrap a value in the serializer if one has been set. Otherwise just returns the raw value.
    #
    # @param value [Object] the value to serialize
    # @param options [Hash] the options to pass to the serializer
    # @return [Object] the serialized value
    def serialize(value, options = nil)
      if value && @serializer
        serializer = nil
        serializer = if @enumerable
          ArraySerializer.new(value, serializer: @serializer, serializer_options: serializer_options(options))
        else
          @serializer.new(value, serializer_options(options))
        end
        context = SerializationContext.current
        if context
          context.with_reference(value) { serializer.as_json }
        else
          serializer.as_json
        end
      else
        serialize_value(value)
      end
    end

    private

    def serializer_options(options)
      if options
        if @serializer_options
          deep_merge(@serializer_options, options)
        else
          options
        end
      else
        @serializer_options
      end
    end

    def deep_merge(hash, merge_hash)
      retval = {}
      merge_hash.each do |key, merge_value|
        value = hash[key]
        retval[key] = if value.is_a?(Hash) && merge_value.is_a?(Hash)
          deep_merge(value, merge_value)
        else
          merge_value
        end
      end
      retval
    end

    # Convert the value to primitive data types: string, number, boolean, symbol, time, date, array, hash.
    def serialize_value(value)
      if value.is_a?(String) || value.is_a?(Numeric) || value.nil? || value == true || value == false || value.is_a?(Symbol)
        value
      elsif value.is_a?(Time) || value.is_a?(Date)
        if defined?(ActiveSupport::TimeWithZone) && value.is_a?(ActiveSupport::TimeWithZone)
          value.to_time
        else
          value
        end
      elsif value.is_a?(Hash)
        serialize_hash(value)
      elsif value.is_a?(Enumerable)
        serialize_enumerable(value)
      elsif value.respond_to?(:as_json)
        value.as_json
      elsif value.respond_to?(:to_hash)
        value.to_hash
      elsif value.respond_to?(:to_h)
        value.to_h
      else
        value
      end
    end

    def serialize_hash(value)
      hash = nil
      value.each do |k, v|
        val = serialize_value(v)
        if val.object_id != v.object_id
          hash ||= value.dup
          hash[k] = val
        end
      end
      hash || value
    end

    def serialize_enumerable(value)
      array = nil
      value.each_with_index do |v, i|
        val = serialize_value(v)
        if val.object_id != v.object_id
          array ||= value.dup
          array[i] = val
        end
      end
      array || value
    end
  end
end
