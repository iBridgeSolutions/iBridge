@echo off
echo ================================================================
echo        iBRIDGE MICROSOFT 365 COMPLETE MIRROR PORTAL
echo ================================================================
echo.
echo This portal is exclusively for: lwandile.gasela@ibridge.co.za
echo Employee Code: IBDG054
echo.

echo Checking configuration...
IF NOT EXIST ".\intranet\data\access-control.json" (
    echo Missing access configuration. Setting up...
    call CONFIGURE-EXCLUSIVE-ACCESS.bat
    echo.
)

echo Starting the unified server...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\start-unified-server.ps1"

echo.
echo If the server window closed, there may be an error.
echo Please check if port 8090 is already in use.
pause
