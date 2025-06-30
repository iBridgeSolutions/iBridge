# Update iBridge Portal App to SPA Configuration Script
# This script helps convert the app registration from Web to SPA type

# Application details
$appName = "iBridge Portal"
$redirectUris = @(
    "http://localhost:8090/intranet/login.html",
    "http://localhost:8090/intranet/",
    "http://localhost:8090/intranet/index.html",
    "http://localhost:8090/login.html"
)
$clientId = "6686c610-81cf-4ed7-8241-a91a20f01b06"

Write-Host "===== iBridge Portal - Update to SPA Type =====" -ForegroundColor Cyan
Write-Host "This script will update your app registration to use Single-Page Application (SPA) type" -ForegroundColor Cyan
Write-Host ""

# Function to handle errors
function Show-ErrorMessage {
    param (
        [string]$ErrorMessage
    )
    Write-Host "`n❌ ERROR: $ErrorMessage" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Check if Azure AD module is installed, if not, install it
Write-Host "Step 1: Checking required PowerShell modules..." -ForegroundColor Green
if (-not (Get-Module -ListAvailable -Name AzureAD)) {
    try {
        Write-Host "  Installing AzureAD module..." -ForegroundColor Yellow
        Install-Module AzureAD -Force -Scope CurrentUser
        Write-Host "  ✅ AzureAD module installed successfully" -ForegroundColor Green
    } catch {
        Show-ErrorMessage "Failed to install AzureAD module. Please run PowerShell as Administrator and try again."
    }
}

# Connect to Azure AD
Write-Host "`nStep 2: Connecting to Microsoft 365..." -ForegroundColor Green
Write-Host "  A login window will open. Sign in with your Microsoft 365 admin account." -ForegroundColor Yellow
try {
    Import-Module AzureAD
    Connect-AzureAD | Out-Null
    $currentUser = Get-AzureADCurrentSessionInfo
    Write-Host "  ✅ Successfully connected as $($currentUser.Account)" -ForegroundColor Green
    $tenantId = $currentUser.TenantId.ToString()
    Write-Host "  ✅ Tenant ID: $tenantId" -ForegroundColor Green
} catch {
    Show-ErrorMessage "Failed to connect to Microsoft 365. Please make sure you have admin permissions."
}

# Find the application
Write-Host "`nStep 3: Finding application..." -ForegroundColor Green
try {
    if ([string]::IsNullOrEmpty($clientId)) {
        $app = Get-AzureADApplication -Filter "DisplayName eq '$appName'"
        if ($app) {
            $clientId = $app.AppId
            Write-Host "  ✅ Found app by name: $appName with ID: $clientId" -ForegroundColor Green
        } else {
            Show-ErrorMessage "Could not find app with name: $appName. Please specify the client ID."
        }
    } else {
        $app = Get-AzureADApplication -Filter "AppId eq '$clientId'"
        if ($app) {
            Write-Host "  ✅ Found app with client ID: $clientId" -ForegroundColor Green
        } else {
            Show-ErrorMessage "Could not find app with client ID: $clientId"
        }
    }
} catch {
    Show-ErrorMessage "Error finding application: $_"
}

# Update the app to support SPA
Write-Host "`nStep 4: Updating application to support SPA..." -ForegroundColor Green

try {
    # Get current redirect URIs
    $currentApp = Get-AzureADApplication -ObjectId $app.ObjectId
    $currentReplyUrls = $currentApp.ReplyUrls
    
    # Make sure all our redirect URIs are included
    foreach ($uri in $redirectUris) {
        if (-not $currentReplyUrls.Contains($uri)) {
            $currentReplyUrls.Add($uri)
        }
    }
    
    # Update the app configuration
    Write-Host "  Updating with SPA type and redirect URIs..." -ForegroundColor Yellow

    # Create the SPA configuration
    $spaConfig = New-Object -TypeName Microsoft.Open.AzureAD.Model.SpaApplication
    $spaConfig.RedirectUris = $redirectUris
    
    # Update the application
    Set-AzureADApplication -ObjectId $app.ObjectId `
                          -ReplyUrls $currentReplyUrls `
                          -Spa $spaConfig `
                          -Oauth2AllowImplicitFlow $true `
                          -Oauth2AllowIdTokenImplicitFlow $true
                          
    Write-Host "  ✅ Application successfully updated to support SPA type" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Error updating application: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Manual update is required. Please follow these steps:" -ForegroundColor Yellow
    Write-Host "  1. Go to https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade" -ForegroundColor White
    Write-Host "  2. Find and select your app: $appName ($clientId)" -ForegroundColor White
    Write-Host "  3. Go to 'Authentication' in the left menu" -ForegroundColor White
    Write-Host "  4. Click '+ Add a platform'" -ForegroundColor White
    Write-Host "  5. Select 'Single-page application'" -ForegroundColor White
    Write-Host "  6. Add the redirect URIs for your SPA" -ForegroundColor White
    Write-Host "  7. Click 'Configure'" -ForegroundColor White
    
    Write-Host "`nPress any key to open the portal in your browser..." -ForegroundColor Green
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    Start-Process "https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Authentication/appId/$clientId"
    exit 1
}

# Open consent URL
Write-Host "`nStep 5: Opening admin consent URL..." -ForegroundColor Green
$adminConsentUrl = "https://login.microsoftonline.com/$tenantId/adminconsent?client_id=$clientId"
Write-Host "  Opening admin consent URL in your default browser..." -ForegroundColor Yellow
Start-Process $adminConsentUrl
Write-Host "  ⚠️ Complete the admin consent in your browser when prompted" -ForegroundColor Yellow

# Final summary
Write-Host "`n===== UPDATE COMPLETE =====" -ForegroundColor Green
Write-Host "`n📋 APP DETAILS:" -ForegroundColor Cyan
Write-Host "Application Name: $appName" -ForegroundColor White
Write-Host "Application (Client) ID: $clientId" -ForegroundColor White
Write-Host "Directory (Tenant) ID: $tenantId" -ForegroundColor White
Write-Host "SPA Redirect URIs:" -ForegroundColor White
foreach ($uri in $redirectUris) {
    Write-Host "  - $uri" -ForegroundColor White
}

# Next steps
Write-Host "`n📝 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Clear your browser cache and cookies related to Microsoft authentication" -ForegroundColor White
Write-Host "2. Test authentication at `"http://localhost:8090/intranet/auth-test.html`"" -ForegroundColor White
Write-Host "   (prefer testing in a normal browser window, not VS Code's Simple Browser)" -ForegroundColor White

Write-Host "`nPress any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
