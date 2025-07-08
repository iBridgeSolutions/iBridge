@echo off
echo ===================================================
echo       FIXING AUTHENTICATION REFRESH LOOP ISSUE
echo ===================================================
echo.

powershell -ExecutionPolicy Bypass -File "fix-authentication-loop.ps1"

echo.
echo Press any key to exit...
pause > nul
