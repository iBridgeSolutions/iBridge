@echo off
echo ================================================
echo  iBridge Password Migration Utility
echo ================================================
echo.
echo This utility will migrate plaintext passwords to secure hashed passwords.
echo A backup will be created before any changes are made.
echo.
echo IMPORTANT: Please ensure all users are logged out before proceeding.
echo.
pause

powershell -ExecutionPolicy Bypass -File migrate-passwords.ps1

echo.
pause
