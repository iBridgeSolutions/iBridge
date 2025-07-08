@echo off
echo Running script to switch to real Microsoft 365 data...
powershell -ExecutionPolicy Bypass -File "%~dp0switch-to-real-m365-data.ps1"
pause
