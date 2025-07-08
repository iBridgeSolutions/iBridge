@echo off
echo Starting iBridge Intranet Server on port 8090...
echo ===============================================
echo Access the intranet at: http://localhost:8090/
echo Direct links:
echo  - Dashboard: http://localhost:8090/index.html
echo  - Company Profile: http://localhost:8090/company.html
echo  - Directory: http://localhost:8090/directory.html
echo Press Ctrl+C to stop the server
echo ===============================================

:: Change to the intranet directory
cd "%~dp0intranet"
echo Server root directory: %cd%

:: Start the server
start "" http://localhost:8090/index.html
http-server -p 8090 -c-1 --cors
