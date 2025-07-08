@echo off
echo =============================================
echo iBridge Azure AD Admin Consent Helper
echo =============================================
echo.
echo This tool will open the admin consent guide in your default browser
echo to help resolve the "Need admin approval" error.
echo.
echo Press any key to open the guide...
pause > nul

start "" "%~dp0intranet\admin-consent-guide.html"

echo.
echo Guide opened in your browser.
echo.
echo If you need the direct admin consent URL, here it is:
echo https://login.microsoftonline.com/feeb9a78-4032-4b89-ae79-2100a5dc16a8/adminconsent?client_id=6686c610-81cf-4ed7-8241-a91a20f01b06
echo.
echo Press any key to exit...
pause > nul
