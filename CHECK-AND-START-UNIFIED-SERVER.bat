@echo off
echo =====================================================
echo   iBridge Link Checker - Single Port Configuration
echo =====================================================
echo.
echo This script will verify that both the main website
echo and intranet site can be accessed from port 8090.
echo.

echo Checking configuration...
echo.

REM Check if main website has intranet link
echo 1. Checking if main website has a link to intranet...
findstr /C:"Staff Portal" "%~dp0index.html" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo    [OK] Main website has link to intranet
) else (
    echo    [WARNING] Main website doesn't have link to intranet
)

REM Check if intranet has main website link
echo 2. Checking if intranet has a link to main website...
findstr /C:"Main Site" "%~dp0intranet\partials\header.html" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo    [OK] Intranet has link to main website
) else (
    echo    [WARNING] Intranet doesn't have link to main website
)

REM Check if unified server script exists
echo 3. Checking if unified server script exists...
if exist "%~dp0start-unified-server.ps1" (
    echo    [OK] Unified server script exists
) else (
    echo    [WARNING] Unified server script not found
)

echo.
echo =====================================================
echo   Starting unified server...
echo =====================================================
echo.
echo The unified server will now start and serve both
echo the main website and intranet from port 8090:
echo.
echo - Main Website: http://localhost:8090/
echo - Intranet: http://localhost:8090/intranet/
echo.
echo Press any key to continue...
pause > nul

powershell -ExecutionPolicy Bypass -File "%~dp0start-unified-server.ps1"
