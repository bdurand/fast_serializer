require 'spec_helper'

describe FastSerializer::SerializedField do

  let(:field){ FastSerializer::SerializedField.new(:test) }
  let(:model){ SimpleModel.new(:id => 1, :name => "foo") }

  it "should integers" do
    expect(field.serialize(1)).to eq 1
  end

  it "should serialize floats" do
    expect(field.serialize(1.5)).to eq 1.5
  end

  it "should serialize strings" do
    expect(field.serialize("foo")).to eq "foo"
  end

  it "should serialize symbols" do
    expect(field.serialize(:foo)).to eq :foo
  end

  it "should serialize nil" do
    expect(field.serialize(nil)).to eq nil
  end

  it "should serialize booleans" do
    expect(field.serialize(true)).to eq true
    expect(field.serialize(false)).to eq false
  end

  it "should serialize times" do
    time = Time.now
    expect(field.serialize(time)).to eq time
  end

  it "should serialize dates" do
    date = Date.today
    expect(field.serialize(date)).to eq date
  end

  it "should serialize a field using a specified serializer" do
    field = FastSerializer::SerializedField.new(:test, serializer: SimpleSerializer)
    expect(field.serialize(model)).to eq({:id => 1, :name => "foo", :validated => false})
  end

  it "should serialize an enumerable field using a specified serializer" do
    field = FastSerializer::SerializedField.new(:test, serializer: SimpleSerializer, enumerable: true)
    expect(field.serialize(model)).to eq([{:id => 1, :name => "foo", :validated => false}])
  end

  it "should serialize a field value by calling as_json on the field" do
    expect(field.serialize(model)).to eq({:id => 1, :name => "foo", :description => nil, :number => nil})
  end

  it "should serialize a hash of objects" do
    expect(field.serialize(:name => "Test", :object => model)).to eq({
      :name => "Test",
      :object => {:id => 1, :name => "foo", :description => nil, :number => nil}
    })
  end

  it "should serialize an array of objects" do
    expect(field.serialize([model, model])).to eq([
      {:id => 1, :name => "foo", :description => nil, :number => nil},
      {:id => 1, :name => "foo", :description => nil, :number => nil}
    ])
  end

end
