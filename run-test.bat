@echo off
REM =============================================================================
REM k6 Test Runner - Windows Batch Wrapper
REM Ejecuta el script de PowerShell con la política de ejecución adecuada
REM =============================================================================

powershell -ExecutionPolicy Bypass -File "%~dp0run-test.ps1"
