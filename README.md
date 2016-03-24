This gem provides a highly optimized framework for serializing Ruby objects into hashes suitable for serialization to some other format (i.e. JSON). It provides many of the same features as other serialization frameworks like active_model_serializers, but it is designed to emphasize code efficiency over feature set.

## Examples

For these examples we'll assume we have a simple Person class.

```ruby
class Person
  attr_accessor :id, :first_name, :last_name, :parents, :children
  
  def intitialize(attributes = {})
    @id = attributes[:id]
    @first_name = attributes[:first_name]
    @last_name = attributes[:last_name]
    @gender = attributes(:gender)
    @parent = attributes[:parents]
    @children = attributes[:children] || {}
  end
  
  def ==(other)
    other.instance_of?(self.class) && other.id == id
  end
end

person = Person.new(:id => 1, :first_name => "John", :last_name => "Doe", :gender => "M")
```

Serializers are classes that include `FastSerializer::Serializer`. Call the `serialize` method to specify which fields to include in the serialized object. Field values are gotten by calling the corresponding method on the serializer. By default each serialized field will define a method that delegates to the wrapped object.

ruby```
class PersonSerializer
  include FastSerializer::Serializer
  serialize :id, :name
  
  def name
    "#{object.first_name} #{object.last_name}"
  end
end

PersonSerializer.new(person).as_json # => {:id => 1, :name => "John Doe"}
```

You can alias fields so the serialized field name is different than the internal field name. You can also turn off creating the delegation method if it isn't needed for a field.

```ruby
class PersonSerializer
  include FastSerializer::Serializer
  serialize :id, as: :person_id
  serialize :name, :delegate => false
  
  def name
    "#{object.first_name} #{object.last_name}"
  end
end

PersonSerializer.new(person).as_json # => {:person_id => 1, :name => "John Doe"}
```

You can specify a serializer to use on fields that return complex objects.

```ruby
class PersonSerializer
  include FastSerializer::Serializer
  serialize :id
  serialize :name, :delegate => false
  serialize :parent, serializer: PersonSerializer
  serialize :children, serializer: PersonSerializer, enumerable: true
  
  def name
    "#{object.first_name} #{object.last_name}"
  end
end

person.parent = Person.new(:id => 2, :first_name => "Sally", :last_name => "Smith")
person.children << Person.new(:id => 3, :first_name => "Jane", :last_name => "Doe")
PersonSerializer.new(person).as_json # => {
                                     #      :id => 1,
                                     #      :name => "John Doe",
                                     #      :parent => {:id => 2, :name => "Sally Smith"},
                                     #      :children => [{:id => 3, :name => "Jane Doe"}]
                                     #    }
```

Serializer can have optional fields. You can also specify fields to exclude.

```ruby
class PersonSerializer
  include FastSerializer::Serializer
  serialize :id
  serialize :name, :delegate => false
  serialize :gender, optional: true
  
  def name
    "#{object.first_name} #{object.last_name}"
  end
end

PersonSerializer.new(person).as_json # => {:id => 1, :name => "John Doe"}
PersonSerializer.new(person, :include => [:gender]).as_json # => {:id => 1, :name => "John Doe", :gender => "M"}
PersonSerializer.new(person, :exclude => [:id]).as_json # => {:name => "John Doe"}
```

You can specify custom options that control how the object is serialized.

```ruby
class PersonSerializer
  include FastSerializer::Serializer
  serialize :id
  serialize :name, :delegate => false
  
  def name
    if option(:last_first)
      "#{object.last_name}, #{object.first_name}"
    else
      "#{object.first_name} #{object.last_name}"
    end
  end
end

PersonSerializer.new(person).as_json # => {:id => 1, :name => "John Doe"}
PersonSerializer.new(person, :last_first).as_json # => {:id => 1, :name => "Doe, John"}
```

You can make serializers cacheable so that the serialized value can be stored and fetched from a cache.

```ruby
class PersonSerializer
  include FastSerializer::Serializer
  serialize :id
  serialize :name, :delegate => false
  
  cacheable true, ttl: 60
  
  def name
    if option(:last_first)
      "#{object.last_name}, #{object.first_name}"
    else
      "#{object.first_name} #{object.last_name}"
    end
  end
end

FastSerializer.cache = MyCache.new # Must be an implementation of FastSerializer::Cache
```

TODO benchmarks
