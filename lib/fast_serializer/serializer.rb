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
      # Subclasses will inherit all of their parent classes serialized fields. Subclasses can override fields
      # defined on the parent class by simply defining them again.
      def serialize(*fields, as: nil, optional: false, delegate: true, serializer: nil, serializer_options: nil, enumerable: false)
        if as && fields.size > 1
          raise ArgumentError.new("Cannot specify :as argument with multiple fields to serialize")
        end
        
        fields.each do |field|
          name = as
          if name.nil? && field.to_s.end_with?("?".freeze)
            name = field.to_s.chomp("?".freeze)
          end
          
          field = field.to_sym
          attribute = (name || field).to_sym
          add_field(attribute, optional: optional, serializer: serializer, serializer_options: serializer_options, enumerable: enumerable)
          
          if delegate && !method_defined?(attribute)
            define_delegate(attribute, field)
          end
        end
      end
      
      # Remove a field from being serialized. This can be useful in subclasses if they need to remove a
      # field defined by the parent class.
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
      def cacheable(cacheable = true, ttl: nil, cache: nil)
        @cacheable = cacheable
        self.cache_ttl = ttl if ttl
        self.cache = cache if cache
      end
      
      # Return true if the serializer class is cacheable.
      def cacheable?
        unless defined?(@cacheable)
          @cacheable = superclass.cacheable? if superclass.respond_to?(:cacheable?)
        end
        !!@cacheable
      end
      
      # Return the time to live in seconds for a cacheable serializer.
      def cache_ttl
        if defined?(@cache_ttl)
          @cache_ttl
        elsif superclass.respond_to?(:cache_ttl)
          superclass.cache_ttl
        else
          nil
        end
      end
      
      # Set the time to live on a cacheable serializer.
      def cache_ttl=(value)
        @cache_ttl = value
      end
      
      # Get the cache implemtation used to store cacheable serializers.
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
      def cache=(cache)
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
      def add_field(name, optional:, serializer:, serializer_options:, enumerable:)
        name = name.to_sym
        field = SerializedField.new(name, optional: optional, serializer: serializer, serializer_options: serializer_options, enumerable: enumerable)
        
        # Add the field to the frozen list of fields.
        field_list = []
        added = false
        serializable_fields.each do |existing_field|
          if existing_field.name == name
            field_list << field
          else
            field_list << existing_field
          end
        end
        field_list << field unless added
        @serializable_fields = field_list.freeze
      end
      
      # Define a delegate method name +attribute+ that invokes the +field+ method on the wrapped object.
      def define_delegate(attribute, field)
        define_method(attribute){ object.send(field) } 
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
      @_serialized = nil
    end
  
    # Serialize the wrapped object into a format suitable for passing to a JSON parser.
    def as_json(*args)
      return nil unless object
      unless @_serialized
        @_serialized = (cacheable? ? load_from_cache : load_hash).freeze
      end
      @_serialized
    end
    
    alias :to_hash :as_json
    alias :to_h :as_json
    
    # Convert the wrapped object to JSON format.
    def to_json(options = nil)
      if defined?(MultiJson)
        MultiJson.dump(as_json)
      else
        JSON.dump(as_json)
      end
    end
    
    # Fetch the specified option from the options hash.
    def option(name)
      @options[name] if @options
    end
    
    # Return true if this serializer is cacheable.
    def cacheable?
      option(:cacheable) || self.class.cacheable?
    end
    
    # Return the cache implementation where this serializer can be stored.
    def cache
      option(:cache) || self.class.cache
    end
    
    # Return the time to live in seconds this serializer can be cached for.
    def cache_ttl
      option(:cache_ttl) || self.class.cache_ttl
    end
    
    # Returns a array of the elements that make this serializer unique. The
    # key is an array made up of the serializer class name, wrapped object, and
    # serialization options hash.
    def cache_key
      [self.class.name, object, options]
    end
    
    # :nodoc:
    def ==(other)
      other.instance_of?(self.class) && @object == other.object && @options == other.options
    end
    alias_method :eql?, :==
    
    private
    
    # Load the hash that will represent the wrapped object as a serialized object.
    def load_hash
      hash = {}
      include_fields = included_optional_fields
      excluded_fields = excluded_regular_fields
      SerializationContext.use do
        self.class.serializable_fields.each do |field|
          name = field.name
          if field.optional?
            next unless include_fields && include_fields.include?(name)
          end
          next if excluded_fields && excluded_fields.include?(name)
          value = field.serialize(send(name))
          hash[name] = value
        end
      end
      hash
    end
    
    # Return a list of optional fields to be included in the output from the :include option.
    def included_optional_fields
      included_fields = option(:include)
      if included_fields
        Array(included_fields).collect(&:to_sym)
      else
        nil
      end
    end
    
    # Return a list of fields to be excluded from the output from the :exclude option.
    def excluded_regular_fields
      excluded_fields = option(:exclude)
      if excluded_fields
        Array(excluded_fields).collect(&:to_sym)
      else
        nil
      end
    end
    
    def load_from_cache
      if cache
        cache.fetch(self, cache_ttl) do
          load_hash
        end
      else
        load_hash
      end
    end
  end
end
