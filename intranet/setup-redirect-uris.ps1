# Azure AD Redirect URI Setup Guide

$clientId = "2f833c55-f976-4d6c-ad96-fa357119f0ee"
$appName = "iBridge Portal"
$tenantId = "feeb9a78-4032-4b89-ae79-2100a5dc16a8"

Write-Host "=========================" -ForegroundColor Cyan
Write-Host "Azure AD Redirect URI Setup Guide" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script provides instructions to properly configure redirect URIs for your iBridge Portal app." -ForegroundColor Yellow
Write-Host ""
Write-Host "Application Details:" -ForegroundColor Green
Write-Host "- Name: $appName"
Write-Host "- Client ID: $clientId"
Write-Host "- Tenant ID: $tenantId"
Write-Host ""

# Get current hostname and port
$hostname = "localhost"
$port = 8090
try {
    $hostname = [System.Net.Dns]::GetHostName()
} catch {
    Write-Host "Could not determine hostname, using 'localhost'" -ForegroundColor Yellow
}

# List required redirect URIs - ensure they are unique
$redirectUris = @(
    # This seems to be what the application is sending
    "http://localhost:8090/login.html"
    
    # These are the correctly structured URIs
    "http://localhost:8090/intranet/login.html"
    "http://localhost:8090/intranet/"
    "http://localhost:8090/intranet/index.html"
)

Write-Host "Redirect URIs to add to Azure AD:" -ForegroundColor Green
foreach ($uri in $redirectUris) {
    Write-Host "- $uri"
}

Write-Host ""
Write-Host "IMPORTANT NOTES:" -ForegroundColor Red
Write-Host "- Each URI must be unique - the error 'Redirect URIs must have distinct values' means you have duplicates" -ForegroundColor Red
Write-Host "- Check for trailing slashes - 'http://localhost:8090/intranet/' and 'http://localhost:8090/intranet' are different" -ForegroundColor Red
Write-Host "- Check for extra spaces at the end of URIs" -ForegroundColor Red
Write-Host "- Check for case sensitivity - all lowercase is recommended" -ForegroundColor Red
Write-Host ""

Write-Host "Steps to configure Azure AD:" -ForegroundColor Green
Write-Host "1. Go to https://portal.azure.com" -ForegroundColor Yellow
Write-Host "2. Navigate to Azure Active Directory > App registrations" -ForegroundColor Yellow
Write-Host "3. Find and select '$appName'" -ForegroundColor Yellow
Write-Host "4. In the left menu, click 'Authentication'" -ForegroundColor Yellow
Write-Host "5. Under 'Platform configurations', add/modify the Web platform" -ForegroundColor Yellow
Write-Host "6. FIRST REMOVE ANY EXISTING URIs by clicking the trashcan icon" -ForegroundColor Magenta
Write-Host "7. THEN add each of the redirect URIs listed above" -ForegroundColor Yellow
Write-Host "8. Make sure 'Access tokens' and 'ID tokens' are checked" -ForegroundColor Yellow
Write-Host "9. Click 'Save'" -ForegroundColor Yellow
Write-Host ""

Write-Host "Would you like to open the Azure portal directly to the App Registration page? (Y/N)" -ForegroundColor Cyan
$response = Read-Host

if ($response.ToUpper() -eq "Y") {
    $url = "https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Authentication/appId/$clientId/objectId/$clientId/isMSAApp/"
    Write-Host "Opening $url in your default browser..." -ForegroundColor Green
    Start-Process $url
} else {
    Write-Host "You can manually navigate to the Azure portal to update your redirect URIs." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "After updating the configuration in Azure AD, wait a few minutes for changes to propagate before testing authentication again." -ForegroundColor Green
