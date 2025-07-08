@echo off
echo ================================================
echo iBridge Intranet - Microsoft 365 Data Importer
echo ================================================
echo.
echo This tool will help you import company and employee 
echo information from Microsoft 365 into your intranet.
echo.
echo STEPS:
echo 1. You'll be prompted to sign in with your Microsoft 365 admin account
echo 2. The tool will fetch organization and employee data
echo 3. Data will be saved to the intranet/data directory
echo 4. You can then access this data in the intranet portal
echo.
echo IMPORTANT: You must have admin rights in your Microsoft 365 tenant.
echo.
echo Press any key to continue...
pause > nul

powershell.exe -ExecutionPolicy Bypass -File "%~dp0fetch-company-data.ps1"

echo.
echo -----------------------------------------------------
echo Data import completed. What to do next:
echo -----------------------------------------------------
echo 1. Start your intranet server: .\serve-intranet.ps1
echo 2. Go to: http://localhost:8090/intranet/
echo 3. Sign in with the dev mode login
echo 4. Visit the Company and Directory pages to see your data
echo -----------------------------------------------------
echo.
echo Press any key to exit...
pause > nul
