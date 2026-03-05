@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_PS=%SCRIPT_DIR%CredTech-Installer.ps1"
set "BUNDLE_URL=https://github.com/yasminmelo83374/agente-yah/releases/latest/download/credtech-bundle.zip"
set "ROOT_DIR=C:\ProgramData\CredTechInstaller"
set "LOG_DIR=%ROOT_DIR%\logs"
set "LAUNCHER_LOG=%LOG_DIR%\launcher-diagnose.log"

net session >nul 2>&1
if %errorlevel% neq 0 (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

if not exist "%ROOT_DIR%" mkdir "%ROOT_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
echo [%date% %time%] Iniciando Diagnose.bat > "%LAUNCHER_LOG%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$cfg=@{project_bundle_url='%BUNDLE_URL%'}; $cfg | ConvertTo-Json -Depth 3 | Set-Content -Path 'C:\ProgramData\CredTechInstaller\config.json' -Encoding UTF8"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PS%" -Mode Diagnose -ProjectBundleUrl "%BUNDLE_URL%" >> "%LAUNCHER_LOG%" 2>&1
if %errorlevel% neq 0 (
  echo [%date% %time%] Falha no Diagnose.bat. >> "%LAUNCHER_LOG%"
  start "" notepad "%LAUNCHER_LOG%"
  pause
)
endlocal
