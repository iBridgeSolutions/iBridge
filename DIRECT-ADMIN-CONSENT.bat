@echo off
echo =============================================
echo iBridge Azure AD Admin Consent Tool
echo =============================================
echo.
echo This tool will help resolve the "Need admin approval" error
echo by opening the direct admin consent URL in your browser.
echo.
echo You will need admin rights in your Azure AD tenant.
echo.
echo Press any key to open the admin consent URL...
pause > nul

start "" "https://login.microsoftonline.com/feeb9a78-4032-4b89-ae79-2100a5dc16a8/adminconsent?client_id=6686c610-81cf-4ed7-8241-a91a20f01b06"

echo.
echo The admin consent URL has been opened in your browser.
echo Please sign in with an administrator account when prompted.
echo.
echo After granting consent:
echo 1. Clear your browser cache and cookies
echo 2. Try signing in to the iBridge Portal again
echo.
echo Would you also like to open the detailed admin consent guide? (Y/N)
set /p openguide=

if /i "%openguide%"=="Y" (
    start "" "%~dp0intranet\admin-consent-guide.html"
)

echo.
echo Process completed. Press any key to exit...
pause > nul
