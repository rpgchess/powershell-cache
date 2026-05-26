#Requires -Version 5.1

<#
.SYNOPSIS
    Script de build para o módulo Cache.

.DESCRIPTION
    Automatiza tarefas de build, teste e validação do módulo Cache:
    - Validação de código com PSScriptAnalyzer
    - Execução de testes Pester
    - Geração de relatórios
    - Empacotamento do módulo
    
    Tarefas disponíveis:
    - Clean: Limpa arquivos temporários
    - Analyze: Valida código com PSScriptAnalyzer
    - Test: Executa testes Pester
    - Build: Build completo (Clean + Analyze + Test)
    - Package: Cria arquivo .zip para distribuição
    - All: Todas as tarefas (Build + Package)

.PARAMETER Task
    Tarefa a executar: Clean, Analyze, Test, Build, Package, All.
    Default: Build

.PARAMETER Configuration
    Configuração de build: Debug ou Release.
    Default: Debug

.PARAMETER SkipTests
    Pula execução de testes Pester.

.EXAMPLE
    PS> .\Build.ps1
    Executa build completo (Clean + Analyze + Test).

.EXAMPLE
    PS> .\Build.ps1 -Task Test
    Executa apenas testes Pester.

.EXAMPLE
    PS> .\Build.ps1 -Task All -Configuration Release
    Build completo em modo Release e cria pacote.

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-26
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('Clean', 'Analyze', 'Test', 'Build', 'Package', 'All')]
    [string] $Task = 'Build',
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('Debug', 'Release')]
    [string] $Configuration = 'Debug',
    
    [Parameter(Mandatory = $false)]
    [switch] $SkipTests
)

begin {
    $ErrorActionPreference = 'Stop'
    
    # Colors
    $script:Colors = @{
        Header  = 'Cyan'
        Success = 'Green'
        Warning = 'Yellow'
        Error   = 'Red'
        Info    = 'Gray'
    }
    
    # Paths
    $script:ProjectRoot = $PSScriptRoot
    $script:OutputDir = Join-Path $script:ProjectRoot 'out'
    $script:TestResultsDir = Join-Path $script:ProjectRoot 'Tests' 'reports'
    $script:PackageDir = Join-Path $script:ProjectRoot 'Package'
    
    # Module info
    $script:ModuleName = 'Cache'
    $script:ModuleManifest = Join-Path $script:ProjectRoot "$script:ModuleName.psd1"
    
    function Write-TaskHeader {
        param([string] $TaskName)
        Write-Host "`n$('=' * 70)" -ForegroundColor $script:Colors.Header
        Write-Host "  TASK: $TaskName" -ForegroundColor $script:Colors.Header
        Write-Host "$('=' * 70)" -ForegroundColor $script:Colors.Header
    }
    
    function Write-TaskSuccess {
        param([string] $Message)
        Write-Host "✓ $Message" -ForegroundColor $script:Colors.Success
    }
    
    function Write-TaskError {
        param([string] $Message)
        Write-Host "✗ $Message" -ForegroundColor $script:Colors.Error
    }
}

