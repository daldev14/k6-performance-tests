@echo off
REM =============================================================================
REM k6 Test Runner - Windows Batch Wrapper
REM Ejecuta el script de PowerShell con la política de ejecución adecuada
REM =============================================================================

REM Cambia al directorio del script para que las rutas relativas funcionen
pushd "%~dp0"

REM Ejecuta PowerShell sin perfil, con política Bypass. Pasa cualquier argumento (%*) al script.
powershell -NoProfile -ExecutionPolicy Bypass -File "run-test.ps1" %*

REM Captura y propaga el código de salida
set "exitCode=%ERRORLEVEL%"

popd
exit /B %exitCode%
