# Reset-AzureAD-RedirectURIs.ps1
# This script resets ALL redirect URIs for the iBridge application to just the correct GitHub Pages URI
# This is the "nuclear option" that should resolve any duplicate URI issues

# App registration details
$clientId = "6686c610-81cf-4ed7-8241-a91a20f01b06" 
$tenantId = "feeb9a78-4032-4b89-ae79-2100a5dc16a8"

# Define the ONLY correct redirect URI for GitHub Pages
$correctRedirectUri = "https://ibridgesolutions.github.io/iBridge/intranet/login.html"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "     iBridge Azure AD Redirect URI RESET TOOL (Nuclear Option)" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️ WARNING: This script will REMOVE ALL redirect URIs and set only:" -ForegroundColor Yellow
Write-Host "   $correctRedirectUri" -ForegroundColor White
Write-Host ""
Write-Host "This should fix any 'Redirect URIs must have distinct values' error." -ForegroundColor White
Write-Host ""

$confirmation = Read-Host "Are you sure you want to proceed? (Y/N)"
if ($confirmation -ne "Y" -and $confirmation -ne "y") {
    Write-Host "Operation cancelled." -ForegroundColor Red
    exit 0
}

# Check if Microsoft Graph PowerShell SDK is installed
$mgGraphModule = Get-Module -ListAvailable -Name Microsoft.Graph.Applications
if ($null -eq $mgGraphModule) {
    Write-Host "The Microsoft Graph PowerShell module is not installed." -ForegroundColor Red
    Write-Host "Installing Microsoft Graph PowerShell module..." -ForegroundColor Yellow
    
    try {
        Install-Module -Name Microsoft.Graph -Force -Scope CurrentUser
    }
    catch {
        Write-Host "Failed to install Microsoft Graph module." -ForegroundColor Red
        Write-Host "Please run this command manually in PowerShell as administrator:" -ForegroundColor Yellow
        Write-Host "Install-Module -Name Microsoft.Graph -Force -Scope CurrentUser" -ForegroundColor White
        exit 1
    }
}

# Connect to Microsoft Graph
try {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Blue
    Connect-MgGraph -TenantId $tenantId -Scopes "Application.ReadWrite.All"
    
    # Set output type to beta for more detailed application information
    Select-MgProfile -Name "beta"
}
catch {
    Write-Host "Failed to connect to Microsoft Graph. Please check your credentials and try again." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Get the application
try {
    Write-Host "Retrieving application with ID $clientId..." -ForegroundColor Blue
    $app = Get-MgApplication -Filter "appId eq '$clientId'"
    
    if ($null -eq $app) {
        Write-Host "Application with ID $clientId not found." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Found application: $($app.DisplayName)" -ForegroundColor Green
    
    # Display current URIs before the reset
    Write-Host ""
    Write-Host "Current redirect URIs before reset:" -ForegroundColor Cyan
    foreach ($uri in $app.Web.RedirectUris) {
        Write-Host "• $uri" -ForegroundColor White
    }
}
catch {
    Write-Host "Failed to retrieve application. Please check your permissions and try again." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Reset all URIs to just the correct one
try {
    Write-Host ""
    Write-Host "Resetting redirect URIs..." -ForegroundColor Blue
    
    $params = @{
        "Web" = @{
            "RedirectUris" = @($correctRedirectUri)
        }
    }
    
    Update-MgApplication -ApplicationId $app.Id -BodyParameter $params
    
    Write-Host "✓ RESET COMPLETE! All previous redirect URIs have been removed." -ForegroundColor Green
    Write-Host "✓ Only the correct GitHub Pages URI remains: $correctRedirectUri" -ForegroundColor Green
}
catch {
    Write-Host "Failed to update application redirect URIs." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Verify the change
try {
    $updatedApp = Get-MgApplication -Filter "appId eq '$clientId'"
    
    Write-Host ""
    Write-Host "Verifying new redirect URIs:" -ForegroundColor Cyan
    foreach ($uri in $updatedApp.Web.RedirectUris) {
        Write-Host "• $uri" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "                      RESET SUCCESSFUL!" -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "The Azure AD app now has exactly one redirect URI:" -ForegroundColor White
    Write-Host "$correctRedirectUri" -ForegroundColor Green
    Write-Host ""
    Write-Host "You should now be able to access the iBridge portal at:" -ForegroundColor White
    Write-Host "https://ibridgesolutions.github.io/iBridge/intranet/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "If login still doesn't work, try clearing your browser cookies and cache." -ForegroundColor Yellow
}
catch {
    Write-Host "Failed to verify application changes." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor White
Read-Host
