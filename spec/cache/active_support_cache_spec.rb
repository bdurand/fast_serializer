require 'spec_helper'

describe FastSerializer::Cache::ActiveSupportCache do

  it "should fetch from an ActiveSupport cache store" do
    cache_store = ActiveSupport::Cache::MemoryStore.new
    cache = FastSerializer::Cache::ActiveSupportCache.new(cache_store)
    serializer = SimpleSerializer.new(SimpleModel.new(:id => 1))

    expect(cache.fetch(serializer, 60){|s| s.as_json} ).to eq serializer.as_json
    expect(cache.fetch(serializer, 60){ raise "boom" }).to eq serializer.as_json
  end

  it "should fetch multiple from an ActiveSupport cache store" do
    cache_store = ActiveSupport::Cache::MemoryStore.new
    cache = FastSerializer::Cache::ActiveSupportCache.new(cache_store)
    s1 = SimpleSerializer.new(SimpleModel.new(:id => 1))
    s2 = SimpleSerializer.new(SimpleModel.new(:id => 2))

    expect(cache.fetch_all([s1, s2], 60){|s| s.as_json} ).to eq [s1.as_json, s2.as_json]
    expect(cache.fetch_all([s1, s2], 60){ raise "boom" }).to eq [s1.as_json, s2.as_json]
  end

end
