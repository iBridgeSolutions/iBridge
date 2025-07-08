@echo off
echo ===== iBridge Portal Access Verification =====
echo.
echo This script will verify that the portal is correctly configured
echo for exclusive access by lwandile.gasela@ibridge.co.za (IBDG054)
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0simple-verify-access.ps1"
pause
