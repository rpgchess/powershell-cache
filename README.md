# Cache Module for PowerShell

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-orange.svg)](CHANGELOG.md)

PowerShell cache manager with TTL (Time To Live) support. Provides persistent caching functionality with automatic expiration management, JSON storage, and comprehensive cache operations.

## ✨ Features

- **TTL-Based Expiration**: Automatic cache entry expiration with configurable TTL
- **Persistent Storage**: JSON file-based storage for cache persistence
- **Dirty Tracking**: Optimized I/O with automatic dirty state management
- **Multiple Constructors**: Flexible initialization with file name or full path
- **Cache Management**: Statistics, expired entry cleanup, key listing
- **Thread-Safe**: Safe concurrent operations
- **Verbose Logging**: Built-in verbose output for debugging
- **Cross-Platform**: Works on Windows, Linux, and macOS
- **PowerShell 5.1+ and 7+ Compatible**

## 📦 Installation

### From Source

```powershell
# Clone or download the repository
git clone https://github.com/rpgchess/powershell-cache.git
cd cache

# Install dependencies
.\Install-Dependencies.ps1

# Build and test
.\Build.ps1 -Task All
```

### Manual Installation

```powershell
# Copy the Cache folder to your PowerShell modules path
Copy-Item -Path .\Cache -Destination "$env:PSModulePath\Cache" -Recurse

# Import the module
Import-Module Cache
```

## 🚀 Quick Start

### Basic Usage

```powershell
# Import module
Import-Module Cache

# Create cache instance
$cache = [Cache]::new('my-app')

# Set value with TTL (5 minutes = 300 seconds)
$cache.Set('user-data', $userData, 300)

# Get value from cache
$data = $cache.Get('user-data')

# Save to disk
$cache.Save()
```

### Without TTL (Permanent)

```powershell
# Set value without expiration
$cache.Set('config', $configData)

# Data never expires until manually removed
$config = $cache.Get('config')
```

### Check Existence

```powershell
# Check if key exists and is valid (not expired)
if ($cache.Contains('session-token')) {
    $token = $cache.Get('session-token')
} else {
    # Fetch new token
}
```

### Custom Cache Location

```powershell
# Specify custom base path for cache file
$customPath = 'C:\MyApp\Cache'
$cache = [Cache]::new('app-cache', $customPath)
```

## 📖 Usage Examples

### Example 1: API Response Caching

```powershell
Import-Module Cache

function Get-UserData {
    param([string] $UserId)
    
    $cache = [Cache]::new('api-cache')
    $cacheKey = "user-$UserId"
    
    # Try cache first
    $cached = $cache.Get($cacheKey)
    if ($cached) {
        Write-Host "Cache hit for user $UserId"
        return $cached
    }
    
    # Cache miss - fetch from API
    Write-Host "Cache miss - fetching from API"
    $userData = Invoke-RestMethod -Uri "https://api.example.com/users/$UserId"
    
    # Cache for 10 minutes
    $cache.Set($cacheKey, $userData, 600)
    $cache.Save()
    
    return $userData
}
```

### Example 2: Session Management

```powershell
Import-Module Cache

$sessionCache = [Cache]::new('sessions')

# Store session with 1 hour TTL
$sessionData = @{
    UserId = 123
    Token = 'abc-xyz'
    Roles = @('Admin', 'User')
}
$sessionCache.Set('session-abc', $sessionData, 3600)

# Check if session is valid
if ($sessionCache.Contains('session-abc')) {
    $session = $sessionCache.Get('session-abc')
    Write-Host "Session valid for user $($session.UserId)"
} else {
    Write-Host "Session expired or not found"
}

$sessionCache.Save()
```

### Example 3: Cache Statistics

```powershell
Import-Module Cache

$cache = [Cache]::new('my-cache')

# Add some entries
$cache.Set('permanent', 'value')
$cache.Set('expiring1', 'value1', 5)
$cache.Set('expiring2', 'value2', 5)

# Get statistics
$stats = $cache.GetStats()
Write-Host "Total entries: $($stats.TotalEntries)"
Write-Host "Valid entries: $($stats.ValidEntries)"
Write-Host "Expired entries: $($stats.ExpiredEntries)"

# Remove expired entries
$removed = $cache.RemoveExpired()
Write-Host "Removed $removed expired entries"

# Get all valid keys
$keys = $cache.GetKeys()
Write-Host "Valid keys: $($keys -join ', ')"
```

### Example 4: Configuration Cache

