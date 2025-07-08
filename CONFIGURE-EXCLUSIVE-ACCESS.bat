@echo off
echo ===== iBridge Portal M365 Configuration =====
echo This will configure the portal for exclusive access by:
echo User: lwandile.gasela@ibridge.co.za
echo Employee Code: IBDG054
echo.

echo Step 1: Creating exclusive access settings
powershell -Command "$accessControl = @{ restrictedAccess = $true; allowedUsers = @('lwandile.gasela@ibridge.co.za'); allowedEmployeeCodes = @('IBDG054'); lastUpdated = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'); accessPolicy = 'exclusive' } | ConvertTo-Json -Depth 4 | Out-File -FilePath '.\intranet\data\access-control.json' -Encoding UTF8"

echo Step 2: Updating settings.json to disable devMode and ensure M365 data is used
powershell -Command "(Get-Content -Path '.\intranet\data\settings.json') -replace '\"devMode\": true', '\"devMode\": false' | Set-Content -Path '.\intranet\data\settings.json'"

echo Step 3: Creating employee code mapping file
powershell -Command "$employeeCodes = @{ mappings = @( @{ userPrincipalName = 'lwandile.gasela@ibridge.co.za'; employeeCode = 'IBDG054' } ) } | ConvertTo-Json -Depth 4 | Out-File -FilePath '.\intranet\data\employee-codes.json' -Encoding UTF8"

echo Step 4: Setting up to use extracted M365 data
echo.
echo The next step will extract comprehensive Microsoft 365 data using your admin account
echo It will mirror Microsoft 365, Azure AD, and Microsoft Admin Center functionality
echo.
echo Please choose how to proceed:
echo.
echo 1. Extract M365 data now (requires Microsoft 365 admin access)
echo 2. Skip data extraction (configure for exclusive access only)
echo.
set /p choice="Enter choice (1 or 2): "

if "%choice%"=="1" (
    echo.
    echo Running Microsoft 365 data extraction script...
    call EXTRACT-M365-ADMIN-DATA.bat
) else (
    echo.
    echo Skipping data extraction.
)

echo.
echo Configuration complete!
echo.
echo The iBridge Portal is now configured for exclusive access by:
echo - Email: lwandile.gasela@ibridge.co.za
echo - Employee Code: IBDG054
echo.
echo To start the intranet server, run:
echo START-UNIFIED-SERVER.bat or START-INTRANET.bat
echo.
echo To access the portal:
echo 1. Navigate to http://localhost:8090/intranet/
echo 2. Login with employee code IBDG054
echo.
pause
