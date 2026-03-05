param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('Diagnose','Repair','Install','ResetProject')]
  [string]$Mode,
  [string]$ProjectBundleUrl,
  [switch]$NoReboot
)

$ErrorActionPreference = 'Stop'

$ProgramDataRoot = 'C:\ProgramData\CredTechInstaller'
$LogDir = Join-Path $ProgramDataRoot 'logs'
$StateDir = Join-Path $ProgramDataRoot 'state'
$BundleDir = Join-Path $ProgramDataRoot 'bundles'
$AppDir = Join-Path $ProgramDataRoot 'app'
$ConfigPath = Join-Path $ProgramDataRoot 'config.json'
$StatePath = Join-Path $StateDir 'state.json'
$LogPath = Join-Path $LogDir 'install.log'
$ReportPath = Join-Path $ProgramDataRoot 'install-report.txt'
$BundleZipPath = Join-Path $BundleDir 'current.zip'
$LocalAppDataRoot = Join-Path $env:LOCALAPPDATA 'CredTech'
$ScriptPath = $MyInvocation.MyCommand.Path
$DefaultBundleUrl = 'https://github.com/yasminmelo83374/agente-yah/releases/latest/download/credtech-bundle.zip'

$ReportLines = New-Object System.Collections.Generic.List[string]
$script:HadFailures = $false
$script:ResultTag = 'SUCCESS'

function Ensure-Directories {
  New-Item -Path $ProgramDataRoot -ItemType Directory -Force | Out-Null
  New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
  New-Item -Path $StateDir -ItemType Directory -Force | Out-Null
  New-Item -Path $BundleDir -ItemType Directory -Force | Out-Null
  New-Item -Path $LocalAppDataRoot -ItemType Directory -Force | Out-Null
}

function Ensure-OutputFiles {
  if (-not (Test-Path $LogPath)) {
    Set-Content -Path $LogPath -Value "$(Get-Date -Format o) [$Mode] log iniciado" -Encoding UTF8
  }
  if (-not (Test-Path $ReportPath)) {
    Set-Content -Path $ReportPath -Value "CredTech Installer Report`n" -Encoding UTF8
  }
}

function Write-Log([string]$Message) {
  $line = "$(Get-Date -Format o) [$Mode] $Message"
  Add-Content -Path $LogPath -Value $line -Encoding UTF8
}

function Add-Report([string]$Message) {
  $ReportLines.Add($Message)
}

function Flush-Report([string]$Status) {
  $header = @(
    'CredTech Installer Report',
    "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Mode: $Mode",
    "Status: $Status",
    ''
  )
  $resultLine = "RESULT: $script:ResultTag"
  $content = $header + $ReportLines + @('', $resultLine)
  Set-Content -Path $ReportPath -Value $content -Encoding UTF8
}

function Load-State {
  if (-not (Test-Path $StatePath)) {
    return @{ version = 1; rebootPending = $false; resumeMode = ''; bundleUrl = ''; lastRun = '' }
  }
  try {
    return Get-Content -Path $StatePath -Raw | ConvertFrom-Json -AsHashtable
  } catch {
    return @{ version = 1; rebootPending = $false; resumeMode = ''; bundleUrl = ''; lastRun = '' }
  }
}

function Save-State([hashtable]$State) {
  $State.lastRun = (Get-Date).ToString('o')
  $State | ConvertTo-Json -Depth 10 | Set-Content -Path $StatePath -Encoding UTF8
}

