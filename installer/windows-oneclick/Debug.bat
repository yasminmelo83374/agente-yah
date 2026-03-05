@echo off
setlocal
set "ROOT_DIR=C:\ProgramData\CredTechInstaller"
set "LOG_DIR=%ROOT_DIR%\logs"
set "REPORT=%ROOT_DIR%\install-report.txt"
set "BAT_LOG=%~dp0bat-output.log"

if not exist "%ROOT_DIR%" mkdir "%ROOT_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo ============================================== > "%BAT_LOG%"
echo [%date% %time%] Debug.bat iniciado >> "%BAT_LOG%"

echo.
echo Relatorio: %REPORT%
echo Pasta de logs: %LOG_DIR%
echo.

if exist "%REPORT%" (
  start "" notepad "%REPORT%"
) else (
  echo Relatorio ainda nao existe. >> "%BAT_LOG%"
)

if exist "%LOG_DIR%\launcher-install.log" (
  start "" notepad "%LOG_DIR%\launcher-install.log"
)

if exist "%LOG_DIR%\install.log" (
  start "" notepad "%LOG_DIR%\install.log"
)

echo [%date% %time%] Debug.bat finalizado >> "%BAT_LOG%"
echo.
echo Debug concluido.
pause
endlocal
