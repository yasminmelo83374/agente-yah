@echo off
setlocal
set SCRIPT_DIR=%~dp0
if not exist "C:\ProgramData\CredTechInstaller" mkdir "C:\ProgramData\CredTechInstaller"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$cfg=@{project_bundle_url='https://github.com/yasminmelo83374/agente-yah/releases/latest/download/credtech-bundle.zip';instructions=@('URL do bundle usado pelo instalador.','Troque somente se publicar novo asset.')} ; $cfg | ConvertTo-Json -Depth 4 | Set-Content -Path 'C:\ProgramData\CredTechInstaller\config.json' -Encoding UTF8"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process PowerShell -Verb RunAs -Wait -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','""%SCRIPT_DIR%CredTech-Installer.ps1""','-Mode','Repair','-ProjectBundleUrl','https://github.com/yasminmelo83374/agente-yah/releases/latest/download/credtech-bundle.zip'"
endlocal