process {
    Write-Host "`n$('=' * 70)" -ForegroundColor $script:Colors.Header
    Write-Host "  Cache Module - Build Script v1.0.0" -ForegroundColor $script:Colors.Header
    Write-Host "$('=' * 70)" -ForegroundColor $script:Colors.Header
    
    Write-Host "`nConfiguração:" -ForegroundColor $script:Colors.Info
    Write-Host "  Tarefa: $Task" -ForegroundColor Gray
    Write-Host "  Configuração: $Configuration" -ForegroundColor Gray
    Write-Host "  Pular testes: $SkipTests" -ForegroundColor Gray
    Write-Host "  Diretório: $script:ProjectRoot" -ForegroundColor Gray
    
    # Task: Clean
    if ($Task -in @('Clean', 'Build', 'All')) {
        Write-TaskHeader "Clean"
        
        try {
            # Remove output directories
            if (Test-Path $script:OutputDir) {
                Remove-Item $script:OutputDir -Recurse -Force
                Write-TaskSuccess "Removido diretório de output"
            }
            
            # Remove cache files
            Get-ChildItem -Path $script:ProjectRoot -Filter '*.cache' -Recurse | Remove-Item -Force
            Write-TaskSuccess "Removidos arquivos .cache"
            
            # Create directories
            New-Item -ItemType Directory -Path $script:OutputDir -Force | Out-Null
            New-Item -ItemType Directory -Path $script:TestResultsDir -Force | Out-Null
            Write-TaskSuccess "Diretórios de output criados"
            
        } catch {
            Write-TaskError "Falha no Clean: $($_.Exception.Message)"
            throw
        }
    }
    
    # Task: Analyze
    if ($Task -in @('Analyze', 'Build', 'All')) {
        Write-TaskHeader "Analyze (PSScriptAnalyzer)"
        
        try {
            # Check if PSScriptAnalyzer is installed
            if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
                Write-TaskError "PSScriptAnalyzer não instalado. Execute Install-Dependencies.ps1"
                throw "Dependência não satisfeita: PSScriptAnalyzer"
            }
            
            Import-Module PSScriptAnalyzer -Force
            
            # Run analysis
            $settingsPath = Join-Path $script:ProjectRoot '.vscode\PSScriptAnalyzerSettings.psd1'
            if (Test-Path $settingsPath) {
                $analysisResults = Invoke-ScriptAnalyzer -Path $script:ProjectRoot -Recurse -Settings $settingsPath
            } else {
                $analysisResults = Invoke-ScriptAnalyzer -Path $script:ProjectRoot -Recurse
            }
            
            # Filter errors
            $errors = $analysisResults | Where-Object { $_.Severity -eq 'Error' }
            $warnings = $analysisResults | Where-Object { $_.Severity -eq 'Warning' }
            
            Write-Host "`nResultados:" -ForegroundColor $script:Colors.Info
            Write-Host "  Erros: $($errors.Count)" -ForegroundColor $(if ($errors.Count -gt 0) { $script:Colors.Error } else { $script:Colors.Success })
            Write-Host "  Warnings: $($warnings.Count)" -ForegroundColor $script:Colors.Warning
            
            if ($errors.Count -gt 0) {
                Write-Host "`nErros encontrados:" -ForegroundColor $script:Colors.Error
                $errors | Format-Table RuleName, ScriptName, Line, Message -AutoSize
                throw "PSScriptAnalyzer encontrou $($errors.Count) erro(s)"
            }
            
            Write-TaskSuccess "Código validado sem erros críticos"
            
        } catch {
            Write-TaskError "Falha no Analyze: $($_.Exception.Message)"
            throw
        }
    }
    
    # Task: Test
    if (-not $SkipTests -and $Task -in @('Test', 'Build', 'All')) {
        Write-TaskHeader "Test (Pester)"
        
        try {
            # Check if Pester is installed
            if (-not (Get-Module -ListAvailable -Name Pester)) {
                Write-TaskError "Pester não instalado. Execute Install-Dependencies.ps1"
                throw "Dependência não satisfeita: Pester"
            }
            
            Import-Module Pester -MinimumVersion 5.0 -Force
            
            # Configure Pester
            $pesterConfig = New-PesterConfiguration
            $pesterConfig.Run.Path = Join-Path $script:ProjectRoot 'Tests'
            $pesterConfig.Run.PassThru = $true
            $pesterConfig.Output.Verbosity = 'Detailed'
            $pesterConfig.TestResult.Enabled = $true
            $pesterConfig.TestResult.OutputPath = Join-Path $script:TestResultsDir 'TestResults.xml'
            $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
            
            # Run tests
            $testResults = Invoke-Pester -Configuration $pesterConfig
            
            Write-Host "`nResultados:" -ForegroundColor $script:Colors.Info
            Write-Host "  Total: $($testResults.TotalCount)" -ForegroundColor Gray
            Write-Host "  Passou: $($testResults.PassedCount)" -ForegroundColor $script:Colors.Success
            Write-Host "  Falhou: $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -gt 0) { $script:Colors.Error } else { $script:Colors.Success })
            Write-Host "  Pulados: $($testResults.SkippedCount)" -ForegroundColor $script:Colors.Warning
            
            if ($testResults.FailedCount -gt 0) {
                throw "Pester encontrou $($testResults.FailedCount) teste(s) falhando"
            }
            
            Write-TaskSuccess "Todos os testes passaram"
            
        } catch {
            Write-TaskError "Falha no Test: $($_.Exception.Message)"
            throw
        }
    }
    
    # Task: Package
    if ($Task -in @('Package', 'All')) {
        Write-TaskHeader "Package"
        
        try {
            # Create package directory
            if (Test-Path $script:PackageDir) {
                Remove-Item $script:PackageDir -Recurse -Force
            }
            New-Item -ItemType Directory -Path $script:PackageDir -Force | Out-Null
            
            # Get module version
            $manifest = Import-PowerShellDataFile -Path $script:ModuleManifest
            $version = $manifest.ModuleVersion
            
            # Create temp staging folder
            $tempDir = Join-Path $env:TEMP "Cache-$version-$(Get-Date -Format 'yyyyMMddHHmmss')"
            $moduleDir = Join-Path $tempDir $script:ModuleName
            New-Item -ItemType Directory -Path $moduleDir -Force | Out-Null
            
            # Copy essential files
            $filesToCopy = @(
                "$script:ModuleName.psd1",
                "$script:ModuleName.psm1",
                'README.md',
                'CHANGELOG.md',
                'LICENSE'
            )
            
            foreach ($file in $filesToCopy) {
                $sourcePath = Join-Path $script:ProjectRoot $file
                if (Test-Path $sourcePath) {
                    Copy-Item $sourcePath -Destination $moduleDir -Force
                }
            }
            
            # Copy directories
            $dirsToCopy = @('Core', 'Tests')
            foreach ($dir in $dirsToCopy) {
                $sourcePath = Join-Path $script:ProjectRoot $dir
                if (Test-Path $sourcePath) {
                    Copy-Item $sourcePath -Destination $moduleDir -Recurse -Force
                }
            }
            
            # Create ZIP file
            $zipPath = Join-Path $script:PackageDir "$script:ModuleName-v$version.zip"
            Compress-Archive -Path $moduleDir -DestinationPath $zipPath -Force
            
            # Clean temp folder
            Remove-Item $tempDir -Recurse -Force
            
            $zipSize = (Get-Item $zipPath).Length / 1KB
            Write-TaskSuccess "Pacote criado: $zipPath ($([math]::Round($zipSize, 2)) KB)"
            
        } catch {
            Write-TaskError "Falha no Package: $($_.Exception.Message)"
            throw
        }
    }
}

end {
    Write-Host "`n$('=' * 70)" -ForegroundColor $script:Colors.Success
    Write-Host "  ✓ Build concluído com sucesso!" -ForegroundColor $script:Colors.Success
    Write-Host "$('=' * 70)`n" -ForegroundColor $script:Colors.Success
}
