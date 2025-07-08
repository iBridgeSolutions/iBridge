@echo off
echo.
echo ====================================================================
echo          iBridge Microsoft 365 Integration - Real Data Setup
echo ====================================================================
echo.
echo This script will configure the iBridge Portal to use real Microsoft 365 data
echo instead of simulated development data. It will:
echo.
echo 1. Update settings to disable development mode
echo 2. Register the application in Microsoft Entra ID
echo 3. Set up proper API permissions
echo 4. Fetch real company and employee data from Microsoft 365
echo.
echo You will need to sign in with: lwandile.gasela@ibridge.co.za
echo.
echo Press any key to continue or CTRL+C to cancel...
pause > nul

powershell -ExecutionPolicy Bypass -File "%~dp0\switch-to-real-m365-data.ps1"
