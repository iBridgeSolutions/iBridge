# Simplified script to update Azure AD app registration redirect URIs
# For app ID: 6686c610-81cf-4ed7-8241-a91a20f01b06

# Install the Azure AD PowerShell module if not installed
if (!(Get-Module -ListAvailable -Name AzureAD)) {
    Write-Host "Installing AzureAD module..." -ForegroundColor Yellow
    Install-Module AzureAD -Scope CurrentUser -Force
}

# Import the module
Import-Module AzureAD

# Constants
$appId = "6686c610-81cf-4ed7-8241-a91a20f01b06"
$newRedirectUri = "https://ibridgesolutions.github.io/iBridge/intranet/login.html"

Write-Host "Please sign in with your admin account (lwandile.gasela@ibridge.co.za)" -ForegroundColor Yellow

# Connect to Azure AD
Connect-AzureAD

try {
    # Get the application by client ID
    $app = Get-AzureADApplication -Filter "appId eq '$appId'"

    if ($null -eq $app) {
        Write-Host "Error: Application with ID $appId not found." -ForegroundColor Red
        exit 1
    }

    Write-Host "Found application: $($app.DisplayName)" -ForegroundColor Green

    # Get current redirect URIs
    $currentUris = $app.ReplyUrls
    Write-Host "Current redirect URIs:" -ForegroundColor Cyan
    $currentUris | ForEach-Object { Write-Host " - $_" -ForegroundColor White }

    # Check if the URI already exists
    if ($currentUris -contains $newRedirectUri) {
        Write-Host "The redirect URI '$newRedirectUri' already exists." -ForegroundColor Yellow
    } else {
        # Add the new redirect URI
        $updatedUris = $currentUris + $newRedirectUri
        Set-AzureADApplication -ObjectId $app.ObjectId -ReplyUrls $updatedUris
        Write-Host "Successfully added the redirect URI." -ForegroundColor Green
    }

    # Verify the update
    $updatedApp = Get-AzureADApplication -Filter "appId eq '$appId'"
    Write-Host "Updated redirect URIs:" -ForegroundColor Cyan
    $updatedApp.ReplyUrls | ForEach-Object { Write-Host " - $_" -ForegroundColor White }

    Write-Host "`nNEXT STEPS:" -ForegroundColor Green
    Write-Host "1. Wait about 5 minutes for changes to propagate" -ForegroundColor White
    Write-Host "2. Clear your browser cache or use incognito mode" -ForegroundColor White
    Write-Host "3. Try accessing https://ibridgesolutions.github.io/iBridge/intranet/login.html again" -ForegroundColor White

} catch {
    Write-Host "An error occurred:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
} finally {
    # Disconnect from Azure AD
    Disconnect-AzureAD
    Write-Host "Disconnected from Azure AD." -ForegroundColor Cyan
}
