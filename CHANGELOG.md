# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.1.5

### Fixed

- The `delegate: false` option on `serialize` is now honored; previously a delegate method was always defined.
- Redefining a serialized field (including in a subclass) now replaces the existing field instead of also appending a duplicate that was serialized twice.
- `SerializationContext` no longer clears its cache on every miss, so duplicate serializers within a context are properly reused.
- `ArraySerializer#cache` and `#cache_ttl` now return the configured cache and TTL instead of `true`, fixing a crash when passing the `:cache` option to an array serializer.
- `Cache::ActiveSupportCache#fetch_all` now passes the TTL to `fetch_multi`, so batch-cached entries expire as configured.
- Serializing non-Array enumerables (such as `Set`) containing values that need conversion no longer raises `NoMethodError`.

### Changed

- Serialization no longer duplicates the options hash for fields without an associated serializer when `:include` or `:exclude` options are present.
- Minimum required Ruby version is now 2.6.

## 1.1.4

### Fixed

- Removed unneeded dependency from gemspec.

## 1.1.3

### Added
- Optimize object shapes for the Ruby interpreter by declaring instance variables in constructors.

## 1.1.2

### Added
- Sanity check for unsupported options

### Fixed
- Handle converting ActiveSupport::TimeWithZone to a Time so it can be better dumped to non-JSON formats.

## 1.1.1

### Added
- Add `array` class method to serializers.

## 1.1.0

### Added
- Add helper method for scope option.
- Pass serialization options to child serializers.
- Add `if` option to conditionally include fields.
- Better cache keys handling for more complex objects.

## 1.0.2

### Added
- Better integration with ActiveSupport caching.

## 1.0.1

### Fixed
- Compatibility with change to fetch_multi in ActiveSupport 4.2.

## 1.0.0

### Added
- Initial release
