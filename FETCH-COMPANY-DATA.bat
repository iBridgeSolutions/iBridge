@echo off
echo =============================================
echo iBridge Company Data Fetcher
echo =============================================
echo.
echo This tool will gather company and employee data
echo from your Microsoft 365 tenant for use in the intranet.
echo.
echo You will need admin rights in your Microsoft 365 tenant.
echo.
echo Press any key to continue...
pause > nul

powershell.exe -ExecutionPolicy Bypass -File "%~dp0fetch-company-data.ps1"

echo.
echo Script completed. Press any key to exit...
pause > nul
