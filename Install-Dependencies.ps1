#Requires -Version 5.1

<#
.SYNOPSIS
    Instala dependências do módulo Cache.

.DESCRIPTION
    Instala módulos necessários para desenvolvimento e teste do Cache:
    - Pester 5.x: Framework de testes
    - PSScriptAnalyzer: Análise estática de código
    
    Suporta PowerShell 5.1+ e PowerShell 7+.

.PARAMETER Scope
    Escopo de instalação: CurrentUser ou AllUsers.
    Default: CurrentUser

.PARAMETER Force
    Força reinstalação mesmo se já instalado.

.EXAMPLE
    PS> .\Install-Dependencies.ps1
    Instala dependências para o usuário atual.

.EXAMPLE
    PS> .\Install-Dependencies.ps1 -Scope AllUsers -Force
    Reinstala dependências para todos os usuários.

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-26
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string] $Scope = 'CurrentUser',
    
    [Parameter(Mandatory = $false)]
    [switch] $Force
)

begin {
    $ErrorActionPreference = 'Stop'
    
    Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
    Write-Host "  Cache Module - Install Dependencies" -ForegroundColor Cyan
    Write-Host "$('=' * 70)`n" -ForegroundColor Cyan
    
    # Dependencies from requirements.psd1
    $requirementsFile = Join-Path $PSScriptRoot 'requirements.psd1'
    
    if (Test-Path $requirementsFile) {
        $requirements = Import-PowerShellDataFile -Path $requirementsFile
    } else {
        Write-Warning "requirements.psd1 não encontrado. Usando dependências padrão."
        $requirements = @{
            PSDependencies = @{
                Pester = @{
                    Version = '5.5.0'
                    Repository = 'PSGallery'
                }
                PSScriptAnalyzer = @{
                    Version = '1.21.0'
                    Repository = 'PSGallery'
                }
            }
        }
    }
}

process {
    Write-Host "Escopo: $Scope" -ForegroundColor Gray
    Write-Host "Forçar reinstalação: $Force`n" -ForegroundColor Gray
    
    foreach ($module in $requirements.PSDependencies.Keys) {
        $dependency = $requirements.PSDependencies[$module]
        
        Write-Host "Verificando $module..." -ForegroundColor Yellow
        
        $installed = Get-Module -ListAvailable -Name $module | 
            Where-Object { $_.Version -ge [version]$dependency.Version } |
            Select-Object -First 1
        
        if ($installed -and -not $Force) {
            Write-Host "  ✓ $module v$($installed.Version) já instalado" -ForegroundColor Green
            continue
        }
        
        try {
            $installParams = @{
                Name = $module
                MinimumVersion = $dependency.Version
                Repository = $dependency.Repository
                Scope = $Scope
                Force = $Force
                AllowClobber = $true
                SkipPublisherCheck = $true
            }
            
            Write-Host "  Instalando $module v$($dependency.Version)..." -ForegroundColor Cyan
            Install-Module @installParams
            
            $newVersion = (Get-Module -ListAvailable -Name $module | Sort-Object Version -Descending | Select-Object -First 1).Version
            Write-Host "  ✓ $module v$newVersion instalado" -ForegroundColor Green
            
        } catch {
            Write-Host "  ✗ Falha ao instalar $module : $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
    }
}

end {
    Write-Host "`n$('=' * 70)" -ForegroundColor Green
    Write-Host "  ✓ Dependências instaladas com sucesso!" -ForegroundColor Green
    Write-Host "$('=' * 70)`n" -ForegroundColor Green
    
    Write-Host "Próximos passos:" -ForegroundColor Yellow
    Write-Host "  1. Execute: .\Build.ps1" -ForegroundColor Gray
    Write-Host "  2. Para testes: .\Build.ps1 -Task Test" -ForegroundColor Gray
    Write-Host "  3. Para pacote: .\Build.ps1 -Task All`n" -ForegroundColor Gray
}
