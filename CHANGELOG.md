# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 2.0.1

### Fixed

- Added missing `stringio` require which caused a `NameError` when parsing an XML string on Ruby versions where the standard library no longer loads it implicitly.
- XPath selectors no longer drop nested elements with the same name (e.g. `.//a/a` now matches `a` elements nested inside other `a` elements).
- XPath selectors with a leading `//` now correctly search all descendants of the document root instead of only children of the root element.
- XPath selectors ending a `//` step with `*` (e.g. `book//*`) now match all descendants instead of skipping the first level.
- The `text()` selector no longer removes duplicate values when different nodes contain identical text.
- HTTP responses are now streamed incrementally instead of being read entirely into memory before parsing.

### Changed

- HTTP requests that return an error status now raise `XmlNodeStream::HttpError` instead of parsing the error response body as XML.

### Added

- HTTP redirects are now followed (up to 5) when parsing from a URL.

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
