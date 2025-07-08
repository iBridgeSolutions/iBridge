@echo off
echo.
echo =================================================================
echo          iBridge Microsoft 365 Integration Tool
echo =================================================================
echo.
echo This batch file will sync your Microsoft 365 data with the intranet
echo portal. The data will be used for the company profile, employee 
echo directory, and other intranet features.
echo.
echo In development mode, sample data will be generated that simulates
echo Microsoft 365 integration.
echo.
echo Press any key to continue or CTRL+C to cancel...
pause > nul

powershell -ExecutionPolicy Bypass -File "%~dp0\sync-m365-dev-data.ps1"
