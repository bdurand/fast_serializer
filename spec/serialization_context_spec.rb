require 'spec_helper'

describe FastSerializer::SerializationContext do

  it "should get a single context only within a block" do
    expect(FastSerializer::SerializationContext.current).to eq nil
    FastSerializer::SerializationContext.use do
      context = FastSerializer::SerializationContext.current
      expect(FastSerializer::SerializationContext.current).to_not eq nil
      FastSerializer::SerializationContext.use do
        expect(FastSerializer::SerializationContext.current).to eq context
      end
      expect(FastSerializer::SerializationContext.current).to eq context
    end
    expect(FastSerializer::SerializationContext.current).to eq nil
  end

  it "should create serializers and reload them from cache with the same object and options" do
    context = FastSerializer::SerializationContext.new
    object = SimpleModel.new(:id => 1, :name => "foo")

    serializer = context.load(SimpleSerializer, object, :count => 1)
    expect(serializer).to be_a SimpleSerializer
    expect(serializer.object).to eq object
    expect(serializer.options).to eq(:count => 1)

    expect(context.load(SimpleSerializer, object, :count => 1).object_id).to eq serializer.object_id
    expect(context.load(SimpleSerializer, SimpleModel.new(:id => 2, :name => "bar"), :count => 1).object_id).to_not eq serializer.object_id
    expect(context.load(SimpleSerializer, object, :count => 2).object_id).to_not eq serializer.object_id
  end

end
