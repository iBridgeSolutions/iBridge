@echo off
echo =====================================================
echo   iBridge Microsoft 365 Data Fetcher (DEV MODE)
echo =====================================================
echo.
echo This script will fetch company and employee data from
echo Microsoft 365 and configure the intranet for dev mode
echo with lwandile.gasela@ibridge.co.za as the admin user.
echo.
echo Press any key to continue...
pause > nul

powershell -ExecutionPolicy Bypass -File "%~dp0fetch-company-data.ps1"

echo.
echo =====================================================
echo   Data fetch complete! Press any key to exit.
echo =====================================================
pause > nul
