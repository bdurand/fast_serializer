module FastSerializer
  # Data structure used internally for maintaining a field to be serialized.
  class SerializedField
    attr_reader :name

    def initialize(name, optional: false, serializer: nil, serializer_options: nil, enumerable: false)
      @name = name
      @optional = !!optional
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
    def serialize(value)
      if value && @serializer
        serializer = nil
        if @enumerable
          serializer = ArraySerializer.new(value, :serializer => @serializer, :serializer_options => @serializer_options)
        else
          serializer = @serializer.new(value, @serializer_options)
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

    # Convert the value to primitive data types: string, number, boolean, symbol, time, date, array, hash.
    def serialize_value(value)
      if value.is_a?(String) || value.is_a?(Numeric) || value == nil || value == true || value == false || value.is_a?(Time) || value.is_a?(Date) || value.is_a?(Symbol)
        value
      elsif value.is_a?(Hash)
        hash = nil
        value.each do |k, v|
          val = serialize_value(v)
          if val.object_id != v.object_id
            hash = value.dup unless hash
            hash[k] = val
          end
        end
        hash || value
      elsif value.is_a?(Enumerable)
        array = nil
        value.each_with_index do |v, i|
          val = serialize_value(v)
          if val.object_id != v.object_id
            array = value.dup unless array
            array[i] = val
          end
        end
        array || value
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

  end
end
