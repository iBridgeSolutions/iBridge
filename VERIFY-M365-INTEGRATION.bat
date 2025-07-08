@echo off
echo.
echo =================================================================
echo          iBridge Microsoft 365 Integration Verification
echo =================================================================
echo.
echo This batch file will verify that Microsoft 365 integration
echo is correctly set up for your intranet portal.
echo.
echo Press any key to continue...
pause > nul

powershell -ExecutionPolicy Bypass -File "%~dp0\verify-m365-integration.ps1"

pause
