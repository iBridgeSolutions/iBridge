@echo off
echo ===== Microsoft 365 Complete Data Extraction =====
echo This script will extract all Microsoft 365, Azure AD, and Entra ID data
echo for user: lwandile.gasela@ibridge.co.za (IBDG054)
echo.
echo Please ensure you have admin access to Microsoft 365
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0extract-m365-admin-data.ps1"
pause