function Is-Admin {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-Admin {
  if (-not (Is-Admin)) {
    throw 'Este instalador precisa de permissao de administrador.'
  }
}

function Mark-Failure([string]$Message) {
  $script:HadFailures = $true
  $script:ResultTag = 'FAILED'
  Write-Log "FAIL: $Message"
  Add-Report "FAIL: $Message"
}

function Safe-Exec([scriptblock]$Code, [string]$Label) {
  try {
    & $Code
    Write-Log "${Label}: OK"
    Add-Report "${Label}: OK"
    return $true
  } catch {
    $msg = $_.Exception.Message
    Mark-Failure "$Label - $msg"
    return $false
  }
}

function Get-ConfigBundleUrl {
  if (-not (Test-Path $ConfigPath)) {
    return ''
  }
  try {
    $cfg = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json -AsHashtable
    if ($cfg.ContainsKey('project_bundle_url')) {
      return [string]$cfg.project_bundle_url
    }
  } catch {
    Write-Log 'config.json invalido; ignorando para leitura de URL.'
  }
  return ''
}

function Ensure-ConfigTemplate {
  if (Test-Path $ConfigPath) {
    return
  }

  $template = @{ project_bundle_url = $DefaultBundleUrl }
  $template | ConvertTo-Json -Depth 5 | Set-Content -Path $ConfigPath -Encoding UTF8
  Add-Report "Config criado automaticamente em $ConfigPath"
  Add-Report "project_bundle_url definido para: $DefaultBundleUrl"
  Write-Log "config.json criado com URL padrao"
}

function Save-ConfigBundleUrl([string]$Url) {
  if ([string]::IsNullOrWhiteSpace($Url)) {
    return
  }

  $cfg = @{}
  if (Test-Path $ConfigPath) {
    try {
      $cfg = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json -AsHashtable
    } catch {
      $cfg = @{}
    }
  }

  $cfg.project_bundle_url = $Url.Trim()
  $cfg | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
  Write-Log "config.json atualizado com URL do bundle"
}

function Resolve-BundleUrl {
  if (-not [string]::IsNullOrWhiteSpace($ProjectBundleUrl)) {
    return $ProjectBundleUrl.Trim()
  }
  $cfg = Get-ConfigBundleUrl
  if (-not [string]::IsNullOrWhiteSpace($cfg)) {
    return $cfg.Trim()
  }
  if (-not [string]::IsNullOrWhiteSpace($env:CREDTECH_BUNDLE_URL)) {
    return $env:CREDTECH_BUNDLE_URL.Trim()
  }
  return ''
}

function Register-Resume([string]$ResumeMode, [string]$BundleUrl) {
  $state = Load-State
  $state.rebootPending = $true
  $state.resumeMode = $ResumeMode
  $state.bundleUrl = $BundleUrl
  Save-State $state

  $argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File','"' + $ScriptPath + '"','-Mode',$ResumeMode)
  if (-not [string]::IsNullOrWhiteSpace($BundleUrl)) {
    $argList += '-ProjectBundleUrl'
    $argList += '"' + $BundleUrl + '"'
  }
  if ($NoReboot) {
    $argList += '-NoReboot'
  }

  $cmd = 'powershell.exe ' + ($argList -join ' ')
  New-Item -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Force | Out-Null
  Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'CredTechInstallerResume' -Value $cmd

  Add-Report 'Retomada apos reboot registrada.'
  Write-Log 'RunOnce registrado para retomada.'
}

function Clear-ResumeState {
  $state = Load-State
  $state.rebootPending = $false
  $state.resumeMode = ''
  Save-State $state
}

function Test-PendingReboot {
  $pending = $false
  if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') { $pending = $true }
  if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') { $pending = $true }
  return $pending
}

function Get-FeatureState([string]$Name) {
  try {
    return (Get-WindowsOptionalFeature -Online -FeatureName $Name).State
  } catch {
    return 'Unknown'
  }
}

function Get-DiagnosticSnapshot {
  $os = Get-CimInstance Win32_OperatingSystem
  $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
  $virtEnabled = $false
  try { $virtEnabled = [bool]$cpu.VirtualizationFirmwareEnabled } catch {}

  $dockerInstalled = [bool](Get-Command docker.exe -ErrorAction SilentlyContinue)
  $dockerRunning = $false
  if ($dockerInstalled) {
    try {
      $v = docker version --format '{{.Server.Version}}' 2>$null
      if (-not [string]::IsNullOrWhiteSpace($v)) { $dockerRunning = $true }
    } catch {}
  }

  $wslInstalled = [bool](Get-Command wsl.exe -ErrorAction SilentlyContinue)
  $wslStatus = ''
  if ($wslInstalled) {
    try { $wslStatus = (& wsl.exe --status | Out-String).Trim() } catch {}
  }

  return @{
    virtualizationFirmwareEnabled = $virtEnabled
    windowsVersion = "$($os.Caption) ($($os.BuildNumber))"
    featureWSL = Get-FeatureState 'Microsoft-Windows-Subsystem-Linux'
    featureVMP = Get-FeatureState 'VirtualMachinePlatform'
    featureHyperV = Get-FeatureState 'Microsoft-Hyper-V-All'
    dockerInstalled = $dockerInstalled
    dockerRunning = $dockerRunning
    wslInstalled = $wslInstalled
    wslStatus = $wslStatus
    cpu = $cpu.Name
    ramFreeGb = [math]::Round(($os.FreePhysicalMemory * 1KB) / 1GB, 2)
  }
}

function Write-DiagnoseReport([hashtable]$Diag) {
  Add-Report "Virtualizacao BIOS/UEFI ativa: $($Diag.virtualizationFirmwareEnabled)"
  Add-Report "Windows: $($Diag.windowsVersion)"
  Add-Report "Feature WSL: $($Diag.featureWSL)"
  Add-Report "Feature VirtualMachinePlatform: $($Diag.featureVMP)"
  Add-Report "Feature Hyper-V: $($Diag.featureHyperV)"
  Add-Report "WSL instalado: $($Diag.wslInstalled)"
  Add-Report "Docker instalado: $($Diag.dockerInstalled)"
  Add-Report "Docker rodando: $($Diag.dockerRunning)"
  Add-Report "CPU: $($Diag.cpu)"
  Add-Report "RAM livre (GB): $($Diag.ramFreeGb)"
  if (-not $Diag.virtualizationFirmwareEnabled) {
    Add-Report 'Acao necessaria: ative a virtualizacao na BIOS/UEFI e rode novamente.'
  }
}

function Enable-WindowsFeatures {
  $needsReboot = $false
  $features = @('Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform')
  foreach ($f in $features) {
    $state = Get-FeatureState $f
    if ($state -ne 'Enabled') {
      Write-Log "Habilitando recurso $f"
      & dism.exe /online /enable-feature /featurename:$f /all /norestart | Out-Null
      if (($LASTEXITCODE -eq 3010) -or ($LASTEXITCODE -eq 1641)) {
        $needsReboot = $true
      }
      if (($LASTEXITCODE -ne 0) -and ($LASTEXITCODE -ne 3010) -and ($LASTEXITCODE -ne 1641)) {
        throw "Falha ao habilitar recurso $f (codigo $LASTEXITCODE)."
      }
    }
  }
  if (Test-PendingReboot) { $needsReboot = $true }
  return $needsReboot
}

function Install-OrUpdate-WSL {
  if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    & wsl.exe --install --no-distribution | Out-Null
  }
  & wsl.exe --set-default-version 2 | Out-Null
  & wsl.exe --update | Out-Null
}

