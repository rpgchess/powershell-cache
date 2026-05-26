#Requires -Modules Cache

<#
.SYNOPSIS
    Exemplo de uso do módulo Cache.

.DESCRIPTION
    Demonstra os principais recursos do módulo Cache:
    - TTL-based caching
    - Persistent storage
    - Cache management
    - Statistics and cleanup

.EXAMPLE
    PS> .\Test-Cache.ps1
    Executa todos os exemplos de uso do Cache.

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-26
    Version: 1.0.0
    
    Prerequisites:
    - Import-Module Cache
#>

[CmdletBinding()]
param()

begin {
    Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
    Write-Host "  Cache Module - Usage Examples" -ForegroundColor Cyan
    Write-Host "$('=' * 70)`n" -ForegroundColor Cyan
    
    # Import module
    Import-Module Cache -Force
}

process {
    # Example 1: Basic Set/Get
    Write-Host "Example 1: Basic Set/Get" -ForegroundColor Yellow
    Write-Host "─" * 70 -ForegroundColor Gray
    
    $cache1 = [Cache]::new('example1')
    $cache1.Set('user-name', 'João Silva')
    $cache1.Set('user-email', 'joao@example.com')
    
    $name = $cache1.Get('user-name')
    $email = $cache1.Get('user-email')
    
    Write-Host "Name: $name"
    Write-Host "Email: $email"
    $cache1.Save()
    Write-Host "✓ Cache saved to: $($cache1.CacheFile)`n" -ForegroundColor Green
    
    # Example 2: TTL Expiration
    Write-Host "Example 2: TTL Expiration" -ForegroundColor Yellow
    Write-Host "─" * 70 -ForegroundColor Gray
    
    $cache2 = [Cache]::new('example2')
    $cache2.Set('session-token', 'abc-123-xyz', 5)  # 5 seconds TTL
    
    Write-Host "Token set with 5 second TTL"
    Write-Host "Getting token immediately: $($cache2.Get('session-token'))"
    
    Write-Host "Waiting 6 seconds for expiration..." -ForegroundColor Gray
    Start-Sleep -Seconds 6
    
    $expired = $cache2.Get('session-token')
    if ($null -eq $expired) {
        Write-Host "✓ Token expired successfully`n" -ForegroundColor Green
    } else {
        Write-Host "✗ Token should have expired`n" -ForegroundColor Red
    }
    
    # Example 3: Complex Objects
    Write-Host "Example 3: Complex Objects" -ForegroundColor Yellow
    Write-Host "─" * 70 -ForegroundColor Gray
    
    $cache3 = [Cache]::new('example3')
    
    $userData = @{
        Id = 123
        Name = 'Maria Santos'
        Email = 'maria@example.com'
        Roles = @('Admin', 'User')
        Settings = @{
            Theme = 'Dark'
            Language = 'pt-BR'
        }
    }
    
    $cache3.Set('user-123', $userData, 300)  # 5 minutes
    $cached = $cache3.Get('user-123')
    
    Write-Host "Cached user:"
    Write-Host "  ID: $($cached.Id)"
    Write-Host "  Name: $($cached.Name)"
    Write-Host "  Roles: $($cached.Roles -join ', ')"
    Write-Host "  Theme: $($cached.Settings.Theme)"
    $cache3.Save()
    Write-Host "✓ Complex object cached`n" -ForegroundColor Green
    
    # Example 4: Cache Statistics
    Write-Host "Example 4: Cache Statistics" -ForegroundColor Yellow
    Write-Host "─" * 70 -ForegroundColor Gray
    
    $cache4 = [Cache]::new('example4')
    $cache4.Set('permanent-1', 'value1')
    $cache4.Set('permanent-2', 'value2')
    $cache4.Set('expiring-1', 'value3', 3)
    $cache4.Set('expiring-2', 'value4', 3)
    
    $stats = $cache4.GetStats()
    Write-Host "Total entries: $($stats.TotalEntries)"
    Write-Host "Valid entries: $($stats.ValidEntries)"
    Write-Host "Expired entries: $($stats.ExpiredEntries)"
    
    Write-Host "`nWaiting 4 seconds for expiration..." -ForegroundColor Gray
    Start-Sleep -Seconds 4
    
    $stats = $cache4.GetStats()
    Write-Host "After expiration:"
    Write-Host "  Total entries: $($stats.TotalEntries)"
    Write-Host "  Valid entries: $($stats.ValidEntries)"
    Write-Host "  Expired entries: $($stats.ExpiredEntries)"
    
    $removed = $cache4.RemoveExpired()
    Write-Host "✓ Removed $removed expired entries`n" -ForegroundColor Green
    
    # Example 5: Get Keys
    Write-Host "Example 5: Get Valid Keys" -ForegroundColor Yellow
    Write-Host "─" * 70 -ForegroundColor Gray
    
    $cache5 = [Cache]::new('example5')
    $cache5.Set('config-db', 'localhost')
    $cache5.Set('config-port', 5432)
    $cache5.Set('temp-data', 'xyz', 2)
    
    Write-Host "Keys before expiration:"
    $keys1 = $cache5.GetKeys()
    Write-Host "  $($keys1 -join ', ')"
    
    Write-Host "`nWaiting 3 seconds..." -ForegroundColor Gray
    Start-Sleep -Seconds 3
    
    Write-Host "Keys after expiration:"
    $keys2 = $cache5.GetKeys()
    Write-Host "  $($keys2 -join ', ')"
    Write-Host "✓ Only valid keys returned`n" -ForegroundColor Green
    
    # Example 6: Contains Check
    Write-Host "Example 6: Contains Check" -ForegroundColor Yellow
    Write-Host "─" * 70 -ForegroundColor Gray
    
    $cache6 = [Cache]::new('example6')
    $cache6.Set('api-key', 'secret-key-123')
    
    if ($cache6.Contains('api-key')) {
        $apiKey = $cache6.Get('api-key')
        Write-Host "✓ API Key found: $apiKey" -ForegroundColor Green
    } else {
        Write-Host "✗ API Key not found" -ForegroundColor Red
    }
    
    if (-not $cache6.Contains('non-existent')) {
        Write-Host "✓ Non-existent key correctly not found`n" -ForegroundColor Green
    }
    
    # Example 7: Custom Path
    Write-Host "Example 7: Custom Cache Path" -ForegroundColor Yellow
    Write-Host "─" * 70 -ForegroundColor Gray
    
    $customPath = Join-Path $env:TEMP 'my-app-cache'
    New-Item -ItemType Directory -Path $customPath -Force | Out-Null
    
    $cache7 = [Cache]::new('app-cache', $customPath)
    $cache7.Set('setting1', 'value1')
    $cache7.Save()
    
    Write-Host "Cache file created at:"
    Write-Host "  $($cache7.CacheFile)"
    Write-Host "✓ Custom path working`n" -ForegroundColor Green
    
    # Example 8: Clear Cache
    Write-Host "Example 8: Clear All Cache" -ForegroundColor Yellow
    Write-Host "─" * 70 -ForegroundColor Gray
    
    $cache8 = [Cache]::new('example8')
    $cache8.Set('key1', 'value1')
    $cache8.Set('key2', 'value2')
    $cache8.Set('key3', 'value3')
    
    Write-Host "Entries before clear: $($cache8.GetKeys().Count)"
    
    $cache8.Clear()
    
    Write-Host "Entries after clear: $($cache8.GetKeys().Count)"
    Write-Host "✓ Cache cleared successfully`n" -ForegroundColor Green
}

end {
    Write-Host "$('=' * 70)" -ForegroundColor Cyan
    Write-Host "  ✓ All examples completed!" -ForegroundColor Cyan
    Write-Host "$('=' * 70)`n" -ForegroundColor Cyan
    
    Write-Host "Cleanup: Removing example cache files..." -ForegroundColor Gray
    Get-ChildItem -Path . -Filter 'example*.cache' | Remove-Item -Force
    Write-Host "✓ Cleanup completed`n" -ForegroundColor Green
}
