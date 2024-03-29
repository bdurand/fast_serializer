# frozen_string_literal: true

module FastSerializer
  # Models can include this module to define themselves as serializers. A serializer is used to wrap
  # an object and output a hash version of that object suitable for serialization to JSON or other formats.
  #
  # To define what fields to serialize on the wrapped object, the serializer class must call the +serialize+
  # class method:
  #
  #   class PersonSerializer
  #     include FastSerializer::Serializer
  #     serialize :id, :name
  #   end
  #
  # This sample serializer will output an object as a hash with keys {:id, :name}. The values for each field
  # is gotten by calling the corresponding method on the serializer object. By default, each serialized field
  # will automatically define a method that simply delegates to the wrapped object. So if you need provide special
  # handling for a field or serialize a virtual field that doesn't exist on the parent object, you just need to
  # implement the method on the serializer.
  #
  #   class PersonSerializer
  #     include FastSerializer::Serializer
  #     serialize :id, :name
  #
  #     def name
  #       "#{object.first_name} #{object.last_name}"
  #     end
  #   end
  #
  # Serializers can implement their own options for controlling details about how to serialize the object.
  #
  #   class PersonSerializer
  #     include FastSerializer::Serializer
  #     serialize :id, :name
  #
  #     def name
  #       if option(:last_first)
  #         "#{object.last_name}, #{object.first_name}"
  #       else
  #         "#{object.first_name} #{object.last_name}"
  #       end
  #     end
  #   end
  #
  #   serializer = PersonSerializer.new(person, :last_first => true)
  #
  # All serializers will honor options for :include (include optional fields), :exclude (exclude fields).
  #
  # Serializer can also be specified as cacheable. Cacheable serializer will store and fetch the serialized value
  # from a cache. In order to user caching you must set the cache implementation. This can either be done on a
  # global level (FastSerializer.cache) class level, or instance level (:cache option). Then you can specify
  # serializers to be cacheable. This can be done on a class level with the +cacheable+ directive or on an
  # instance level with the :cacheable option. A time to live can also be set at the same levels using +cache_ttl+.
  #
  # Serializers are designed to be reusable and must never have any internal state associated with them. Calling
  # +as_json+ on a serializer multiple times must always return the same value.
  #
  # Serializing a nil object will result in nil rather than an empty hash.
  module Serializer
    def self.included(base)
      base.extend(ClassMethods)
      base.extend(ArrayHelper) unless base.is_a?(FastSerializer::ArraySerializer)
    end

    # Return the wrapped object that is being serialized.
    attr_reader :object

    # Return the options hash (if any) that specified optional details about how to serialize the object.
    attr_reader :options

    module ClassMethods
      # Define one or more fields to include in the serialized object. Field values will be gotten
      # by calling the method of the same name on class including this module.
      #
      # Several options can be specified to control how the field is serialized.
      #
      # * as: Name to call the field in the serialized hash. Defaults to the same as the field name
      #   (withany ? stripped off the end for boolean fields). This option can only be specified
      #   for a single field.
      #
      # * optional: Boolean flag indicating if the field is optional in the serialized value (defaults to false).
      #   Optional fields are only included if the :include option to the +as_json+ method includes the field name.
      #
      # * delegate: Boolean flag indicating if the field call should be delegated to the wrapped object (defaults to true).
      #   When this is supplied, a method will be automatically defined on the serializer with the name of the field
      #   that simply then calls the same method on the wrapped object.
      #
      # * serializer: Class that should be used to serialize the field. If this option is specified, the field value will
      #   be serialized using the specified serializer class which should include this module. Otherwise, the +as_json+
      #   method will be called on the field class.
      #
      # * serializer_options: Options that should be used for serializing the field for when the :serializer option
      #   has been specified.
      #
      # * enumerable: Boolean flag indicating if the field is enumerable (defaults to false). This option is only
      #   used if the :serializer option has been set. If the field is marked as enumerable, then the value will be
      #   serialized as an array with each element wrapped in the specified serializer.
      #
      # * condition: Block or method name that will be called at runtime bound to the serializer that will
      #   determine if the attribute will be included or not.
      #
      # Subclasses will inherit all of their parent classes serialized fields. Subclasses can override fields
      # defined on the parent class by simply defining them again.
      #
      # @param fields [Array<Symbol, Hash>] the fields to serialize. If the last argument is a hash, it will be
      #   treated as options for the serialized fields.
      # @return [void]
      def serialize(*fields)
        options = {}
        if fields.size > 1 && fields.last.is_a?(Hash)
          fields.last.each do |key, value|
            options[key.to_sym] = value
          end
          fields = fields[0, fields.size - 1]
        end
        as = options.delete(:as)
        optional = options.delete(:optional) || false
        delegate = options.delete(:delegate) || true
        enumerable = options.delete(:enumerable) || false
        serializer = options.delete(:serializer)
        serializer_options = options.delete(:serializer_options)
        condition = options.delete(:if)

        unless options.empty?
          raise ArgumentError.new("Unsupported serialize options: #{options.keys.join(", ")}")
        end

        if as && fields.size > 1
          raise ArgumentError.new("Cannot specify :as argument with multiple fields to serialize")
        end

        fields.each do |field|
          name = as
          if name.nil? && field.to_s.end_with?("?")
            name = field.to_s.chomp("?")
          end

          field = field.to_sym
          attribute = (name || field).to_sym
          add_field(attribute, optional: optional, serializer: serializer, serializer_options: serializer_options, enumerable: enumerable, condition: condition)

          if delegate && !method_defined?(attribute)
            define_delegate(attribute, field)
          end
        end
      end

      # Remove a field from being serialized. This can be useful in subclasses if they need to remove a
      # field defined by the parent class.
      #
      # @param fields [Array<Symbol>] the fields to remove
      def remove(*fields)
        remove_fields = fields.collect(&:to_sym)
        field_list = []
        serializable_fields.each do |existing_field|
          field_list << existing_field unless remove_fields.include?(existing_field.name)
        end
        @serializable_fields = field_list.freeze
      end

      # Specify the cacheability of the serializer.
      #
      # You can specify the cacheable state (defaults to true) of the class. Subclasses will inherit the
      # cacheable state of their parent class, so if you have non-cacheable serializer subclassing a
      # cacheable parent class, you can call <tt>cacheable false</tt> to override the parent behavior.
      #
      # You can also specify the cache time to live (ttl) in seconds and the cache implementation to use.
      # Both of these values are inherited on subclasses.
      #
      # @param cacheable [Boolean] pass false if the serializer is not cacheable
      # @param ttl [Numeric] the time to live in seconds for a cacheable serializer
      # @param cache [FastSerializer::Cache] the cache implementation to use for a cacheable serializer
      def cacheable(cacheable = true, ttl: nil, cache: nil)
        @cacheable = cacheable
        self.cache_ttl = ttl if ttl
        self.cache = cache if cache
      end

      # Return true if the serializer class is cacheable.
      #
      # @return [Boolean]
      def cacheable?
        unless defined?(@cacheable)
          @cacheable = superclass.cacheable? if superclass.respond_to?(:cacheable?)
        end
        !!@cacheable
      end

      # Return the time to live in seconds for a cacheable serializer.
      #
      # @return [Numeric]
      def cache_ttl
        if defined?(@cache_ttl)
          @cache_ttl
        elsif superclass.respond_to?(:cache_ttl)
          superclass.cache_ttl
        end
      end

      # Set the time to live on a cacheable serializer.
      #
      # @param value [Numeric] the time to live in seconds
      # @return [void]
      def cache_ttl=(value)
        @cache_ttl = value
      end

      # Get the cache implemtation used to store cacheable serializers.
      #
      # @return [FastSerializer::Cache]
      def cache
        if defined?(@cache)
          @cache
        elsif superclass.respond_to?(:cache)
          superclass.cache
        else
          FastSerializer.cache
        end
      end

      # Set the cache implementation used to store cacheable serializers.
      #
      # @param cache [FastSerializer::Cache]
      # @return [void]
      def cache=(cache)
        if defined?(ActiveSupport::Cache::Store) && cache.is_a?(ActiveSupport::Cache::Store)
          cache = Cache::ActiveSupportCache.new(cache)
        end
        @cache = cache
      end

      # :nodoc:
      def new(object, options = nil)
        context = SerializationContext.current
        if context
          # If there's a context in scope this will load duplicate entries from the context rather than creating new instances.
          context.load(self, object, options)
        else
          super
        end
      end

      # Return a list of the SerializedFields defined for the class.
      #
      # @return [Array<FastSerializer::SerializedField>]
      def serializable_fields
        unless defined?(@serializable_fields) && @serializable_fields
          fields = superclass.send(:serializable_fields).dup if superclass.respond_to?(:serializable_fields)
          fields ||= []
          @serializable_fields = fields.freeze
        end
        @serializable_fields
      end

      private

      # Add a field to be serialized.
      def add_field(name, optional:, serializer:, serializer_options:, enumerable:, condition:)
        name = name.to_sym
        if condition.is_a?(Proc)
          include_method_name = "__include_#{name}?".to_sym
          define_method(include_method_name, condition)
          private include_method_name
          condition = include_method_name
        end

        field = SerializedField.new(name, optional: optional, serializer: serializer, serializer_options: serializer_options, enumerable: enumerable, condition: condition)

        # Add the field to the frozen list of fields.
        field_list = []
        added = false
        serializable_fields.each do |existing_field|
          field_list << if existing_field.name == name
            field
          else
            existing_field
          end
        end
        field_list << field unless added
        @serializable_fields = field_list.freeze
      end

      # Define a delegate method name +attribute+ that invokes the +field+ method on the wrapped object.
      def define_delegate(attribute, field)
        define_method(attribute) { object.send(field) }
      end
    end

    module ArrayHelper
      # Helper method to serialize an array of values using this serializer.
      def array(values, options = nil)
        options = (options ? options.merge(serializer: self) : {serializer: self})
        FastSerializer::ArraySerializer.new(values, options)
      end
    end

    # Create a new serializer for the specified object.
    #
    # Options can be passed in to control how the object is serialized. Options supported by all Serializers:
    #
    # * :include - Field or array of optional field names that should be included in the serialized object.
    # * :exclude - Field or array of field names that should be excluded from the serialized object.
    # * :cacheable - Override the cacheable behavior set on the class.
    # * :cache_ttl - Override the cache ttl set on the class.
    # * :cache - Override the cache implementation set on the class.
    def initialize(object, options = nil)
      @object = object
      @options = options
      @cache = options[:cache] if options
      if @cache && defined?(ActiveSupport::Cache::Store) && cache.is_a?(ActiveSupport::Cache::Store)
        @cache = Cache::ActiveSupportCache.new(@cache)
      end
      @_serialized = nil
    end

    # Serialize the wrapped object into a format suitable for passing to a JSON parser.
    def as_json(*args)
      return nil unless object
      @_serialized ||= (cacheable? ? load_from_cache : load_hash).freeze
      @_serialized
    end

    alias_method :to_hash, :as_json
    alias_method :to_h, :as_json

    # Convert the wrapped object to JSON format.
    def to_json(options = {})
      if defined?(MultiJson)
        MultiJson.dump(as_json, options)
      else
        JSON.dump(as_json)
      end
    end

    # Fetch the specified option from the options hash.
    def option(name)
      @options[name] if @options
    end

    def scope
      option(:scope)
    end

    # Return true if this serializer is cacheable.
    def cacheable?
      option(:cacheable) || self.class.cacheable?
    end

    # Return the cache implementation where this serializer can be stored.
    def cache
      @cache || self.class.cache
    end

    # Return the time to live in seconds this serializer can be cached for.
    def cache_ttl
      option(:cache_ttl) || self.class.cache_ttl
    end

    # Returns a array of the elements that make this serializer unique. The
    # key is an array made up of the serializer class name, wrapped object, and
    # serialization options hash.
    def cache_key
      object_cache_key = (object.respond_to?(:cache_key) ? object.cache_key : object)
      [self.class.name, object_cache_key, options_cache_key(options)]
    end

    # :nodoc:
    def ==(other)
      other.instance_of?(self.class) && @object == other.object && @options == other.options
    end
    alias_method :eql?, :==

    protected

    # Load the hash that will represent the wrapped object as a serialized object.
    def load_hash
      hash = {}
      include_fields = included_optional_fields
      excluded_fields = excluded_regular_fields
      SerializationContext.use do
        self.class.serializable_fields.each do |field|
          name = field.name

          if field.optional?
            next unless include_fields&.include?(name)
          end
          next if excluded_fields && excluded_fields[name] == true
          condition = field.condition
          next if condition && !send(condition)

          value = field.serialize(send(name), serializer_options(name))
          hash[name] = value
        end
      end
      hash
    end

    def serializer_options(name)
      opts = options
      return nil unless opts
      if opts && (opts.include?(:include) || opts.include?(:exclude))
        opts = opts.dup
        include_options = opts[:include]
        if include_options.is_a?(Hash)
          include_options = include_options[name.to_sym]
          opts[:include] = include_options if include_options
        end
        exclude_options = options[:exclude]
        if exclude_options.is_a?(Hash)
          exclude_options = exclude_options[name.to_sym]
          opts[:exclude] = exclude_options if exclude_options
        end
      end
      opts
    end

    # Load the hash that will represent the wrapped object as a serialized object from a cache.
    def load_from_cache
      if cache
        cache.fetch(self, cache_ttl) do
          load_hash
        end
      else
        load_hash
      end
    end

    private

    def options_cache_key(options)
      return nil if options.nil?
      if options.respond_to?(:cache_key)
        options.cache_key
      elsif options.is_a?(Hash)
        hash_key = {}
        options.each do |key, value|
          hash_key[key] = options_cache_key(value)
        end
        hash_key
      elsif options.is_a?(Enumerable)
        options.collect { |option| options_cache_key(option) }
      else
        options
      end
    end

    # Return a list of optional fields to be included in the output from the :include option.
    def included_optional_fields
      normalize_field_list(option(:include))
    end

    # Return a list of fields to be excluded from the output from the :exclude option.
    def excluded_regular_fields
      normalize_field_list(option(:exclude))
    end

    def normalize_field_list(vals)
      return nil if vals.nil?
      if vals.is_a?(Hash)
        hash = nil
        vals.each do |key, values|
          if hash || !key.is_a?(Symbol)
            hash ||= {}
            hash[key.to_sym] = values
          end
        end
        vals = hash if hash
      else
        hash = {}
        Array(vals).each do |key|
          hash[key.to_sym] = true
        end
        vals = hash
      end
      vals
    end
  end
end
