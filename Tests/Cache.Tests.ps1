#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

<#
.SYNOPSIS
    Pester tests for Cache module.

.DESCRIPTION
    Test suite for the Cache class and module functionality.
    Tests include:
    - Constructor and initialization
    - Set/Get operations
    - TTL expiration
    - Cache persistence
    - Statistics and management

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-26
    Version: 1.0.0
#>

BeforeAll {
    # Import module
    $modulePath = Join-Path $PSScriptRoot '..' 'Cache.psd1'
    Import-Module $modulePath -Force -ErrorAction Stop
    
    # Test cache directory
    $script:TestCacheDir = Join-Path $TestDrive 'cache-tests'
    New-Item -ItemType Directory -Path $script:TestCacheDir -Force | Out-Null
}

AfterAll {
    # Remove module
    Remove-Module Cache -Force -ErrorAction SilentlyContinue
}

Describe 'Cache Module' -Tag 'Unit' {
    Context 'Module Import' {
        It 'Should have Cache class available' {
            [Cache] | Should -Not -BeNullOrEmpty
        }
        
        It 'Should export Cache class' {
            [Cache] | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Cache Class - Constructors' -Tag 'Unit' {
    Context 'Constructor with file name only' {
        It 'Should create cache with file name' {
            $cache = [Cache]::new('test-cache')
            $cache | Should -Not -BeNullOrEmpty
            $cache.CacheFile | Should -BeLike '*test-cache.cache'
        }
        
        It 'Should add .cache extension if missing' {
            $cache = [Cache]::new('test')
            $cache.CacheFile | Should -BeLike '*test.cache'
        }
        
        It 'Should not double .cache extension' {
            $cache = [Cache]::new('test.cache')
            $cache.CacheFile | Should -Not -BeLike '*test.cache.cache'
        }
    }
    
    Context 'Constructor with base path' {
        It 'Should create cache with custom base path' {
            $cache = [Cache]::new('custom', $script:TestCacheDir)
            $cache.CacheFile | Should -Be (Join-Path $script:TestCacheDir 'custom.cache')
        }
        
        It 'Should add .cache extension in custom path' {
            $cache = [Cache]::new('custom', $script:TestCacheDir)
            $cache.CacheFile | Should -BeLike '*.cache'
        }
    }
}

Describe 'Cache Class - Basic Operations' -Tag 'Unit' {
    BeforeEach {
        $script:cache = [Cache]::new('test-basic', $script:TestCacheDir)
    }
    
    AfterEach {
        if ($script:cache.CacheFile -and (Test-Path $script:cache.CacheFile)) {
            Remove-Item $script:cache.CacheFile -Force
        }
    }
    
    Context 'Set and Get' {
        It 'Should set and get string value' {
            $script:cache.Set('key1', 'value1')
            $result = $script:cache.Get('key1')
            $result | Should -Be 'value1'
        }
        
        It 'Should set and get hashtable' {
            $data = @{ Name = 'Test'; Value = 123 }
            $script:cache.Set('key2', $data)
            $result = $script:cache.Get('key2')
            $result.Name | Should -Be 'Test'
            $result.Value | Should -Be 123
        }
        
        It 'Should set and get array' {
            $data = @(1, 2, 3, 4, 5)
            $script:cache.Set('key3', $data)
            $result = $script:cache.Get('key3')
            $result.Count | Should -Be 5
            $result[0] | Should -Be 1
        }
        
        It 'Should return null for non-existent key' {
            $result = $script:cache.Get('non-existent')
            $result | Should -BeNullOrEmpty
        }
        
        It 'Should overwrite existing key' {
            $script:cache.Set('key4', 'old-value')
            $script:cache.Set('key4', 'new-value')
            $result = $script:cache.Get('key4')
            $result | Should -Be 'new-value'
        }
    }
    
    Context 'TTL Expiration' {
        It 'Should respect TTL and expire entry' {
            $script:cache.Set('expiring-key', 'test-value', 5)  # 5 seconds TTL
            
            # Immediately should be available
            $result1 = $script:cache.Get('expiring-key')
            $result1 | Should -Be 'test-value'
            
            # Wait for expiration (6 seconds to be safe)
            Start-Sleep -Seconds 6
            
            # Should be expired now
            $result2 = $script:cache.Get('expiring-key')
            $result2 | Should -BeNullOrEmpty
        }
        
        It 'Should not expire entry without TTL' {
            $script:cache.Set('permanent-key', 'permanent-value')  # No TTL
            
            Start-Sleep -Seconds 2
            
            $result = $script:cache.Get('permanent-key')
            $result | Should -Be 'permanent-value'
        }
        
        It 'Should handle TTL of 0 as no expiration' {
            $script:cache.Set('zero-ttl', 'value', 0)
            Start-Sleep -Seconds 1
            $result = $script:cache.Get('zero-ttl')
            $result | Should -Be 'value'
        }
    }
    
    Context 'Remove and Clear' {
        It 'Should remove specific key' {
            $script:cache.Set('key-to-remove', 'value')
            $script:cache.Remove('key-to-remove')
            $result = $script:cache.Get('key-to-remove')
            $result | Should -BeNullOrEmpty
        }
        
        It 'Should not throw on removing non-existent key' {
            { $script:cache.Remove('non-existent') } | Should -Not -Throw
        }
        
        It 'Should clear all entries' {
            $script:cache.Set('key1', 'value1')
            $script:cache.Set('key2', 'value2')
            $script:cache.Set('key3', 'value3')
            
            $script:cache.Clear()
            
            $script:cache.Get('key1') | Should -BeNullOrEmpty
            $script:cache.Get('key2') | Should -BeNullOrEmpty
            $script:cache.Get('key3') | Should -BeNullOrEmpty
        }
        
        It 'Should mark cache as dirty after clear' {
            $script:cache.Set('key1', 'value1')
            $script:cache.Clear()
            $script:cache.IsDirty | Should -Be $true
        }
    }
    
    Context 'Contains' {
        It 'Should return true for existing key' {
            $script:cache.Set('existing-key', 'value')
            $script:cache.Contains('existing-key') | Should -Be $true
        }
        
        It 'Should return false for non-existent key' {
            $script:cache.Contains('non-existent') | Should -Be $false
        }
        
        It 'Should return false for expired key' {
            $script:cache.Set('expired-key', 'value', 1)
            Start-Sleep -Seconds 2
            $script:cache.Contains('expired-key') | Should -Be $false
        }
    }
}

Describe 'Cache Class - Persistence' -Tag 'Unit' {
    BeforeEach {
        $script:cache = [Cache]::new('test-persistence', $script:TestCacheDir)
    }
    
    AfterEach {
        if ($script:cache.CacheFile -and (Test-Path $script:cache.CacheFile)) {
            Remove-Item $script:cache.CacheFile -Force
        }
    }
    
    Context 'Save and Load' {
        It 'Should save cache to file' {
            $script:cache.Set('persistent-key', 'persistent-value')
            $script:cache.Save()
            
            Test-Path $script:cache.CacheFile | Should -Be $true
        }
        
        It 'Should load cache from file' {
            # Save cache
            $script:cache.Set('key1', 'value1')
            $script:cache.Set('key2', 'value2')
            $script:cache.Save()
            
            # Create new cache instance (loads from file)
            $newCache = [Cache]::new('test-persistence', $script:TestCacheDir)
            
            $newCache.Get('key1') | Should -Be 'value1'
            $newCache.Get('key2') | Should -Be 'value2'
        }
        
        It 'Should persist complex objects' {
            $data = @{
                Name = 'Test'
                Items = @(1, 2, 3)
                Nested = @{ Key = 'Value' }
            }
            
            $script:cache.Set('complex', $data)
            $script:cache.Save()
            
            $newCache = [Cache]::new('test-persistence', $script:TestCacheDir)
            $result = $newCache.Get('complex')
            
            $result.Name | Should -Be 'Test'
            $result.Items.Count | Should -Be 3
            $result.Nested.Key | Should -Be 'Value'
        }
        
        It 'Should not save if not dirty' {
            $script:cache.Set('key', 'value')
            $script:cache.Save()
            
            # Mark as not dirty
            $script:cache.IsDirty = $false
            
            # Modify file timestamp
            $lastWrite = (Get-Item $script:cache.CacheFile).LastWriteTime
            Start-Sleep -Milliseconds 100
            
            # Save should be skipped
            $script:cache.Save()
            
            # Timestamp should not change
            $newWrite = (Get-Item $script:cache.CacheFile).LastWriteTime
            $newWrite | Should -Be $lastWrite
        }
    }
    
    Context 'Dirty Tracking' {
        It 'Should mark as dirty on Set' {
            $script:cache.IsDirty = $false
            $script:cache.Set('key', 'value')
            $script:cache.IsDirty | Should -Be $true
        }
        
        It 'Should mark as dirty on Remove' {
            $script:cache.Set('key', 'value')
            $script:cache.Save()
            $script:cache.IsDirty = $false
            
            $script:cache.Remove('key')
            $script:cache.IsDirty | Should -Be $true
        }
        
        It 'Should mark as dirty on Clear' {
            $script:cache.Set('key', 'value')
            $script:cache.Save()
            $script:cache.IsDirty = $false
            
            $script:cache.Clear()
            $script:cache.IsDirty | Should -Be $true
        }
        
        It 'Should mark as not dirty after Save' {
            $script:cache.Set('key', 'value')
            $script:cache.IsDirty | Should -Be $true
            
            $script:cache.Save()
            $script:cache.IsDirty | Should -Be $false
        }
    }
}

Describe 'Cache Class - Advanced Operations' -Tag 'Unit' {
    BeforeEach {
        $script:cache = [Cache]::new('test-advanced', $script:TestCacheDir)
    }
    
    AfterEach {
        if ($script:cache.CacheFile -and (Test-Path $script:cache.CacheFile)) {
            Remove-Item $script:cache.CacheFile -Force
        }
    }
    
    Context 'GetKeys' {
        It 'Should return all valid keys' {
            $script:cache.Set('key1', 'value1')
            $script:cache.Set('key2', 'value2')
            $script:cache.Set('key3', 'value3', 1)  # Will expire
            
            Start-Sleep -Seconds 2
            
            $keys = $script:cache.GetKeys()
            $keys.Count | Should -Be 2
            $keys | Should -Contain 'key1'
            $keys | Should -Contain 'key2'
            $keys | Should -Not -Contain 'key3'  # Expired
        }
        
        It 'Should return empty array for empty cache' {
            $keys = $script:cache.GetKeys()
            $keys | Should -BeNullOrEmpty
        }
    }
    
    Context 'GetStats' {
        It 'Should return cache statistics' {
            $script:cache.Set('key1', 'value1')
            $script:cache.Set('key2', 'value2')
            $script:cache.Set('key3', 'value3', 1)  # Will expire
            
            Start-Sleep -Seconds 2
            
            $stats = $script:cache.GetStats()
            
            $stats.TotalEntries | Should -Be 3
            $stats.ValidEntries | Should -Be 2
            $stats.ExpiredEntries | Should -Be 1
            $stats.CacheFile | Should -Be $script:cache.CacheFile
        }
        
        It 'Should show IsDirty status' {
            $script:cache.Set('key', 'value')
            $stats = $script:cache.GetStats()
            $stats.IsDirty | Should -Be $true
        }
    }
    
    Context 'RemoveExpired' {
        It 'Should remove expired entries' {
            $script:cache.Set('permanent', 'value')
            $script:cache.Set('expiring1', 'value1', 1)
            $script:cache.Set('expiring2', 'value2', 1)
            
            Start-Sleep -Seconds 2
            
            $removed = $script:cache.RemoveExpired()
            
            $removed | Should -Be 2
            $script:cache.Contains('permanent') | Should -Be $true
            $script:cache.Contains('expiring1') | Should -Be $false
            $script:cache.Contains('expiring2') | Should -Be $false
        }
        
        It 'Should return 0 if no expired entries' {
            $script:cache.Set('key1', 'value1')
            $script:cache.Set('key2', 'value2')
            
            $removed = $script:cache.RemoveExpired()
            $removed | Should -Be 0
        }
        
        It 'Should mark as dirty after removing expired entries' {
            $script:cache.Set('expiring', 'value', 1)
            $script:cache.Save()
            $script:cache.IsDirty = $false
            
            Start-Sleep -Seconds 2
            $script:cache.RemoveExpired()
            
            $script:cache.IsDirty | Should -Be $true
        }
    }
}
