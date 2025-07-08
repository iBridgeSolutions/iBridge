@echo off
echo ================================================
echo  iBridge Two-Factor Authentication Setup
echo ================================================
echo.
echo This utility will configure two-factor authentication for users.
echo A backup will be created before any changes are made.
echo.
echo IMPORTANT: This is an administrative function.
echo.
pause

powershell -ExecutionPolicy Bypass -File setup-two-factor-auth.ps1

echo.
pause
