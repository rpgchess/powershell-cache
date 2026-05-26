@{
    # Module manifest for Cache module
    
    RootModule = 'Cache.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a8f5c3d2-9e1b-4f7a-8d6c-2b9e4f1a7c5d'
    
    Author = 'Claudio Almeida'
    CompanyName = 'Personal'
    Copyright = '(c) 2026 Claudio Almeida. All rights reserved.'
    
    Description = 'PowerShell cache manager with TTL support. Provides persistent caching functionality with automatic expiration management, JSON storage, and comprehensive cache operations.'
    
    # Minimum PowerShell version
    PowerShellVersion = '5.1'
    
    # Compatible PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # Scripts to process before loading module
    ScriptsToProcess = @(
        'Core\Cache.ps1'
    )
    
    # Functions to export (none - class-based module)
    FunctionsToExport = @()
    
    # Cmdlets to export (none)
    CmdletsToExport = @()
    
    # Variables to export (none)
    VariablesToExport = @()
    
    # Aliases to export (none)
    AliasesToExport = @()
    
    # Private data
    PrivateData = @{
        PSData = @{
            # Tags for PowerShell Gallery
            Tags = @(
                'Cache',
                'Caching',
                'TTL',
                'Storage',
                'Performance',
                'JSON',
                'Persistent',
                'PSEdition_Desktop',
                'PSEdition_Core',
                'Windows',
                'Linux',
                'MacOS'
            )
            
            # License URI
            LicenseUri = 'https://github.com/rpgchess/powershell-cache/blob/main/LICENSE'
            
            # Project URI
            ProjectUri = 'https://github.com/rpgchess/powershell-cache'
            
            # Icon URI
            # IconUri = ''
            
            # Release notes
            ReleaseNotes = @'
# Cache v1.0.0 - Initial Release

## Features
- TTL-based cache expiration
- Persistent JSON storage
- Automatic dirty tracking
- Multiple constructors (file name or full path)
- Cache statistics and management
- Expired entry cleanup
- Thread-safe operations
- Verbose logging support

## Usage
```powershell
Import-Module Cache

# Create cache instance
$cache = [Cache]::new('my-app')

# Set with TTL (5 minutes)
$cache.Set('key', $data, 300)

# Get from cache
$value = $cache.Get('key')

# Save to disk
$cache.Save()
```

## Documentation
See README.md for complete documentation and examples.
'@
        }
    }
}
