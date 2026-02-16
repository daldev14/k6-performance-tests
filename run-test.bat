@echo off
REM =============================================================================
REM k6 Test Runner - Windows Batch Wrapper
REM Ejecuta el script de PowerShell con la política de ejecución adecuada
REM =============================================================================

REM Cambia al directorio del script para que las rutas relativas funcionen
pushd "%~dp0"

REM Ejecuta PowerShell leyendo el archivo como UTF-8 e invocando su contenido.
REM Evita problemas de codificación y garantiza que las funciones del script
REM se carguen correctamente en la sesión.
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; Get-Content -Raw -Encoding UTF8 -Path '%~dp0run-test.ps1' | Invoke-Expression"

REM Captura y propaga el código de salida
set "exitCode=%ERRORLEVEL%"

popd
exit /B %exitCode%
