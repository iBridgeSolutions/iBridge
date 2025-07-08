@echo off
echo.
echo =================================================================
echo          iBridge Microsoft 365 Data Consistency Guide
echo =================================================================
echo.
echo This guide provides instructions for maintaining consistent
echo data between Microsoft 365 and your intranet portal.
echo.
echo It includes:
echo  - Regular synchronization recommendations
echo  - Data verification procedures
echo  - Data formatting standards
echo  - Conflict resolution guidelines
echo  - Moving from development to production
echo.
echo Press any key to view the guide...
pause > nul

powershell -ExecutionPolicy Bypass -File "%~dp0\m365-consistency-guide.ps1"
