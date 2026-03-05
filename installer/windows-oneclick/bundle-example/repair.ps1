$ErrorActionPreference = 'SilentlyContinue'
& wsl.exe --shutdown | Out-Null
& wsl.exe --update | Out-Null
& docker compose down | Out-Null
& docker compose up -d --force-recreate | Out-Null
Write-Output 'Repair OK'
