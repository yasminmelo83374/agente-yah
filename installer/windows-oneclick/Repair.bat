@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_PS=%SCRIPT_DIR%CredTech-Installer.ps1"
set "BUNDLE_URL=https://github.com/yasminmelo83374/agente-yah/releases/latest/download/credtech-bundle.zip"

net session >nul 2>&1
if %errorlevel% neq 0 (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

if not exist "C:\ProgramData\CredTechInstaller" mkdir "C:\ProgramData\CredTechInstaller"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$cfg=@{project_bundle_url='%BUNDLE_URL%'}; $cfg | ConvertTo-Json -Depth 3 | Set-Content -Path 'C:\ProgramData\CredTechInstaller\config.json' -Encoding UTF8"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PS%" -Mode Repair -ProjectBundleUrl "%BUNDLE_URL%"
if %errorlevel% neq 0 pause
endlocal
