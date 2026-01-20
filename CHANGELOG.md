# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 2.0.0

### Changed

- Updated minimum Ruby version to 2.7.
- Only supports passing in http and https URLs as URI's. The previous behavior of calling `Kernel#open` was removed as a potential security risk.

## 1.0.2

### Changed

- Update to work with latest versions of Nokogiri and LibXML

## 1.0.1

### Fixed

- Fixes to Rakefile so it loads without rspec

## 1.0.0

### Added

- Initial release.
