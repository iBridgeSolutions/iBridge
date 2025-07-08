# Script to check the redirect URIs for iBridge Azure AD application
# This script helps verify the configured redirect URIs without making any changes

# App registration details
$clientId = "6686c610-81cf-4ed7-8241-a91a20f01b06"
$tenantId = "feeb9a78-4032-4b89-ae79-2100a5dc16a8"

# Define the expected redirect URI for GitHub Pages
$githubPagesRedirectUri = "https://ibridgesolutions.github.io/iBridge/intranet/login.html"
$incorrectRedirectUri = "https://ibridgesolutions.github.io/intranet/login.html"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "          iBridge Azure AD Redirect URI Verification Tool" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Azure AD PowerShell module is installed
$azureADModule = Get-Module -ListAvailable -Name AzureAD
if ($null -eq $azureADModule) {
    Write-Host "The AzureAD PowerShell module is not installed." -ForegroundColor Red
    Write-Host "Please install it by running:" -ForegroundColor Yellow
    Write-Host "Install-Module -Name AzureAD -Force -Scope CurrentUser" -ForegroundColor White
    exit 1
}

# Connect to Azure AD
try {
    Write-Host "Connecting to Azure AD..." -ForegroundColor Blue
    Connect-AzureAD -TenantId $tenantId
}
catch {
    Write-Host "Failed to connect to Azure AD. Please check your credentials and try again." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Get the application
try {
    Write-Host "Retrieving application with ID $clientId..." -ForegroundColor Blue
    $app = Get-AzureADApplication -Filter "AppId eq '$clientId'"
    
    if ($null -eq $app) {
        Write-Host "Application with ID $clientId not found." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Found application: $($app.DisplayName)" -ForegroundColor Green
}
catch {
    Write-Host "Failed to retrieve application. Please check your permissions and try again." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Check if the correct GitHub Pages redirect URI exists
$hasCorrectUri = $false
$hasIncorrectUri = $false

foreach ($uri in $app.ReplyUrls) {
    if ($uri -eq $githubPagesRedirectUri) {
        $hasCorrectUri = $true
    }
    if ($uri -eq $incorrectRedirectUri) {
        $hasIncorrectUri = $true
    }
}

Write-Host ""
Write-Host "Current redirect URIs for $($app.DisplayName):" -ForegroundColor Cyan
foreach ($uri in $app.ReplyUrls) {
    if ($uri -eq $githubPagesRedirectUri) {
        Write-Host "✓ $uri (CORRECT GitHub Pages URI)" -ForegroundColor Green
    }
    elseif ($uri -eq $incorrectRedirectUri) {
        Write-Host "✗ $uri (INCORRECT GitHub Pages URI - missing /iBridge/ path)" -ForegroundColor Red
    }
    else {
        Write-Host "• $uri" -ForegroundColor White
    }
}

Write-Host ""
if ($hasCorrectUri) {
    Write-Host "✓ The correct GitHub Pages redirect URI is configured." -ForegroundColor Green
} 
else {
    Write-Host "✗ The correct GitHub Pages redirect URI is NOT configured!" -ForegroundColor Red
    Write-Host "  Missing: $githubPagesRedirectUri" -ForegroundColor Red
    Write-Host "  Run update-azure-redirect-uri.ps1 to add it automatically" -ForegroundColor Yellow
}

if ($hasIncorrectUri) {
    Write-Host "⚠️ WARNING: An incorrect GitHub Pages redirect URI was found!" -ForegroundColor Yellow
    Write-Host "  Found: $incorrectRedirectUri" -ForegroundColor Yellow
    Write-Host "  This URI is missing the '/iBridge/' repository name in the path" -ForegroundColor Yellow
    Write-Host "  Consider removing this URI if the correct one is also configured" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "                         Next Steps" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
if (!$hasCorrectUri) {
    Write-Host "1. Run update-azure-redirect-uri.ps1 to add the correct redirect URI" -ForegroundColor Yellow
    Write-Host "2. Wait for the Azure AD changes to propagate (may take a few minutes)" -ForegroundColor Yellow
    Write-Host "3. Clear browser cache or use an incognito/private window" -ForegroundColor Yellow
    Write-Host "4. Try signing in again at: https://ibridgesolutions.github.io/iBridge/intranet/login.html" -ForegroundColor Yellow
} else {
    Write-Host "Your Azure AD application appears to be correctly configured." -ForegroundColor Green
    Write-Host "If you're still experiencing issues:" -ForegroundColor White
    Write-Host "• Clear browser cache or use an incognito/private window" -ForegroundColor White
    Write-Host "• Verify your user has access to the application" -ForegroundColor White
    Write-Host "• Check the browser console for any JavaScript errors" -ForegroundColor White
}
Write-Host "====================================================================" -ForegroundColor Cyan
