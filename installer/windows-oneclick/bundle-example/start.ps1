$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
  docker compose up -d
} finally {
  Pop-Location
}
