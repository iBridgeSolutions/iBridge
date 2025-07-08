@echo off
echo.
echo ====================================================================
echo          iBridge Portal - Switch to Real Microsoft 365 Data
echo ====================================================================
echo.
echo This script will configure the iBridge Portal to use real Microsoft 365 data
echo instead of simulated development data.
echo.
echo After running this script, you will need to:
echo 1. Configure the app in Microsoft Entra ID Admin Center
echo 2. Grant the necessary API permissions
echo 3. Start the intranet server
echo.
echo Press any key to continue or CTRL+C to cancel...
pause > nul

powershell -ExecutionPolicy Bypass -File "%~dp0\simple-switch-to-real-data.ps1"
