# Fix Duplicate Redirect URIs Issue

Write-Host "=============================" -ForegroundColor Cyan
Write-Host "Fix for Duplicate Redirect URIs" -ForegroundColor Cyan 
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

Write-Host "From your screenshot, we saw this error:" -ForegroundColor Yellow
Write-Host "'Failed to update iBridge Portal application. Error detail: Redirect URIs must have distinct values.'" -ForegroundColor Red
Write-Host ""

Write-Host "This script will help you fix the issue." -ForegroundColor Green
Write-Host ""

Write-Host "SOLUTIONS:" -ForegroundColor Magenta
Write-Host ""
Write-Host "OPTION 1: Update Azure Portal Configuration" -ForegroundColor Cyan
Write-Host "---------------------------------------" -ForegroundColor Cyan
Write-Host "1. Go to Azure Portal (https://portal.azure.com)" -ForegroundColor Yellow
Write-Host "2. Navigate to Azure AD > App registrations > iBridge Portal" -ForegroundColor Yellow
Write-Host "3. Click on Authentication in the left menu" -ForegroundColor Yellow
Write-Host "4. Under Web platform configuration:" -ForegroundColor Yellow
Write-Host "   a. REMOVE ALL existing redirect URIs (click the trashcan icon for each)" -ForegroundColor Red
Write-Host "   b. Add ONLY these URIs:" -ForegroundColor Yellow
Write-Host "      - http://localhost:8090/intranet/login.html" -ForegroundColor Green
Write-Host "      - http://localhost:8090/intranet/" -ForegroundColor Green
Write-Host "      - http://localhost:8090/intranet/index.html" -ForegroundColor Green
Write-Host "   c. Make sure both 'Access tokens' and 'ID tokens' are checked" -ForegroundColor Yellow
Write-Host "   d. Click Save" -ForegroundColor Yellow
Write-Host ""

Write-Host "OPTION 2: Update Application Code" -ForegroundColor Cyan
Write-Host "-------------------------" -ForegroundColor Cyan
Write-Host "We've already updated your login.html to use:" -ForegroundColor Yellow
Write-Host "redirectUri = window.location.origin + '/intranet/login.html'" -ForegroundColor Green
Write-Host ""
Write-Host "This matches one of the URIs that's already registered in your Azure Portal." -ForegroundColor Yellow
Write-Host ""

Write-Host "OPTION 3: Test Development Login" -ForegroundColor Cyan
Write-Host "-----------------------" -ForegroundColor Cyan
Write-Host "While you're fixing the Azure AD integration, you can use the Development Login:" -ForegroundColor Yellow
Write-Host "1. Open http://localhost:8090/intranet/login.html" -ForegroundColor Yellow
Write-Host "2. Click 'Development Mode Login' at the bottom" -ForegroundColor Yellow
Write-Host "3. Enter your details (email should be lwandile.gasela@ibridge.co.za)" -ForegroundColor Yellow
Write-Host "4. Click 'Login (Dev Mode)'" -ForegroundColor Yellow
Write-Host ""

Write-Host "Would you like to open the Azure portal Authentication page directly? (Y/N)" -ForegroundColor Cyan
$response = Read-Host

if ($response.ToUpper() -eq "Y") {
    $clientId = "2f833c55-f976-4d6c-ad96-fa357119f0ee"
    $url = "https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Authentication/appId/$clientId/objectId/$clientId/isMSAApp/"
    Write-Host "Opening $url in your default browser..." -ForegroundColor Green
    Start-Process $url
} else {
    Write-Host "You can manually navigate to the Azure portal to update your redirect URIs." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Would you like to open the intranet login page to test after making changes? (Y/N)" -ForegroundColor Cyan
$response = Read-Host

if ($response.ToUpper() -eq "Y") {
    $url = "http://localhost:8090/intranet/login.html"
    Write-Host "Opening $url in your default browser..." -ForegroundColor Green
    Start-Process $url
}

Write-Host ""
Write-Host "Remember: After making changes in the Azure portal, wait a few minutes for changes to propagate before testing." -ForegroundColor Yellow