function Install-DockerFromWeb {
  $dockerInstaller = Join-Path $BundleDir 'DockerDesktopInstaller.exe'
  $dockerUrl = 'https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe'
  Write-Log "Baixando Docker Desktop installer: $dockerUrl"
  Invoke-WebRequest -Uri $dockerUrl -OutFile $dockerInstaller -UseBasicParsing -TimeoutSec 600

  Write-Log 'Executando instalador Docker (modo silencioso).'
  $p = Start-Process -FilePath $dockerInstaller -ArgumentList 'install --quiet --accept-license' -PassThru -Wait -WindowStyle Hidden
  if (($p.ExitCode -ne 0) -and ($p.ExitCode -ne 3010) -and ($p.ExitCode -ne 1641)) {
    Write-Log "Tentativa 1 falhou (exit $($p.ExitCode)), tentando /S"
    $p2 = Start-Process -FilePath $dockerInstaller -ArgumentList '/S' -PassThru -Wait -WindowStyle Hidden
    if (($p2.ExitCode -ne 0) -and ($p2.ExitCode -ne 3010) -and ($p2.ExitCode -ne 1641)) {
      throw "Falha no instalador Docker (codigo $($p2.ExitCode))."
    }
  }
}

function Ensure-DockerInstalled {
  if (Get-Command docker.exe -ErrorAction SilentlyContinue) {
    return
  }

  $wingetOk = $false
  if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
    try {
      Write-Log 'Instalando Docker Desktop via winget.'
      & winget install -e --id Docker.DockerDesktop --accept-package-agreements --accept-source-agreements --silent | Out-Null
      if ($LASTEXITCODE -eq 0) {
        $wingetOk = $true
      } else {
        Write-Log "winget falhou com codigo $LASTEXITCODE"
      }
    } catch {
      Write-Log "winget falhou: $($_.Exception.Message)"
    }
  } else {
    Write-Log 'winget nao encontrado. Usando fallback web.'
  }

  if (-not $wingetOk -and -not (Get-Command docker.exe -ErrorAction SilentlyContinue)) {
    Install-DockerFromWeb
  }
}

