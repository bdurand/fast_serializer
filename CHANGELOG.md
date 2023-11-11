# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
