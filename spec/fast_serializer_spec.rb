require 'spec_helper'

describe FastSerializer do

  it "should be able to set and get a global cache" do
    expect(FastSerializer.cache).to eq nil
    begin
      cache = TestCache.new
      FastSerializer.cache = cache
      expect(FastSerializer.cache).to eq cache
    ensure
      FastSerializer.cache = nil
    end
    expect(FastSerializer.cache).to eq nil
  end

  it "should set the cache to Rails.cache with the value :rails" do
    begin
      rails = double(:cache => :rails_cache)
      stub_const("Rails", rails)
      FastSerializer.cache = :rails
      expect(FastSerializer.cache).to be_a FastSerializer::Cache::ActiveSupportCache
      expect(FastSerializer.cache.cache).to eq :rails_cache
    ensure
      FastSerializer.cache = nil
    end
  end

  it "should set the cache with an ActiveSupport cache" do
    begin
      cache_store = ActiveSupport::Cache::MemoryStore.new
      FastSerializer.cache = cache_store
      expect(FastSerializer.cache).to be_a FastSerializer::Cache::ActiveSupportCache
      expect(FastSerializer.cache.cache).to eq cache_store
    ensure
      FastSerializer.cache = nil
    end
  end

end
