# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" if File.exist?(ENV["BUNDLE_GEMFILE"])

begin
  require "simplecov"
  SimpleCov.start do
    add_filter ["/spec/"]
  end
rescue LoadError
end

Bundler.require(:default, :test)

begin
  require "active_support/all"
rescue LoadError
end

require_relative "../lib/fast_serializer"
require_relative "support/test_models"

RSpec.configure do |config|
  config.warnings = true
  config.order = :random
end
