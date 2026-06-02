#Requires -Version 5.1

<#
.SYNOPSIS
    Script de build para o módulo Cache.
.DESCRIPTION
    Automatiza tarefas de build, teste e validação: Clean, Analyze, Test, Build, Package, All.
.PARAMETER Task
    Tarefa a executar. Padrão: Build
.PARAMETER Configuration
    Debug ou Release. Padrão: Debug. Release ativa code coverage.
.PARAMETER SkipTests
    Pula execução de testes.
.EXAMPLE
    PS> .\Build.ps1 -Task All -Configuration Release
.NOTES
    Author: Claudio Almeida
    Date: 2026-06-01
    Version: 1.1.0
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Clean', 'Analyze', 'Test', 'Build', 'Package', 'All')]
    [string] $Task = 'Build',

    [ValidateSet('Debug', 'Release')]
    [string] $Configuration = 'Debug',

    [switch] $SkipTests
)

. $PSScriptRoot\BuildHelper.ps1

Start-Build -Task $Task -Configuration $Configuration -SkipTests:$SkipTests `
    -ModuleName 'Cache' `
    -ManifestFileName 'Cache.psd1' `
    -RequiredFiles @('Cache.psd1', 'Cache.psm1', 'Core\Cache.ps1') `
    -PackageFiles @('*.psd1', '*.psm1', 'Core\*', 'README.md', 'CHANGELOG.md', 'LICENSE') `
    -CleanPatterns @('*.cache')
