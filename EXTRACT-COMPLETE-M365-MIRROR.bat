@echo off
echo ================================================================
echo       MICROSOFT 365 COMPLETE MIRROR - DATA EXTRACTION
echo ================================================================
echo.
echo This script will extract ALL data from Microsoft 365/Azure/Entra ID
echo to create a comprehensive mirror for lwandile.gasela@ibridge.co.za
echo.
echo Requirements:
echo - Microsoft 365 admin credentials for lwandile.gasela@ibridge.co.za
echo - PowerShell 5.1 or higher with ExecutionPolicy allowing script execution
echo.
echo Press any key to begin the extraction...
pause >nul

powershell -NoProfile -ExecutionPolicy Bypass -File ".\extract-m365-complete-mirror.ps1"

echo.
echo ================================================================
echo Extraction complete! Start the server to access the mirror portal.
echo Run CHECK-AND-START-UNIFIED-SERVER.bat to launch the portal.
echo.
echo Access at: http://localhost:8090/intranet/
echo Login with: IBDG054 or lwandile.gasela@ibridge.co.za
echo ================================================================

pause
