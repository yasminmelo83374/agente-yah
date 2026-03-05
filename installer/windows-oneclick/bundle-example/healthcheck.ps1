$ErrorActionPreference = 'SilentlyContinue'

$apiPort = 8080
$panelPort = 3000
$envPath = Join-Path $PSScriptRoot '.env'

if (Test-Path $envPath) {
  $lines = Get-Content -Path $envPath
  foreach ($line in $lines) {
    if ($line -match '^API_PORT=(\d+)$') { $apiPort = [int]$Matches[1] }
    if ($line -match '^PANEL_PORT=(\d+)$') { $panelPort = [int]$Matches[1] }
  }
}

$ok1 = $false
$ok2 = $false
try {
  $r1 = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:$panelPort" -TimeoutSec 8
  $ok1 = $r1.StatusCode -ge 200 -and $r1.StatusCode -lt 500
} catch {}

try {
  $r2 = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:$apiPort" -TimeoutSec 8
  $ok2 = $r2.StatusCode -eq 200
} catch {}

if ($ok1 -and $ok2) {
  Write-Output 'OK'
  exit 0
}

Write-Output 'FAIL'
exit 1