function Ensure-DockerRunning {
  $dockerExe = Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'
  if (Test-Path $dockerExe) {
    Start-Process -FilePath $dockerExe -WindowStyle Hidden | Out-Null
  }

  $maxAttempts = 72
  for ($i = 1; $i -le $maxAttempts; $i++) {
    Write-Log "Aguardando Docker iniciar ($i/$maxAttempts)"
    try {
      $v = docker version --format '{{.Server.Version}}' 2>$null
      if (-not [string]::IsNullOrWhiteSpace($v)) {
        Write-Log "Docker ativo (versao $v)"
        return
      }
    } catch {}
    Start-Sleep -Seconds 5
  }

  throw 'Docker Desktop nao iniciou em ate 6 minutos.'
}

function Prepare-BundleDestination {
  New-Item -Path $BundleDir -ItemType Directory -Force | Out-Null
  if (Test-Path $BundleZipPath) {
    Remove-Item -Path $BundleZipPath -Force
    Write-Log 'Bundle antigo removido (current.zip).'
  }
}

function Download-Bundle([string]$Url) {
  if ([string]::IsNullOrWhiteSpace($Url)) {
    throw 'PROJECT_BUNDLE_URL nao definido.'
  }
  Write-Log "Baixando bundle de $Url"
  Invoke-WebRequest -Uri $Url -OutFile $BundleZipPath -UseBasicParsing -TimeoutSec 300
}

function Extract-Bundle {
  if (-not (Test-Path $BundleZipPath)) {
    throw 'Bundle ZIP nao encontrado para extracao.'
  }

  if (Test-Path $AppDir) {
    Remove-Item -Path $AppDir -Recurse -Force
  }
  New-Item -Path $AppDir -ItemType Directory -Force | Out-Null

  try {
    Expand-Archive -Path $BundleZipPath -DestinationPath $AppDir -Force
  } catch {
    Write-Log 'Expand-Archive falhou. Tentando metodo alternativo .NET ZipFile.'
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($BundleZipPath, $AppDir)
  }
}

function Get-FreePort([int]$Preferred) {
  $ports = @(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty LocalPort -Unique)
  if (-not ($ports -contains $Preferred)) {
    return $Preferred
  }
  for ($p = $Preferred + 1; $p -lt ($Preferred + 100); $p++) {
    if (-not ($ports -contains $p)) { return $p }
  }
  return $Preferred
}

