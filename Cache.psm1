<#
.SYNOPSIS
    Cache module for PowerShell.

.DESCRIPTION
    Provides caching functionality with TTL support for PowerShell scripts and modules.
    
    This module exports the Cache class which provides:
    - TTL-based expiration
    - Persistent JSON storage
    - Automatic dirty tracking
    - Cache statistics and management
    
.EXAMPLE
    Import-Module Cache
    
    $cache = [Cache]::new('my-app')
    $cache.Set('user-data', $userData, 300)  # 5 min TTL
    $data = $cache.Get('user-data')
    $cache.Save()

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-26
    Version: 1.0.0
#>

# Module initialization
$ErrorActionPreference = 'Stop'

# Classes are loaded via ScriptsToProcess in manifest
# Cache class is available after import

# Export nothing explicitly (class-based module)
# Classes are automatically available after import
Export-ModuleMember -Function @()
Export-ModuleMember -Cmdlet @()
Export-ModuleMember -Variable @()
Export-ModuleMember -Alias @()

# Module loaded successfully
Write-Verbose "Cache module v1.0.0 loaded successfully"
