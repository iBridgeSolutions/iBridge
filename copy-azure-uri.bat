@echo off
echo =============================================
echo         Azure AD Redirect URI Fix Helper
echo =============================================
echo.
echo Please add this URI to your Azure AD application:
echo.
echo https://ibridgesolutions.github.io/iBridge/intranet/login.html
echo.
echo Steps:
echo 1. Go to https://portal.azure.com
echo 2. Navigate to Azure Active Directory ^> App registrations
echo 3. Find your app with ID: 6686c610-81cf-4ed7-8241-a91a20f01b06
echo 4. Click Authentication in the left menu
echo 5. Add the URI under Web platform Redirect URIs
echo 6. Click Save
echo.
echo Press any key to copy the URI to clipboard...
pause > nul
powershell -command "Set-Clipboard -Value 'https://ibridgesolutions.github.io/iBridge/intranet/login.html'"
echo URI copied to clipboard!
echo.
pause
