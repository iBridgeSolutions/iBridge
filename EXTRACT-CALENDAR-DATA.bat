@echo off
echo ========================================
echo       EXTRACT CALENDAR DATA
echo ========================================
echo This script will extract calendar data from Microsoft 365 and save it locally
echo.

set /p real_data="Do you want to use real data from Microsoft 365? (Y/N): "
set use_real_data=false
if /i "%real_data%"=="Y" set use_real_data=true

set /p dev_mode="Run in development mode? (Y/N): "
set use_dev_mode=false
if /i "%dev_mode%"=="Y" set use_dev_mode=true

echo.
if "%use_real_data%"=="true" (
    echo Using real data from Microsoft 365...
) else (
    echo Using sample calendar data...
)

if "%use_dev_mode%"=="true" (
    echo Running in development mode...
)

echo.
echo Starting extraction...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0extract-calendar-data.ps1" -UseRealData:$%use_real_data% -UseDevMode:$%use_dev_mode%

echo.
echo Press any key to exit...
pause > nul