function Ensure-EnvPort([string]$EnvPath, [string]$Key, [int]$Preferred) {
  if (-not (Test-Path $EnvPath)) { return }
  $port = Get-FreePort $Preferred
  $lines = Get-Content -Path $EnvPath
  $found = $false
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "^$([Regex]::Escape($Key))=") {
      $lines[$i] = "$Key=$port"
      $found = $true
    }
  }
  if (-not $found) { $lines += "$Key=$port" }
  Set-Content -Path $EnvPath -Value $lines -Encoding UTF8
  Add-Report "$Key definido para porta $port"
}

function Prepare-AppEnv {
  $envExample = Join-Path $AppDir '.env.example'
  $envFile = Join-Path $AppDir '.env'

  if (Test-Path $envExample) {
    if (-not (Test-Path $envFile)) {
      Copy-Item -Path $envExample -Destination $envFile -Force
    }
    Ensure-EnvPort -EnvPath $envFile -Key 'API_PORT' -Preferred 8080
    Ensure-EnvPort -EnvPath $envFile -Key 'PANEL_PORT' -Preferred 3000
  }
}

function Get-EndpointUrls {
  $apiPort = 8080
  $panelPort = 3000
  $envFile = Join-Path $AppDir '.env'
  if (Test-Path $envFile) {
    $lines = Get-Content -Path $envFile
    foreach ($line in $lines) {
      if ($line -match '^API_PORT=(\d+)$') { $apiPort = [int]$Matches[1] }
      if ($line -match '^PANEL_PORT=(\d+)$') { $panelPort = [int]$Matches[1] }
    }
  }
  return @{ api = "http://localhost:$apiPort"; panel = "http://localhost:$panelPort" }
}

function Compose-Up {
  if (-not (Test-Path (Join-Path $AppDir 'docker-compose.yml'))) {
    throw 'docker-compose.yml nao encontrado no app extraido.'
  }

  Push-Location $AppDir
  try {
    & docker compose up -d | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw 'Falha ao subir docker compose.'
    }
  } finally {
    Pop-Location
  }
}

function Get-ComposePsText {
  if (-not (Test-Path (Join-Path $AppDir 'docker-compose.yml'))) {
    return 'compose nao encontrado'
  }

  Push-Location $AppDir
  try {
    $out = & docker compose ps 2>&1 | Out-String
    return $out.Trim()
  } catch {
    return 'falha ao obter docker compose ps'
  } finally {
    Pop-Location
  }
}

function Run-AppRepairScript {
  $repair = Join-Path $AppDir 'repair.ps1'
  if (-not (Test-Path $repair)) {
    Add-Report 'repair.ps1 nao encontrado no app. Seguindo com reparo interno.'
    return
  }
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $repair | Out-Null
}

function Restart-DockerBackend {
  try {
    & taskkill /IM 'Docker Desktop.exe' /F | Out-Null
  } catch {}
  Start-Sleep -Seconds 2
  $dockerExe = Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'
  if (Test-Path $dockerExe) {
    Start-Process -FilePath $dockerExe -WindowStyle Hidden | Out-Null
  }
  Ensure-DockerRunning
}

function Run-LocalHealthcheck {
  $health = Join-Path $AppDir 'healthcheck.ps1'
  if (-not (Test-Path $health)) {
    Add-Report 'Healthcheck: script nao encontrado.'
    return $false
  }

  try {
    $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $health
    $txt = ($out | Out-String).Trim()
    Add-Report "Healthcheck output: $txt"
    return ($txt -match 'OK')
  } catch {
    Add-Report 'Healthcheck output: FAIL'
    return $false
  }
}

function Test-Everything {
  $dockerOk = $false
  try {
    $v = docker version --format '{{.Server.Version}}' 2>$null
    if (-not [string]::IsNullOrWhiteSpace($v)) { $dockerOk = $true }
  } catch {}
  Add-Report "Docker rodando: $dockerOk"

  $ps = Get-ComposePsText
  Add-Report 'docker compose ps:'
  Add-Report $ps

  $composeUp = ($ps -match 'Up|running|Running')
  Add-Report ('Containers compose UP: ' + $composeUp)

  $healthOk = Run-LocalHealthcheck
  Add-Report "Healthcheck final: $(if ($healthOk) { 'OK' } else { 'FAIL' })"

  return ($dockerOk -and $composeUp -and $healthOk)
}

