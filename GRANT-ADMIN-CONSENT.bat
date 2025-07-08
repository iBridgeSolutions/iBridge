@echo off
echo =============================================
echo iBridge Azure AD Admin Consent Tool
echo =============================================
echo.
echo This tool will help resolve the "Need admin approval" error
echo by checking and granting admin consent for the iBridge Portal.
echo.
echo You will need admin rights in your Azure AD tenant.
echo.
echo Press any key to continue...
pause > nul

powershell.exe -ExecutionPolicy Bypass -File "%~dp0grant-admin-consent.ps1"

echo.
echo Script completed. Press any key to exit...
pause > nul
