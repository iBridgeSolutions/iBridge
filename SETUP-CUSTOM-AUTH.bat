@echo off
echo ================================================================
echo            CUSTOM AUTHENTICATION SYSTEM SETUP
echo ================================================================
echo.
echo This script will update the portal to use custom authentication
echo with the format IBD[Last Name Initials][Unique ID] (e.g., IBDG054)
echo instead of Microsoft 365 authentication.
echo.
echo WARNING: This will modify the portal configuration.
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause > nul

powershell -NoProfile -ExecutionPolicy Bypass -File ".\setup-custom-auth.ps1"

echo.
echo If no errors were reported, the portal now uses custom authentication.
echo.
echo To manage employee codes, run: MANAGE-EMPLOYEE-CODES.bat
echo.
echo Press any key to exit...
pause > nul
