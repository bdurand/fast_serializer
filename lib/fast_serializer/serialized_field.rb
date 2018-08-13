module FastSerializer
  # Data structure used internally for maintaining a field to be serialized.
  class SerializedField
    attr_reader :name, :condition

    def initialize(name, optional: false, serializer: nil, serializer_options: nil, enumerable: false, condition: nil)
      @name = name
      @optional = !!optional
      @condition = condition
      if serializer
        @serializer = serializer
        @serializer_options = serializer_options
        @enumerable = enumerable
      end
    end

    def optional?
      @optional
    end

    # Wrap a value in the serializer if one has been set. Otherwise just returns the raw value.
    def serialize(value, options = nil)
      if value && @serializer
        serializer = nil
        if @enumerable
          serializer = ArraySerializer.new(value, :serializer => @serializer, :serializer_options => serializer_options(options))
        else
          serializer = @serializer.new(value, serializer_options(options))
        end
        context = SerializationContext.current
        if context
          context.with_reference(value){ serializer.as_json }
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
        if value.is_a?(Hash) && merge_value.is_a?(Hash)
          retval[key] = deep_merge(value, merge_value)
        else
          retval[key] = merge_value
        end
      end
      retval
    end

    # Convert the value to primitive data types: string, number, boolean, symbol, time, date, array, hash.
    def serialize_value(value)
      if value.is_a?(String) || value.is_a?(Numeric) || value == nil || value == true || value == false || value.is_a?(Time) || value.is_a?(Date) || value.is_a?(Symbol)
        value
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
          hash = value.dup unless hash
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
          array = value.dup unless array
          array[i] = val
        end
      end
      array || value
    end
  end
end
