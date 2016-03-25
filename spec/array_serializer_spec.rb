require 'spec_helper'

describe FastSerializer::ArraySerializer do
  
  it "should serialize an array of regular objects" do
    array = [1, 2, 3]
    serializer = FastSerializer::ArraySerializer.new(array)
    expect(serializer.as_json).to eq array
  end
  
  it "should serialize any Enumerable" do
    hash = {:a => 1, :b => 2}
    serializer = FastSerializer::ArraySerializer.new(hash)
    expect(serializer.as_json).to eq hash.to_a
  end
  
  it "should serializer an array of objects using a specific serializer" do
    model_1 = SimpleModel.new(:id => 1, :name => "foo")
    model_2 = SimpleModel.new(:id => 2, :name => "bar")
    serializer = FastSerializer::ArraySerializer.new([model_1, model_2], :serializer => SimpleSerializer)
    expect(JSON.load(serializer.to_json)).to eq [
      {"id" => 1, "name" => "foo", "validated" => false},
      {"id" => 2, "name" => "bar", "validated" => false}
    ]
  end
  
  it "should serializer an array of objects using a specific serializer with options" do
    model_1 = SimpleModel.new(:id => 1, :name => "foo")
    model_2 = SimpleModel.new(:id => 2, :name => "bar")
    serializer = FastSerializer::ArraySerializer.new([model_1, model_2], :serializer => SimpleSerializer, :serializer_options => {:include => :description})
    expect(JSON.load(serializer.to_json)).to eq [
      {"id" => 1, "name" => "foo", "validated" => false, "description" => nil},
      {"id" => 2, "name" => "bar", "validated" => false, "description" => nil}
    ]
  end
  
  it "should not respond to_hash methods" do
    array = [1, 2, 3]
    serializer = FastSerializer::ArraySerializer.new(array)
    expect(serializer.respond_to?(:to_hash)).to eq false
    expect(serializer.respond_to?(:to_h)).to eq false
  end
  
  it "should respond to to_a" do
    array = [1, 2, 3]
    serializer = FastSerializer::ArraySerializer.new(array)
    expect(serializer.to_a).to eq array
  end

end
