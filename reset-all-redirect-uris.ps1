# Complete Reset of Azure AD Redirect URIs
# This script completely removes all URIs and adds only the correct one

# App details
$clientId = "6686c610-81cf-4ed7-8241-a91a20f01b06"
$tenantId = "feeb9a78-4032-4b89-ae79-2100a5dc16a8"

# The correct URI to set
$correctUri = "https://ibridgesolutions.github.io/iBridge/intranet/login.html"

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "         Azure AD Complete URI Reset Tool" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This is an ADVANCED fix for persistent redirect URI problems" -ForegroundColor Yellow
Write-Host "It will REMOVE ALL existing redirect URIs and add only the correct one" -ForegroundColor Yellow
Write-Host ""

try {
    # Check if we're running PowerShell Core
    if ($PSVersionTable.PSEdition -eq "Core") {
        throw "This script must run in Windows PowerShell (not PowerShell Core)"
    }

    # Check if Azure AD module is installed
    $azureADModule = Get-Module -ListAvailable -Name AzureAD
    if ($null -eq $azureADModule) {
        Write-Host "Installing AzureAD module..." -ForegroundColor Yellow
        Install-Module -Name AzureAD -Force -Scope CurrentUser
        Write-Host "AzureAD module installed successfully" -ForegroundColor Green
    }

    # Import the module
    Import-Module AzureAD

    # Connect to Azure AD
    Write-Host "Connecting to Azure AD..." -ForegroundColor Blue
    Connect-AzureAD

    # Get the application
    Write-Host "Finding application with ID $clientId..." -ForegroundColor Blue
    $app = Get-AzureADApplication -Filter "AppId eq '$clientId'"
    
    if ($null -eq $app) {
        Write-Host "Application not found!" -ForegroundColor Red
        exit
    }

    Write-Host "Found application: $($app.DisplayName)" -ForegroundColor Green
    
    # Display current URIs
    Write-Host ""
    Write-Host "Current redirect URIs:" -ForegroundColor Cyan
    foreach ($uri in $app.ReplyUrls) {
        if ($uri -eq $correctUri) {
            Write-Host "• $uri (CORRECT)" -ForegroundColor Green
        } else {
            Write-Host "• $uri (WILL BE REMOVED)" -ForegroundColor Red
        }
    }

    # Confirm the operation
    Write-Host ""
    Write-Host "WARNING: This will REMOVE ALL existing redirect URIs!" -ForegroundColor Red
    Write-Host "Only this URI will remain: $correctUri" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Continue? (y/n)" -ForegroundColor Yellow
    $confirm = Read-Host

    if ($confirm -ne "y") {
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        exit
    }

    # Set the new URI list (just the one correct URI)
    $newUris = @($correctUri)

    # Update the application
    Write-Host "Updating application..." -ForegroundColor Blue
    Set-AzureADApplication -ObjectId $app.ObjectId -ReplyUrls $newUris

    # Verify the changes
    $updatedApp = Get-AzureADApplication -Filter "AppId eq '$clientId'"
    
    Write-Host ""
    Write-Host "Updated redirect URIs:" -ForegroundColor Cyan
    foreach ($uri in $updatedApp.ReplyUrls) {
        Write-Host "• $uri" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "SUCCESS! All redirect URIs have been reset" -ForegroundColor Green
    Write-Host "Only the correct URI remains:" -ForegroundColor Green
    Write-Host $correctUri -ForegroundColor Green

} catch {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "MANUAL STEPS:" -ForegroundColor Yellow
    Write-Host "1. Sign in to the Azure Portal: https://portal.azure.com" -ForegroundColor White
    Write-Host "2. Go to Azure Active Directory > App registrations" -ForegroundColor White
    Write-Host "3. Find your app with ID: $clientId" -ForegroundColor White
    Write-Host "4. Click on Authentication in the left menu" -ForegroundColor White
    Write-Host "5. Under Redirect URIs, DELETE ALL existing URIs" -ForegroundColor White
    Write-Host "6. Click Save" -ForegroundColor White
    Write-Host "7. Add ONLY this URI:" -ForegroundColor White
    Write-Host "   $correctUri" -ForegroundColor Green
    Write-Host "8. Click Save again" -ForegroundColor White
    Write-Host ""

    # Try to copy the URI to clipboard
    try {
        Set-Clipboard -Value $correctUri
        Write-Host "The correct URI has been copied to your clipboard" -ForegroundColor Green
    } catch {
        # Silently fail if clipboard operation doesn't work
    }
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "                   NEXT STEPS" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "1. Wait 5 minutes for Azure AD changes to propagate" -ForegroundColor Yellow
Write-Host "2. Clear ALL browser caches or use a private window" -ForegroundColor Yellow
Write-Host "3. Try signing in at: $correctUri" -ForegroundColor Yellow
Write-Host ""
Write-Host "If problems persist, create a new app registration" -ForegroundColor White
Write-Host "====================================================" -ForegroundColor Cyan
