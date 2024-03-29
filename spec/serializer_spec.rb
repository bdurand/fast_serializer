# frozen_string_literal: true

require "spec_helper"

describe FastSerializer::Serializer do
  let(:model) { SimpleModel.new(id: 1, name: "foo", description: "foobar", number: 12) }

  it "should serialize object to JSON compatible format" do
    serializer = SimpleSerializer.new(model)
    expect(serializer.as_json).to eq({id: 1, name: "foo", validated: false})
    expect(serializer.to_hash).to eq({id: 1, name: "foo", validated: false})
    expect(serializer.to_h).to eq({id: 1, name: "foo", validated: false})
  end

  it "should serialize nil as nil" do
    expect(SimpleSerializer.new(nil).as_json).to eq nil
  end

  it "should include optional fields only if included in the options" do
    expect(SimpleSerializer.new(model).as_json).to eq({id: 1, name: "foo", validated: false})
    expect(SimpleSerializer.new(model, include: :nothing).as_json).to eq({id: 1, name: "foo", validated: false})
    expect(SimpleSerializer.new(model, include: :description).as_json).to eq({id: 1, name: "foo", validated: false, description: "foobar"})
    expect(SimpleSerializer.new(model, include: ["description"]).as_json).to eq({id: 1, name: "foo", validated: false, description: "foobar"})
  end

  it "should exclude specified fields" do
    expect(SimpleSerializer.new(model, exclude: :name).as_json).to eq({id: 1, validated: false})
    expect(SimpleSerializer.new(model, exclude: ["id", "validated"]).as_json).to eq({name: "foo"})
  end

  it "should allow aliasing fields" do
    number_model = SimpleModel.new(number: 50.5)
    expect(SimpleSerializer.new(number_model, include: :amount).as_json).to eq({id: nil, name: nil, validated: false, amount: 50.5})
  end

  it "should pull cached serializers from a cache" do
    serializer = SimpleSerializer.new(model)
    cached_serializer = CachedSerializer.new(model)

    expect(serializer.cacheable?).to eq false
    expect(cached_serializer.cacheable?).to eq true

    expect(serializer.cache_ttl).to eq nil
    expect(cached_serializer.cache_ttl).to eq 2

    expect(cached_serializer.as_json).to eq serializer.as_json
    expect(cached_serializer.as_json.object_id).to eq cached_serializer.as_json.object_id
  end

  it "should allow setting cache and ttl on parent serializers" do
    expect(SubCacheSerializer1.cacheable?).to eq true
    expect(SubCacheSerializer2.cacheable?).to eq true

    expect(SubCacheSerializer1.cache).to eq :mock
    expect(SubCacheSerializer2.cache).to eq CachedSerializer.cache

    expect(SubCacheSerializer1.cache_ttl).to eq 5
    expect(SubCacheSerializer2.cache_ttl).to eq 2
  end

  it "should allow setting cache and ttl on instances" do
    serializer = SimpleSerializer.new(model, cacheable: true, cache: :mock, cache_ttl: 10)
    expect(serializer.cacheable?).to eq true
    expect(serializer.cache).to eq :mock
    expect(serializer.cache_ttl).to eq 10
  end

  it "should get the cache from the global setting by default" do
    expect(SubCacheSerializerGlobalInheritTest.cache).to eq nil
    allow(FastSerializer).to receive_messages(cache: :mock)
    expect(SubCacheSerializerGlobalInheritTest.cache).to eq :mock
  end

  it "should not break on cached serializers if no cache is set" do
    serializer = CachedSerializer.new(model, cache: nil)
    expect(serializer.as_json).to eq({id: 1, name: "foo", validated: false})
  end

  it "should serialize complex objects" do
    other_model = SimpleModel.new(id: 3, name: "other")
    complex = SimpleModel.new(id: 2, name: :complex, parent: model, associations: [model, other_model])
    serializer = ComplexSerializer.new(complex, serial_number: 15)
    expect(serializer.as_json).to eq({
      id: 2, name: :complex, validated: false, serial_number: 15,
      associations: [
        {id: 1, name: "foo", validated: false},
        {id: 3, name: "other", validated: false}
      ],
      parent: {id: 1, name: "foo", validated: false}
    })
  end

  it "should pass include and exclude options to child serializers" do
    other_model = SimpleModel.new(id: 3, name: "other")
    complex = SimpleModel.new(id: 2, name: :complex, parent: model, associations: [model, other_model])
    serializer = ComplexSerializer.new(complex, serial_number: 15, exclude: {associations: [:validated]}, include: {parent: :amount})
    expect(serializer.as_json).to eq({
      id: 2, name: :complex, validated: false, serial_number: 15,
      associations: [
        {id: 1, name: "foo"},
        {id: 3, name: "other"}
      ],
      parent: {id: 1, name: "foo", validated: false, amount: 12}
    })
  end

  it "should have a scope option" do
    serializer = CachedSerializer.new(model, scope: :foo)
    expect(serializer.scope).to eq :foo
  end

  it "should return identical serialized values for serializers on the same object and options inside the same context" do
    other_model = SimpleModel.new(id: 3, name: "other")
    complex = SimpleModel.new(id: 2, name: "complex", associations: [model, other_model, model])
    serializer = ComplexSerializer.new(complex)
    json = serializer.as_json
    expect(json[:associations][0].object_id).to_not eq json[:associations][1].object_id
    expect(json[:associations][0].object_id).to eq json[:associations][2].object_id
  end

  it "should dump the object to JSON" do
    complex = SimpleModel.new(id: 2, name: "complex", parent: model, associations: [model])
    serializer = ComplexSerializer.new(complex)
    expect(JSON.parse(serializer.to_json)).to eq({
      "id" => 2,
      "name" => "complex",
      "validated" => false,
      "serial_number" => nil,
      "associations" => [
        {"id" => 1, "name" => "foo", "validated" => false}
      ],
      "parent" => {"id" => 1, "name" => "foo", "validated" => false, "description" => "foobar"}
    })
  end

  it "should allow passing options for JSON dumping" do
    complex = SimpleModel.new(id: 2, name: "complex", parent: model, associations: [model])
    serializer = ComplexSerializer.new(complex)
    expect(serializer.to_json(pretty: true)).to be_a(String)
  end

  it "should expose options from the options hash by name" do
    serializer = CachedSerializer.new(model, foo: "bar")
    expect(serializer.option(:foo)).to eq "bar"
    expect(serializer.option(:other)).to eq nil
  end

  it "should return nil value for options if none are set" do
    serializer = CachedSerializer.new(model, nil)
    expect(serializer.option(:foo)).to eq nil
  end

  it "should not get into infinite loops" do
    model = SimpleModel.new(id: 1)
    model.parent = model
    serializer = CircularSerializer.new(model)
    expect { serializer.as_json }.to raise_error(FastSerializer::CircularReferenceError)
  end

  it "should allow conditionals on serialized fields" do
    expect(ConditionalSerializer.new(model).as_json).to eq({id: 1})
    expect(ConditionalSerializer.new(model, scope: :description).as_json).to eq({id: 1, description: "foobar"})
    expect(ConditionalSerializer.new(model, scope: :name).as_json).to eq({id: 1, name: "foo"})
  end
end