function Run-OneRepairCycle {
  Safe-Exec -Label 'Repair cycle - Reiniciar Docker backend' -Code { Restart-DockerBackend } | Out-Null
  Safe-Exec -Label 'Repair cycle - Subir compose novamente' -Code { Compose-Up } | Out-Null
}

function Reset-Project {
  if (Test-Path $AppDir) {
    Remove-Item -Path $AppDir -Recurse -Force
  }
  if (Test-Path $BundleZipPath) {
    Remove-Item -Path $BundleZipPath -Force
  }
  Add-Report 'Projeto local resetado com sucesso.'
}

function Run-Diagnose {
  $diag = Get-DiagnosticSnapshot
  Write-DiagnoseReport -Diag $diag

  $url = Resolve-BundleUrl
  if ([string]::IsNullOrWhiteSpace($url)) {
    Mark-Failure 'PROJECT_BUNDLE_URL ausente. Defina por parametro, config.json ou variavel de ambiente CREDTECH_BUNDLE_URL.'
  } else {
    Add-Report "Bundle URL detectado: $url"
  }

  if (-not $diag.virtualizationFirmwareEnabled) {
    Add-Report 'Virtualizacao da BIOS/UEFI esta desligada. Ative e rode novamente.'
  }
}

function Run-Install {
  Ensure-Admin

  $diag = Get-DiagnosticSnapshot
  Write-DiagnoseReport -Diag $diag
  if (-not $diag.virtualizationFirmwareEnabled) {
    Mark-Failure 'Instalacao pausada: virtualizacao BIOS/UEFI desligada.'
    return
  }

  $bundleUrl = Resolve-BundleUrl
  if ([string]::IsNullOrWhiteSpace($bundleUrl)) {
    Mark-Failure 'PROJECT_BUNDLE_URL nao definido. Rodando apenas diagnostico e encerrando.'
    return
  }

  Save-ConfigBundleUrl -Url $bundleUrl

  $rebootNeeded = $false
  try {
    $rebootNeeded = [bool](Enable-WindowsFeatures)
    Add-Report "Habilitar recursos Windows (WSL/VMP): OK (rebootNeeded=$rebootNeeded)"
    Write-Log "Habilitar recursos Windows (WSL/VMP): OK (rebootNeeded=$rebootNeeded)"
  } catch {
    Mark-Failure "Habilitar recursos Windows (WSL/VMP) - $($_.Exception.Message)"
  }

  Safe-Exec -Label 'Instalar/Atualizar WSL' -Code { Install-OrUpdate-WSL } | Out-Null
  Safe-Exec -Label 'Instalar Docker Desktop' -Code { Ensure-DockerInstalled } | Out-Null
  Safe-Exec -Label 'Iniciar Docker Desktop' -Code { Ensure-DockerRunning } | Out-Null
  Safe-Exec -Label 'Preparar pasta bundles' -Code { Prepare-BundleDestination } | Out-Null
  Safe-Exec -Label 'Baixar bundle do projeto' -Code { Download-Bundle -Url $bundleUrl } | Out-Null
  Safe-Exec -Label 'Extrair bundle em C:\ProgramData\CredTechInstaller\app' -Code { Extract-Bundle } | Out-Null
  Safe-Exec -Label 'Preparar arquivo .env e portas livres' -Code { Prepare-AppEnv } | Out-Null
  Safe-Exec -Label 'Subir containers com docker compose up -d' -Code { Compose-Up } | Out-Null

  $allOk = Test-Everything
  Add-Report "Test Everything (1a tentativa): $(if ($allOk) { 'OK' } else { 'FAIL' })"

  if (-not $allOk) {
    Add-Report 'Executando 1 ciclo automatico de reparo apos falha...'
    Run-OneRepairCycle
    $allOk = Test-Everything
    Add-Report "Test Everything (apos reparo): $(if ($allOk) { 'OK' } else { 'FAIL' })"
  }

  if (-not $allOk) {
    Mark-Failure 'Testes finais falharam apos 1 ciclo de reparo.'
  }

  $endpoints = Get-EndpointUrls
  Add-Report "Painel: $($endpoints.panel)"
  Add-Report "API: $($endpoints.api)"

  if ($rebootNeeded) {
    Add-Report 'Reboot necessario para finalizar recursos do Windows.'
    if (-not $NoReboot) {
      Register-Resume -ResumeMode 'Install' -BundleUrl $bundleUrl
      Add-Report 'Reiniciando automaticamente para continuar instalacao.'
      Write-Log 'Reiniciando sistema para continuar instalacao.'
      shutdown.exe /r /t 15 /c 'CredTech Installer precisa reiniciar para finalizar a instalacao.' | Out-Null
    } else {
      Add-Report 'NoReboot ativo: reboot nao executado.'
    }
  } else {
    Clear-ResumeState
  }
}

