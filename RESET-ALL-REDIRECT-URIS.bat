@echo off
echo =========================================
echo iBridge Azure AD Redirect URI Reset Tool
echo =========================================
echo.
echo This tool will RESET ALL redirect URIs for your Azure AD application
echo and set ONLY the correct GitHub Pages redirect URI.
echo.
echo This is the "nuclear option" that should resolve any duplicate URI issues.
echo.
echo Press any key to continue...
pause > nul

powershell.exe -ExecutionPolicy Bypass -File "%~dp0reset-redirect-uris.ps1"

echo.
echo Script completed. Press any key to exit.
pause > nul
