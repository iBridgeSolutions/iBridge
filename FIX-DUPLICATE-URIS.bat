@echo off
echo =============================================
echo         Azure AD Duplicate URIs Fix Helper
echo =============================================
echo.
echo ERROR: "Failed to update iBridge Portal application. Error detail: Redirect URIs must have distinct values."
echo.
echo This error occurs when you try to add a URI that already exists or is too similar to an existing one.
echo.
echo SOLUTION:
echo 1. Sign in to Azure Portal
echo 2. Go to Azure Active Directory ^> App registrations
echo 3. Find your iBridge application (ID: 6686c610-81cf-4ed7-8241-a91a20f01b06)
echo 4. Click Authentication in the left menu
echo 5. Check for these URIs:
echo    - https://ibridgesolutions.github.io/iBridge/intranet/login.html
echo    - https://ibridgesolutions.github.io/intranet/login.html (without /iBridge/)
echo.
echo 6. If both exist, REMOVE the incorrect one WITHOUT /iBridge/:
echo    - KEEP: https://ibridgesolutions.github.io/iBridge/intranet/login.html (CORRECT)
echo    - DELETE: https://ibridgesolutions.github.io/intranet/login.html (INCORRECT)
echo.
echo 7. Click Save after removing the duplicate
echo.
echo Press any key to copy the CORRECT URI to clipboard...
pause > nul
powershell -command "Set-Clipboard -Value 'https://ibridgesolutions.github.io/iBridge/intranet/login.html'"
echo.
echo CORRECT URI copied to clipboard!
echo.
pause
