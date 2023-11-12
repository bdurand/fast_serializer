[![Continuous Integration](https://github.com/bdurand/fast_serializer/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/fast_serializer/actions/workflows/continuous_integration.yml)
[![Regression Test](https://github.com/bdurand/fast_serializer/actions/workflows/regression_test.yml/badge.svg)](https://github.com/bdurand/fast_serializer/actions/workflows/regression_test.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)
[![Gem Version](https://badge.fury.io/rb/fast_serializer.svg)](https://badge.fury.io/rb/fast_serializer)

This gem provides a highly optimized framework for serializing Ruby objects into hashes suitable for serialization to some other format (i.e. JSON). It provides many of the same features as other serialization frameworks like active_model_serializers, but it is designed to emphasize code efficiency over feature set and syntactic surgar.

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

```ruby
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

Subclasses of serializers inherit all attributes. You can add or remove additional attributes in a subclass.

```ruby
class PersonSerializer
  include FastSerializer::Serializer
  serialize :id
  serialize :name
  serialize :phone
end

class EmployeeSerializer < PersonSerializer
  serialize :email
  remove :phone
end

PersonSerializer.new(person).as_json # => {:id => 1, :name => "John Doe", :phone => "222-555-1212"}
EmployeeSerializer.new(person).as_json # => {:id => 1, :name => "John Doe", :email => "john@example.com"}
```

### Optional and excluding fields

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

You can also pass the `:include` and `:exclude` options as hashes if you want to have them apply to associated records.

```ruby
class PersonSerializer
  include FastSerializer::Serializer
  serialize :id
  serialize :name
  serialize :company, serializer: CompanySerializer
end

PersonSerializer.new(person, :exclude => {:company => :address}).as_json
```

You can also specify fields to be optional with an `:if` block in the definition with the name of a method from the serializer. It can also be a `Proc` that will be executed with the binding of an instance of the serializer. The field will only be included if the method returns a truthy value.

```ruby
class PersonSerializer
  include FastSerializer::Serializer
  serialize :id
  serialize :name, if: -> { scope && scope.id == id }
  serialize :role, if: :staff?

  def staff?
    object.staff?
  end
end
```

### Serializer options

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
PersonSerializer.new(person, :last_first => true).as_json # => {:id => 1, :name => "Doe, John"}
```

The options hash is passed to all nested serializers. The special option name `:scope` is available as a method within the serializer and is used by convention to enforce various data restrictions.

```ruby
class PersonSerializer
  include FastSerializer::Serializer
  serialize :id
  serialize :name
  serialize :email, if: -> { scope && scope.id == object.id }
end
```

### Caching

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

For Rails application, you can run this in an initializer to tell `FastSerializer` to use `Rails.cache`

```ruby
FastSerializer.cache = :rails
```

You can also pass a cache to a serializer using the `:cache` option.

### Collections

If you have a collection of objects to serialize, you can use the `FastSerializer::ArraySerializer` to serialize an enumeration of objects.

```ruby
FastSerializer::ArraySerializer.new([a, b, c, d], :serializer => MyObjectSerializer)
```

You can also use the `array` helper class method on a serializer to do the same thing:

```ruby
PersonSerializer.array([a, b, c, d])
```

## Performance

Your mileage may vary. In many cases the performance of the serialization code doesn't particularly matter and this gem performs just about as well as other solutions. However, if you do have high throughput API or can utilize the caching features or have heavily nested models in your JSON responses, then the performance increase may be noticeable.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fast_serializer'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install fast_serializer
```

## Contributing

Open a pull request on GitHub.

Please use the [standardrb](https://github.com/testdouble/standard) syntax and lint your code with `standardrb --fix` before submitting.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
