# Script to update the redirect URI for iBridge Azure AD application
# This script helps fix the Azure AD redirect URI mismatch issue by adding the correct GitHub Pages redirect URI

# App registration details
$clientId = "6686c610-81cf-4ed7-8241-a91a20f01b06"
$tenantId = "feeb9a78-4032-4b89-ae79-2100a5dc16a8"

# Define the correct redirect URI for GitHub Pages
$githubPagesRedirectUri = "https://ibridgesolutions.github.io/iBridge/intranet/login.html"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "          iBridge Azure AD Redirect URI Update Tool" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will update your Azure AD application with the correct" -ForegroundColor Yellow
Write-Host "GitHub Pages redirect URI: $githubPagesRedirectUri" -ForegroundColor Yellow
Write-Host ""

# Check if Azure AD PowerShell module is installed
$azureADModule = Get-Module -ListAvailable -Name AzureAD
if ($null -eq $azureADModule) {
    Write-Host "The AzureAD PowerShell module is not installed." -ForegroundColor Red
    Write-Host "Installing AzureAD module..." -ForegroundColor Yellow
    try {
        Install-Module -Name AzureAD -Force -Scope CurrentUser
        Write-Host "AzureAD module installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install AzureAD module. Please install it manually using:" -ForegroundColor Red
        Write-Host "Install-Module -Name AzureAD -Force -Scope CurrentUser" -ForegroundColor White
        Write-Host "Error: $_" -ForegroundColor Red
        exit 1
    }
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

# Check if the redirect URI already exists
$redirectUriExists = $false
foreach ($uri in $app.ReplyUrls) {
    if ($uri -eq $githubPagesRedirectUri) {
        $redirectUriExists = $true
        break
    }
}

if ($redirectUriExists) {
    Write-Host "The redirect URI $githubPagesRedirectUri is already configured." -ForegroundColor Green
}
else {
    # Add the GitHub Pages redirect URI
    try {
        Write-Host "Adding GitHub Pages redirect URI..." -ForegroundColor Blue
        $newReplyUrls = $app.ReplyUrls + $githubPagesRedirectUri
        Set-AzureADApplication -ObjectId $app.ObjectId -ReplyUrls $newReplyUrls
        Write-Host "Successfully added redirect URI: $githubPagesRedirectUri" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to add redirect URI. Please check your permissions and try again." -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        exit 1
    }
}

# Show all current redirect URIs for verification
try {
    $updatedApp = Get-AzureADApplication -Filter "AppId eq '$clientId'"
    
    Write-Host ""
    Write-Host "Current redirect URIs for $($updatedApp.DisplayName):" -ForegroundColor Cyan
    foreach ($uri in $updatedApp.ReplyUrls) {
        if ($uri -eq $githubPagesRedirectUri) {
            Write-Host "✓ $uri" -ForegroundColor Green
        }
        else {
            Write-Host "• $uri" -ForegroundColor White
        }
    }
}
catch {
    Write-Host "Failed to retrieve updated application details." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "                         Next Steps" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "1. Wait for the Azure AD changes to propagate (may take a few minutes)" -ForegroundColor Yellow
Write-Host "2. Clear browser cache or use an incognito/private window" -ForegroundColor Yellow
Write-Host "3. Try signing in again at: https://ibridgesolutions.github.io/iBridge/intranet/login.html" -ForegroundColor Yellow
Write-Host ""
Write-Host "If you still encounter issues, verify that:" -ForegroundColor White
Write-Host "• The application registration in Azure AD has the correct redirect URI" -ForegroundColor White
Write-Host "• You're using a browser that supports modern authentication" -ForegroundColor White
Write-Host "• Your account has access to the application in Azure AD" -ForegroundColor White
Write-Host "====================================================================" -ForegroundColor Cyan
