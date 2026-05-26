# Changelog

All notable changes to the Cache module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-26

### Added
- Initial release of Cache module
- `Cache` class with TTL-based expiration support
- Multiple constructor overloads (file name only or with base path)
- Persistent JSON storage with automatic dirty tracking
- Core methods:
  - `Load()` - Load cache from file
  - `Save()` - Save cache to file (if dirty)
  - `Get(string)` - Get value with TTL validation
  - `Set(string, object)` - Set value without expiration
  - `Set(string, object, int)` - Set value with TTL in seconds
  - `Remove(string)` - Remove specific key
  - `Clear()` - Remove all entries
  - `Contains(string)` - Check if key exists and is valid
  - `GetKeys()` - Get all valid (non-expired) keys
  - `GetStats()` - Get cache statistics
  - `RemoveExpired()` - Remove expired entries
- Comprehensive test suite with 50+ unit tests
- Build automation with `Build.ps1`
- Dependency management with `Install-Dependencies.ps1`
- PSScriptAnalyzer configuration
- Complete documentation:
  - README.md with usage examples
  - API reference
  - Development guide
  - LICENSE (MIT)
- Support for PowerShell 5.1+ and PowerShell 7+
- Cross-platform compatibility (Windows, Linux, macOS)
- Verbose logging support for debugging

### Features
- **TTL Expiration**: Automatic expiration of cached entries based on TTL
- **Persistent Storage**: JSON-based storage for cache persistence across sessions
- **Dirty Tracking**: Optimized I/O by only saving when cache has changes
- **Flexible Constructors**: Create cache with file name or custom path
- **Cache Management**: Statistics, cleanup, and key listing
- **Thread-Safe**: Safe for concurrent operations
- **Verbose Logging**: Built-in logging for debugging and monitoring

### Technical Details
- Module manifest version: 1.0.0
- GUID: a8f5c3d2-9e1b-4f7a-8d6c-2b9e4f1a7c5d
- Compatible PSEditions: Desktop, Core
- Minimum PowerShell version: 5.1
- Class-based module with ScriptsToProcess
- Dependencies: None (standalone module)
- Test framework: Pester 5.x
- Code analysis: PSScriptAnalyzer 1.21+

### Documentation
- Complete README with quick start guide
- API reference with all methods and properties
- Usage examples for common scenarios:
  - API response caching
  - Session management
  - Configuration caching
  - Cache statistics and cleanup
- Development and contribution guide
- Build and testing instructions

### Quality Assurance
- 50+ unit tests covering all functionality
- PSScriptAnalyzer validation with zero critical errors
- Cross-platform testing on Windows, Linux, macOS
- Comprehensive test coverage:
  - Constructor initialization
  - Set/Get operations
  - TTL expiration behavior
  - Persistence and dirty tracking
  - Statistics and management operations

### Performance
- Optimized I/O with dirty tracking (only saves when needed)
- Efficient JSON serialization/deserialization
- Lazy expiration checking (on Get operations)
- Batch expired entry removal with `RemoveExpired()`

---

## Version History

- **1.0.0** (2026-05-26): Initial release

---

**Note**: This is a standalone extraction from the Request module's `RequestCache` class, enhanced with additional features and comprehensive testing.
