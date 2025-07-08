@echo off
echo Running Data Validation for iBridge Intranet...
powershell -ExecutionPolicy Bypass -File "%~dp0validate-intranet-data.ps1"
pause
