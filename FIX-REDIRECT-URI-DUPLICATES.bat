@echo off
echo =======================================
echo iBridge Azure AD Redirect URI Fix Tool
echo =======================================
echo.
echo This tool will help fix the "Redirect URIs must have distinct values" error
echo by identifying and removing any duplicate URIs in your Azure AD application.
echo.
echo Press any key to continue...
pause > nul

powershell.exe -ExecutionPolicy Bypass -File "%~dp0check-redirect-uris-graph.ps1"

echo.
echo Script completed. Press any key to exit.
pause > nul