```powershell
Import-Module Cache

function Get-AppConfig {
    $cache = [Cache]::new('app-config')
    
    # Try cache first
    $config = $cache.Get('config')
    if ($config) {
        return $config
    }
    
    # Load from file
    $configPath = '.\config.json'
    $config = Get-Content $configPath | ConvertFrom-Json
    
    # Cache permanently (no TTL)
    $cache.Set('config', $config)
    $cache.Save()
    
    return $config
}
```

## 🛠️ API Reference

### Constructors

```powershell
# Constructor with file name (creates in current directory)
$cache = [Cache]::new('my-cache')  # Creates my-cache.cache

# Constructor with full path
$cache = [Cache]::new('my-cache', 'C:\Custom\Path')
```

### Methods

| Method | Description | Parameters | Returns |
|--------|-------------|------------|---------|
| `Load()` | Load cache from file | None | void |
| `Save()` | Save cache to file (if dirty) | None | void |
| `Get(string)` | Get value from cache (validates TTL) | `$Key` | object |
| `Set(string, object)` | Set value without expiration | `$Key`, `$Data` | void |
| `Set(string, object, int)` | Set value with TTL | `$Key`, `$Data`, `$TtlSeconds` | void |
| `Remove(string)` | Remove specific key | `$Key` | void |
| `Clear()` | Remove all entries | None | void |
| `Contains(string)` | Check if key exists and is valid | `$Key` | bool |
| `GetKeys()` | Get all valid (non-expired) keys | None | string[] |
| `GetStats()` | Get cache statistics | None | hashtable |
| `RemoveExpired()` | Remove expired entries | None | int |

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `CacheFile` | string | Full path to cache file |
| `Cache` | hashtable | Internal cache storage |
| `IsDirty` | bool | Indicates if cache has unsaved changes |

## 🧪 Development

### Prerequisites

- PowerShell 5.1+ or PowerShell 7+
- Pester 5.x (for testing)
- PSScriptAnalyzer (for code analysis)

### Setup

```powershell
# Install dependencies
.\Install-Dependencies.ps1

# Run all tasks
.\Build.ps1 -Task All
```

### Build Tasks

```powershell
# Clean artifacts
.\Build.ps1 -Task Clean

# Run code analysis
.\Build.ps1 -Task Analyze

# Run tests
.\Build.ps1 -Task Test

# Full build (Clean + Analyze + Test)
.\Build.ps1 -Task Build

# Create package
.\Build.ps1 -Task Package

# All tasks
.\Build.ps1 -Task All
```

### Testing

```powershell
# Run all tests
.\Build.ps1 -Task Test

# Run with verbose output
.\Build.ps1 -Task Test -Verbose

# Skip tests
.\Build.ps1 -Task Build -SkipTests
```

## 📝 Cache File Format

Cache files are stored in JSON format:

```json
{
  "key1": {
    "Data": "value1",
    "CachedAt": "2026-05-26T10:30:00.0000000Z",
    "ExpiresAt": "2026-05-26T10:35:00.0000000Z"
  },
  "key2": {
    "Data": { "Name": "Test", "Value": 123 },
    "CachedAt": "2026-05-26T10:30:00.0000000Z"
  }
}
```

## ⚙️ Configuration

### Cache Location

By default, cache files are created in the current working directory. You can customize:

```powershell
# Current directory (default)
$cache = [Cache]::new('my-cache')

# Custom path
$appData = $env:LOCALAPPDATA
$cache = [Cache]::new('my-cache', "$appData\MyApp")
```

### Verbose Logging

Enable verbose output to see cache operations:

```powershell
$VerbosePreference = 'Continue'

$cache = [Cache]::new('my-cache')
$cache.Set('key', 'value', 300)  # Shows: "Cache set for key: key (TTL: 300 seconds...)"
$cache.Get('key')                 # Shows: "Cache hit for key: key"
$cache.Save()                     # Shows: "Cache saved to ..."
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add/update tests
5. Run `.\Build.ps1 -Task All`
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## 🔗 Related Projects

- [Request Module](https://github.com/yourusername/request) - HTTP client for PowerShell
- [Logger Module](https://github.com/yourusername/logger) - Logging for PowerShell

## 📮 Support

For issues, questions, or contributions:
- **Issues**: [GitHub Issues](https://github.com/yourusername/cache/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/cache/discussions)

## 📊 Project Status

- ✅ Stable - v1.0.0
- ✅ Well tested - 50+ unit tests
- ✅ Cross-platform compatible
- ✅ Production ready

---

**Author**: Claudio Almeida  
**Version**: 1.0.0  
**Date**: 2026-05-26
