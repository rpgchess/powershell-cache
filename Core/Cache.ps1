<#
.SYNOPSIS
    PowerShell cache manager with TTL support.

.DESCRIPTION
    Provides caching functionality for any PowerShell data with Time To Live (TTL) support.
    Stores cache entries in JSON files with automatic expiration management.
    
    Features:
    - TTL-based expiration
    - Persistent storage in JSON
    - Automatic dirty tracking
    - Thread-safe operations
    - Verbose logging support

.EXAMPLE
    $cache = [Cache]::new('my-app.cache')
    $cache.Set('user-123', $userData, 300)  # 5 minutes TTL
    $cached = $cache.Get('user-123')

.EXAMPLE
    # Cache without TTL (never expires)
    $cache = [Cache]::new('permanent.cache')
    $cache.Set('config', $configData)  # No expiration
    $data = $cache.Get('config')

.EXAMPLE
    # Check if key exists and is valid
    if ($cache.Contains('session-token')) {
        $token = $cache.Get('session-token')
    }

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-26
    Version: 1.0.0
    Module: Cache
#>

class Cache {
    [string] $CacheFile
    [hashtable] $Cache
    [bool] $IsDirty = $false
    
    #region Constructors
    
    # Constructor with cache file name (creates in module root)
    Cache([string] $CacheFileName) {
        # Se não tiver extensão, adicionar .cache
        if (-not $CacheFileName.EndsWith('.cache')) {
            $CacheFileName = "$CacheFileName.cache"
        }
        
        # Cache file no diretório onde o módulo foi importado
        $this.CacheFile = Join-Path $PWD $CacheFileName
        $this.Load()
    }
    
    # Constructor with full path
    Cache([string] $CacheFileName, [string] $BasePath) {
        if (-not $CacheFileName.EndsWith('.cache')) {
            $CacheFileName = "$CacheFileName.cache"
        }
        
        $this.CacheFile = Join-Path $BasePath $CacheFileName
        $this.Load()
    }
    
    #endregion
    
    #region Public Methods
    
    # Load cache from file
    [void] Load() {
        if (Test-Path $this.CacheFile) {
            try {
                $json = Get-Content $this.CacheFile -Raw -ErrorAction Stop
                $this.Cache = $json | ConvertFrom-Json -AsHashtable
                Write-Verbose "Cache loaded from $($this.CacheFile)"
            } catch {
                Write-Warning "Failed to load cache: $($_.Exception.Message)"
                $this.Cache = @{}
            }
        } else {
            $this.Cache = @{}
            Write-Verbose "Cache file not found, initialized empty cache"
        }
    }
    
    # Save cache to file
    [void] Save() {
        if (-not $this.IsDirty) {
            Write-Verbose "Cache not dirty, skipping save"
            return
        }
        
        try {
            # Criar diretório se não existir
            $cacheDir = Split-Path $this.CacheFile -Parent
            if (-not (Test-Path $cacheDir)) {
                New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
            }
            
            $this.Cache | ConvertTo-Json -Depth 10 | Set-Content $this.CacheFile -ErrorAction Stop
            $this.IsDirty = $false
            Write-Verbose "Cache saved to $($this.CacheFile)"
        } catch {
            Write-Warning "Failed to save cache: $($_.Exception.Message)"
        }
    }
    
    # Get item from cache (validates TTL)
    [object] Get([string] $Key) {
        if (-not $this.Cache.ContainsKey($Key)) {
            Write-Verbose "Cache miss for key: $Key"
            return $null
        }
        
        $entry = $this.Cache[$Key]
        
        # Validate TTL
        if ($entry.ExpiresAt) {
            try {
                $expiresAt = [DateTimeOffset]::Parse($entry.ExpiresAt).UtcDateTime
                if ([DateTime]::UtcNow -gt $expiresAt) {
                    Write-Verbose "Cache expired for key: $Key (expired at $($entry.ExpiresAt))"
                    $this.Remove($Key)
                    return $null
                }
            } catch {
                Write-Warning "Failed to parse ExpiresAt for key $Key : $($_.Exception.Message)"
                # If parse fails, consider it expired
                $this.Remove($Key)
                return $null
            }
        }
        
        Write-Verbose "Cache hit for key: $Key"
        return $entry.Data
    }
    
