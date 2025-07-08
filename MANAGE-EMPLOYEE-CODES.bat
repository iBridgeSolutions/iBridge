@echo off
echo ================================================================
echo             EMPLOYEE CODE MANAGEMENT SYSTEM
echo ================================================================
echo.
echo This script will help you manage employee codes in the format:
echo IBD[Last Name Initials][Unique ID]
echo.
echo Examples: IBDG054, IBDSM001, IBDJ100
echo.
echo Press any key to continue...
pause > nul

powershell -NoProfile -ExecutionPolicy Bypass -File ".\manage-employee-codes.ps1"

echo.
echo Employee code management completed.
echo.
