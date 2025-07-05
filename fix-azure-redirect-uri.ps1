# Script to update Azure AD app registration redirect URIs
# For app ID: 6686c610-81cf-4ed7-8241-a91a20f01b06

# Install required modules if not already installed
if (!(Get-Module -ListAvailable -Name Microsoft.Graph.Applications)) {
    Write-Host "Installing Microsoft Graph Applications module..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph.Applications -Scope CurrentUser -Force
}

if (!(Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "Installing Microsoft Graph Authentication module..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force
}

# Import modules
Import-Module Microsoft.Graph.Applications
Import-Module Microsoft.Graph.Authentication

# Constants
$appId = "6686c610-81cf-4ed7-8241-a91a20f01b06"
$newRedirectUri = "https://ibridgesolutions.github.io/iBridge/intranet/login.html"

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Write-Host "Please sign in with your admin account (lwandile.gasela@ibridge.co.za)" -ForegroundColor Yellow
Connect-MgGraph -Scopes "Application.ReadWrite.All" -UseDeviceAuthentication

try {
    # Get the application by client ID
    Write-Host "Getting application details..." -ForegroundColor Cyan
    $app = Get-MgApplication -Filter "appId eq '$appId'"

    if ($null -eq $app) {
        Write-Host "Error: Application with ID $appId not found." -ForegroundColor Red
        exit 1
    }

    Write-Host "Found application: $($app.DisplayName)" -ForegroundColor Green

    # Display current redirect URIs
    Write-Host "Current web redirect URIs:" -ForegroundColor Cyan
    foreach ($uri in $app.Web.RedirectUris) {
        Write-Host " - $uri" -ForegroundColor White
    }

    # Check if the URI already exists
    if ($app.Web.RedirectUris -contains $newRedirectUri) {
        Write-Host "The redirect URI '$newRedirectUri' already exists." -ForegroundColor Yellow
    } else {
        # Add the new redirect URI
        Write-Host "Adding new redirect URI: $newRedirectUri" -ForegroundColor Cyan
        $webProperties = @{
            RedirectUris = $app.Web.RedirectUris + $newRedirectUri
        }

        if ($null -eq $app.Web) {
            # If Web property doesn't exist, create it
            Update-MgApplication -ApplicationId $app.Id -Web @{ RedirectUris = @($newRedirectUri) }
        } else {
            # Update existing Web property
            Update-MgApplication -ApplicationId $app.Id -Web $webProperties
        }

        Write-Host "Successfully added the redirect URI." -ForegroundColor Green
    }

    # Verify the update
    $updatedApp = Get-MgApplication -Filter "appId eq '$appId'"
    Write-Host "Updated web redirect URIs:" -ForegroundColor Cyan
    foreach ($uri in $updatedApp.Web.RedirectUris) {
        Write-Host " - $uri" -ForegroundColor White
    }

    # Add the same URI as a SPA redirect URI as well (this is sometimes needed for modern authentication)
    Write-Host "Checking SPA redirect URIs..." -ForegroundColor Cyan
    
    $hasSpaPlatform = $null -ne $updatedApp.Spa
    
    if ($hasSpaPlatform) {
        if ($updatedApp.Spa.RedirectUris -contains $newRedirectUri) {
            Write-Host "The SPA redirect URI '$newRedirectUri' already exists." -ForegroundColor Yellow
        } else {
            $spaProperties = @{
                RedirectUris = $updatedApp.Spa.RedirectUris + $newRedirectUri
            }
            
            if ($null -eq $updatedApp.Spa -or $null -eq $updatedApp.Spa.RedirectUris) {
                Update-MgApplication -ApplicationId $app.Id -Spa @{ RedirectUris = @($newRedirectUri) }
            } else {
                Update-MgApplication -ApplicationId $app.Id -Spa $spaProperties
            }
            
            Write-Host "Successfully added the SPA redirect URI." -ForegroundColor Green
        }
    } else {
        Write-Host "Adding SPA platform with redirect URI..." -ForegroundColor Cyan
        Update-MgApplication -ApplicationId $app.Id -Spa @{ RedirectUris = @($newRedirectUri) }
        Write-Host "Successfully added SPA platform with the redirect URI." -ForegroundColor Green
    }

    # Final verification
    $finalApp = Get-MgApplication -Filter "appId eq '$appId'"
    
    Write-Host "`nFINAL CONFIGURATION:" -ForegroundColor Green
    Write-Host "Web redirect URIs:" -ForegroundColor Cyan
    foreach ($uri in $finalApp.Web.RedirectUris) {
        Write-Host " - $uri" -ForegroundColor White
    }
    
    if ($null -ne $finalApp.Spa -and $null -ne $finalApp.Spa.RedirectUris) {
        Write-Host "SPA redirect URIs:" -ForegroundColor Cyan
        foreach ($uri in $finalApp.Spa.RedirectUris) {
            Write-Host " - $uri" -ForegroundColor White
        }
    }

    Write-Host "`nNEXT STEPS:" -ForegroundColor Green
    Write-Host "1. Wait about 5 minutes for changes to propagate" -ForegroundColor White
    Write-Host "2. Clear your browser cache or use incognito mode" -ForegroundColor White
    Write-Host "3. Try accessing https://ibridgesolutions.github.io/iBridge/intranet/login.html again" -ForegroundColor White
    
} catch {
    Write-Host "An error occurred:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
} finally {
    # Disconnect from Microsoft Graph
    Disconnect-MgGraph
    Write-Host "Disconnected from Microsoft Graph." -ForegroundColor Cyan
}
