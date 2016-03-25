class SimpleModel
  attr_reader :id, :name, :description, :associations, :number
  attr_accessor :parent
  
  def initialize(attributes = {})
    @id = attributes[:id]
    @name = attributes[:name]
    @description = attributes[:description]
    @validated = attributes[:validated]
    @associations = attributes[:associations]
    @parent = attributes[:parent]
    @number = attributes[:number]
  end
  
  def validated?
    !!@validated
  end
  
  def as_json(*args)
    {:id => @id, :name => @name, :description => @description, :number => @number}
  end
end

class TestCache < FastSerializer::Cache
  def initialize
    @cache = {}
  end
  
  def fetch(serializer, ttl)
    val = @cache[serializer.cache_key]
    unless val
      val = yield
      @cache[serializer.cache_key] = val
    end
    val
  end
end

class SimpleSerializer
  include FastSerializer::Serializer
  
  serialize :id, :name, :validated?
  serialize :description, optional: true
  serialize :number, as: :amount, optional: true
end

class CachedSerializer < SimpleSerializer
  cacheable ttl: 2, cache: TestCache.new
end

class ComplexSerializer < SimpleSerializer
  serialize :serial_number, delegate: false
  serialize :associations, delegate: true, serializer: CachedSerializer, enumerable: true
  serialize :parent, delegate: true, serializer: SimpleSerializer
  
  def serial_number
    option(:serial_number)
  end
end

class CircularSerializer < SimpleSerializer
  remove :name, :validated
  serialize :parent, serializer: self
end
