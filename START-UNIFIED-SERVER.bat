@echo off
echo =====================================================
echo   iBridge Unified Server (Single Port Solution)
echo =====================================================
echo.
echo This script will start a unified server on port 8090
echo that serves both the main website and the intranet.
echo.
echo  * Main Website: http://localhost:8090/
echo  * Intranet: http://localhost:8090/intranet/
echo.
echo Press any key to start the server...
pause > nul

powershell -ExecutionPolicy Bypass -File "%~dp0start-unified-server.ps1"