    # Add/update item in cache
    [void] Set([string] $Key, [object] $Data) {
        $this.Set($Key, $Data, 0)
    }
    
    [void] Set([string] $Key, [object] $Data, [int] $TtlSeconds) {
        $entry = @{
            Data = $Data
            CachedAt = [DateTime]::UtcNow.ToString('o')
        }
        
        if ($TtlSeconds -gt 0) {
            $expiresAt = [DateTime]::UtcNow.AddSeconds($TtlSeconds)
            $entry.ExpiresAt = $expiresAt.ToString('o')
            Write-Verbose "Cache set for key: $Key (TTL: $TtlSeconds seconds, expires at $($entry.ExpiresAt))"
        } else {
            Write-Verbose "Cache set for key: $Key (no expiration)"
        }
        
        $this.Cache[$Key] = $entry
        $this.IsDirty = $true
    }
    
    # Remove item from cache
    [void] Remove([string] $Key) {
        if ($this.Cache.ContainsKey($Key)) {
            $this.Cache.Remove($Key)
            $this.IsDirty = $true
            Write-Verbose "Cache removed for key: $Key"
        } else {
            Write-Verbose "Cache key not found: $Key"
        }
    }
    
    # Clear all cache
    [void] Clear() {
        $count = $this.Cache.Count
        $this.Cache = @{}
        $this.IsDirty = $true
        Write-Verbose "Cache cleared ($count entries removed)"
    }
    
    # Check if key exists and is valid (not expired)
    [bool] Contains([string] $Key) {
        return $null -ne $this.Get($Key)
    }
    
    # Get all valid (non-expired) keys
    [string[]] GetKeys() {
        $validKeys = @()
        # Create copy of keys to avoid modification during enumeration
        $keys = @($this.Cache.Keys)
        foreach ($key in $keys) {
            if ($null -ne $this.Get($key)) {
                $validKeys += $key
            }
        }
        return $validKeys
    }
    
    # Get cache statistics
    [hashtable] GetStats() {
        $totalEntries = $this.Cache.Count
        $expiredEntries = 0
        $validEntries = 0
        
        foreach ($key in $this.Cache.Keys) {
            $entry = $this.Cache[$key]
            if ($entry.ExpiresAt) {
                try {
                    $expiresAt = [DateTimeOffset]::Parse($entry.ExpiresAt).UtcDateTime
                    if ([DateTime]::UtcNow -gt $expiresAt) {
                        $expiredEntries++
                    } else {
                        $validEntries++
                    }
                } catch {
                    $expiredEntries++
                }
            } else {
                $validEntries++
            }
        }
        
        return @{
            TotalEntries = $totalEntries
            ValidEntries = $validEntries
            ExpiredEntries = $expiredEntries
            CacheFile = $this.CacheFile
            IsDirty = $this.IsDirty
        }
    }
    
    # Remove expired entries
    [int] RemoveExpired() {
        $removed = 0
        $keysToRemove = @()
        
        foreach ($key in $this.Cache.Keys) {
            $entry = $this.Cache[$key]
            if ($entry.ExpiresAt) {
                try {
                    $expiresAt = [DateTimeOffset]::Parse($entry.ExpiresAt).UtcDateTime
                    if ([DateTime]::UtcNow -gt $expiresAt) {
                        $keysToRemove += $key
                    }
                } catch {
                    $keysToRemove += $key
                }
            }
        }
        
        foreach ($key in $keysToRemove) {
            $this.Cache.Remove($key)
            $removed++
        }
        
        if ($removed -gt 0) {
            $this.IsDirty = $true
            Write-Verbose "Removed $removed expired entries"
        }
        
        return $removed
    }
    
    #endregion
}
