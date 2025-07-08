@echo off
echo Enriching Employee Data for iBridge Intranet...
powershell -ExecutionPolicy Bypass -File "%~dp0enrich-employee-data.ps1"
pause
