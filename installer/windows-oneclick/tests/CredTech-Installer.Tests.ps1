$script:ScriptUnderTest = ''
$resolvedScript = Resolve-Path (Join-Path $PSScriptRoot '..\CredTech-Installer.ps1') -ErrorAction SilentlyContinue
if ($resolvedScript) {
  $script:ScriptUnderTest = $resolvedScript.Path
}
$script:ProgramDataRoot = 'C:\ProgramData\CredTechInstaller'
$script:LogPath = Join-Path $script:ProgramDataRoot 'logs\install.log'
$script:ReportPath = Join-Path $script:ProgramDataRoot 'install-report.txt'
$script:ConfigPath = Join-Path $script:ProgramDataRoot 'config.json'
$script:BundleZipPath = Join-Path $script:ProgramDataRoot 'bundles\current.zip'
$script:AppDir = Join-Path $script:ProgramDataRoot 'app'
$script:LocalAppData = [Environment]::GetFolderPath('LocalApplicationData')
$script:LocalCredTech = Join-Path $script:LocalAppData 'CredTech'
$script:StableBundleUrl = 'https://github.com/yasminmelo83374/agente-yah/releases/latest/download/credtech-bundle.zip'

Describe 'CredTech-Installer.ps1' {
  BeforeAll {
    $script:ProgramDataRoot = 'C:\ProgramData\CredTechInstaller'
    $script:LogPath = Join-Path $script:ProgramDataRoot 'logs\install.log'
    $script:ReportPath = Join-Path $script:ProgramDataRoot 'install-report.txt'
    $script:ConfigPath = Join-Path $script:ProgramDataRoot 'config.json'
    $script:BundleZipPath = Join-Path $script:ProgramDataRoot 'bundles\current.zip'
    $script:AppDir = Join-Path $script:ProgramDataRoot 'app'
    $script:StableBundleUrl = 'https://github.com/yasminmelo83374/agente-yah/releases/latest/download/credtech-bundle.zip'
    $script:LocalAppData = [Environment]::GetFolderPath('LocalApplicationData')
    if ([string]::IsNullOrWhiteSpace($script:LocalAppData)) {
      $script:LocalAppData = $env:TEMP
    }
    $script:LocalCredTech = Join-Path $script:LocalAppData 'CredTech'

    $script:TestScriptUnderTest = Resolve-Path (Join-Path $PSScriptRoot '..\CredTech-Installer.ps1') -ErrorAction SilentlyContinue
    if ($script:TestScriptUnderTest) {
      $script:TestScriptUnderTest = $script:TestScriptUnderTest.Path
    }
    if ([string]::IsNullOrWhiteSpace($script:TestScriptUnderTest)) {
      $fallback = Resolve-Path 'installer/windows-oneclick/CredTech-Installer.ps1' -ErrorAction SilentlyContinue
      if ($fallback) {
        $script:TestScriptUnderTest = $fallback.Path
      }
    }
    $script:TestProgramDataRoot = $script:ProgramDataRoot
    $script:TestLocalCredTech = $script:LocalCredTech

    function script:Reset-CredTechPaths {
      if (-not [string]::IsNullOrWhiteSpace($script:TestProgramDataRoot)) {
        if (Test-Path $script:TestProgramDataRoot) { Remove-Item -Recurse -Force $script:TestProgramDataRoot }
      }
      if (-not [string]::IsNullOrWhiteSpace($script:TestLocalCredTech)) {
        if (Test-Path $script:TestLocalCredTech) { Remove-Item -Recurse -Force $script:TestLocalCredTech }
      }
    }

    function script:Invoke-InstallerMode {
      param(
        [Parameter(Mandatory = $true)][string]$Mode,
        [string]$ProjectBundleUrl,
        [string]$ForceFailMode
      )

      $prev = $env:CREDTECH_FORCE_FAIL
      if ($ForceFailMode) {
        $env:CREDTECH_FORCE_FAIL = $ForceFailMode
      } else {
        Remove-Item Env:CREDTECH_FORCE_FAIL -ErrorAction SilentlyContinue
      }

      if ([string]::IsNullOrWhiteSpace($script:TestScriptUnderTest)) {
        throw 'ScriptUnderTest nao resolvido para execucao.'
      }

      $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:TestScriptUnderTest, '-Mode', $Mode, '-NoReboot')
      if ($ProjectBundleUrl) {
        $args += @('-ProjectBundleUrl', $ProjectBundleUrl)
      }

      & powershell.exe @args | Out-Null
      $exitCode = $LASTEXITCODE

      if ($null -ne $prev) {
        $env:CREDTECH_FORCE_FAIL = $prev
      } else {
        Remove-Item Env:CREDTECH_FORCE_FAIL -ErrorAction SilentlyContinue
      }

      return $exitCode
    }
  }

  BeforeEach {
    script:Reset-CredTechPaths
  }

  It 'Ensure-Directories cria todas as pastas obrigatorias' {
    $code = script:Invoke-InstallerMode -Mode Diagnose -ForceFailMode Diagnose
    $code | Should -Be 1

    (Test-Path 'C:\ProgramData\CredTechInstaller') | Should -BeTrue
    (Test-Path 'C:\ProgramData\CredTechInstaller\logs') | Should -BeTrue
    (Test-Path 'C:\ProgramData\CredTechInstaller\state') | Should -BeTrue
    (Test-Path (Join-Path $script:LocalAppData 'CredTech')) | Should -BeTrue
  }

  It 'config.json e criado e contem project_bundle_url' {
    $null = script:Invoke-InstallerMode -Mode Diagnose -ForceFailMode Diagnose

    (Test-Path $script:ConfigPath) | Should -BeTrue
    $cfg = Get-Content -Raw -Path $script:ConfigPath | ConvertFrom-Json
    $cfg.project_bundle_url | Should -Not -BeNullOrEmpty
  }

  It 'Resolve-BundleUrl respeita prioridade parameter > config > env' {
    script:Reset-CredTechPaths
    New-Item -ItemType Directory -Force -Path $script:ProgramDataRoot | Out-Null
    @{ project_bundle_url = 'https://config.example/bundle.zip' } | ConvertTo-Json -Depth 5 | Set-Content -Path $script:ConfigPath -Encoding UTF8
    $env:CREDTECH_BUNDLE_URL = 'https://env.example/bundle.zip'

    $null = script:Invoke-InstallerMode -Mode Diagnose -ProjectBundleUrl 'https://param.example/bundle.zip'
    $report = Get-Content -Raw -Path $script:ReportPath
    $report | Should -Match 'Bundle URL origem: parameter'
    $report | Should -Match 'https://param\.example/bundle\.zip'

    script:Reset-CredTechPaths
    New-Item -ItemType Directory -Force -Path $script:ProgramDataRoot | Out-Null
    @{ project_bundle_url = 'https://config.example/bundle.zip' } | ConvertTo-Json -Depth 5 | Set-Content -Path $script:ConfigPath -Encoding UTF8
    $null = script:Invoke-InstallerMode -Mode Diagnose
    $report = Get-Content -Raw -Path $script:ReportPath
    $report | Should -Match 'Bundle URL origem: config'
    $report | Should -Match 'https://config\.example/bundle\.zip'

    script:Reset-CredTechPaths
    New-Item -ItemType Directory -Force -Path $script:ProgramDataRoot | Out-Null
    @{} | ConvertTo-Json | Set-Content -Path $script:ConfigPath -Encoding UTF8
    $env:CREDTECH_BUNDLE_URL = 'https://env.example/bundle.zip'
    $null = script:Invoke-InstallerMode -Mode Diagnose
    $report = Get-Content -Raw -Path $script:ReportPath
    $report | Should -Match 'Bundle URL origem: environment'
    $report | Should -Match 'https://env\.example/bundle\.zip'

    Remove-Item Env:CREDTECH_BUNDLE_URL -ErrorAction SilentlyContinue
  }

  It 'Download-Bundle baixa zip de teste e Extract-Bundle extrai docker-compose.yml' {
    $code = script:Invoke-InstallerMode -Mode ValidateOnly -ProjectBundleUrl $script:StableBundleUrl
    $code | Should -Be 0

    (Test-Path $script:BundleZipPath) | Should -BeTrue
    (Get-Item $script:BundleZipPath).Length | Should -BeGreaterThan 1000
    (Test-Path (Join-Path $script:AppDir 'docker-compose.yml')) | Should -BeTrue
  }

  It 'Diagnose, Install e Repair geram report e log mesmo em falha' {
    foreach ($mode in @('Diagnose','Install','Repair')) {
      script:Reset-CredTechPaths
      $code = script:Invoke-InstallerMode -Mode $mode -ForceFailMode $mode
      $code | Should -Be 1
      (Test-Path $script:ReportPath) | Should -BeTrue
      (Test-Path $script:LogPath) | Should -BeTrue
      (Get-Content -Raw -Path $script:ReportPath) | Should -Match 'RESULT: FAILED'
    }
  }
}