function Run-Repair {
  Ensure-Admin

  $diag = Get-DiagnosticSnapshot
  Write-DiagnoseReport -Diag $diag

  if (-not $diag.virtualizationFirmwareEnabled) {
    Mark-Failure 'Virtualizacao BIOS/UEFI desligada. Ative no setup da maquina e rode Repair novamente.'
    return
  }

  Safe-Exec -Label 'WSL shutdown' -Code { & wsl.exe --shutdown | Out-Null } | Out-Null
  Safe-Exec -Label 'WSL update' -Code { & wsl.exe --update | Out-Null } | Out-Null
  Safe-Exec -Label 'Reiniciar backend Docker' -Code { Restart-DockerBackend } | Out-Null

  if (-not (Test-Path $AppDir)) {
    Add-Report 'App nao instalado ainda.'
  } else {
    Safe-Exec -Label 'Executar repair.ps1 do projeto' -Code { Run-AppRepairScript } | Out-Null
    Safe-Exec -Label 'Subir compose novamente' -Code { Compose-Up } | Out-Null
    $allOk = Test-Everything
    Add-Report "Repair final Test Everything: $(if ($allOk) { 'OK' } else { 'FAIL' })"
    if (-not $allOk) {
      Mark-Failure 'Repair executado, mas ambiente ainda nao passou em todos os testes.'
    }
  }

  $endpoints = Get-EndpointUrls
  Add-Report "Painel: $($endpoints.panel)"
  Add-Report "API: $($endpoints.api)"
}

Ensure-Directories
Ensure-OutputFiles
Ensure-ConfigTemplate

$autoResolvedUrl = Resolve-BundleUrl
if (-not [string]::IsNullOrWhiteSpace($autoResolvedUrl)) {
  Save-ConfigBundleUrl -Url $autoResolvedUrl
}

Write-Log "Inicio do modo $Mode"

try {
  switch ($Mode) {
    'Diagnose' { Run-Diagnose }
    'Install' { Run-Install }
    'Repair' { Run-Repair }
    'ResetProject' { Ensure-Admin; Reset-Project }
  }

  if ($script:HadFailures) {
    throw 'Uma ou mais etapas falharam. Consulte o report.'
  }

  $script:ResultTag = 'SUCCESS'
  Flush-Report -Status 'SUCCESS'
  Write-Log "Fim do modo $Mode com sucesso"
  Write-Output 'Concluido. Verifique o install-report.txt para detalhes.'
  exit 0
} catch {
  $safeMessage = $_.Exception.Message
  Write-Log "Falha no modo ${Mode}: $safeMessage"
  Add-Report "Falha: $safeMessage"
  Add-Report 'Consulte o log para detalhes tecnicos.'
  $script:ResultTag = 'FAILED'
  Flush-Report -Status 'FAILED'
  Write-Output 'Nao foi possivel concluir. Verifique o install-report.txt.'
  exit 1
}
