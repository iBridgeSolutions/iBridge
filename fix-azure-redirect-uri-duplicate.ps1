# Script to fix duplicate URIs in Azure AD application
# This script helps remove the incorrect URI and keep the correct one

# App details
$clientId = "6686c610-81cf-4ed7-8241-a91a20f01b06"
$tenantId = "feeb9a78-4032-4b89-ae79-2100a5dc16a8"

# URIs
$correctUri = "https://ibridgesolutions.github.io/iBridge/intranet/login.html"
$incorrectUri = "https://ibridgesolutions.github.io/intranet/login.html"

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "       Azure AD Duplicate Redirect URIs Fix" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Error: 'Redirect URIs must have distinct values'" -ForegroundColor Red
Write-Host ""
Write-Host "This script will help remove the incorrect URI and keep the correct one." -ForegroundColor Yellow
Write-Host ""

# Check if Azure AD PowerShell module is installed
$azureADModule = Get-Module -ListAvailable -Name AzureAD
if ($null -eq $azureADModule) {
    Write-Host "The AzureAD PowerShell module is not installed." -ForegroundColor Red
    Write-Host "Please follow these manual steps instead:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Sign in to Azure Portal" -ForegroundColor White
    Write-Host "2. Go to Azure Active Directory > App registrations" -ForegroundColor White
    Write-Host "3. Find your iBridge application (ID: $clientId)" -ForegroundColor White
    Write-Host "4. Click Authentication in the left menu" -ForegroundColor White
    Write-Host "5. Check the list of redirect URIs and remove:" -ForegroundColor White
    Write-Host "   $incorrectUri" -ForegroundColor Red
    Write-Host "6. Make sure this URI is present:" -ForegroundColor White
    Write-Host "   $correctUri" -ForegroundColor Green
    Write-Host "7. Click Save" -ForegroundColor White
    
    # Copy correct URI to clipboard
    try {
        Set-Clipboard -Value $correctUri
        Write-Host ""
        Write-Host "The correct URI has been copied to your clipboard." -ForegroundColor Green
    }
    catch {
        Write-Host ""
        Write-Host "Couldn't copy to clipboard. Please manually copy the correct URI above." -ForegroundColor Yellow
    }
    
    exit
}

# Try to connect to Azure AD
try {
    Write-Host "Connecting to Azure AD..." -ForegroundColor Blue
    Import-Module AzureAD
    Connect-AzureAD -TenantId $tenantId
    
    # Get the application
    Write-Host "Retrieving application with ID $clientId..." -ForegroundColor Blue
    $app = Get-AzureADApplication -Filter "AppId eq '$clientId'"
    
    if ($null -eq $app) {
        Write-Host "Application with ID $clientId not found." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Found application: $($app.DisplayName)" -ForegroundColor Green
    
    # Check if both URIs exist
    $hasCorrectUri = $false
    $hasIncorrectUri = $false
    
    foreach ($uri in $app.ReplyUrls) {
        if ($uri -eq $correctUri) {
            $hasCorrectUri = $true
        }
        if ($uri -eq $incorrectUri) {
            $hasIncorrectUri = $true
        }
    }
    
    # Display current URIs
    Write-Host ""
    Write-Host "Current redirect URIs:" -ForegroundColor Cyan
    foreach ($uri in $app.ReplyUrls) {
        if ($uri -eq $correctUri) {
            Write-Host "✓ $uri (CORRECT)" -ForegroundColor Green
        }
        elseif ($uri -eq $incorrectUri) {
            Write-Host "✗ $uri (INCORRECT - will be removed)" -ForegroundColor Red
        }
        else {
            Write-Host "• $uri" -ForegroundColor White
        }
    }
    
    # Fix the URIs
    if ($hasIncorrectUri) {
        Write-Host ""
        Write-Host "Found incorrect URI. Removing it..." -ForegroundColor Yellow
        
        # Create new URI list without the incorrect URI
        $newUris = $app.ReplyUrls | Where-Object { $_ -ne $incorrectUri }
        
        # Add correct URI if it doesn't exist
        if (-not $hasCorrectUri) {
            $newUris += $correctUri
        }
        
        # Update the application
        try {
            Set-AzureADApplication -ObjectId $app.ObjectId -ReplyUrls $newUris
            Write-Host "Successfully updated redirect URIs!" -ForegroundColor Green
            
            # Verify the changes
            $updatedApp = Get-AzureADApplication -Filter "AppId eq '$clientId'"
            
            Write-Host ""
            Write-Host "Updated redirect URIs:" -ForegroundColor Cyan
            foreach ($uri in $updatedApp.ReplyUrls) {
                if ($uri -eq $correctUri) {
                    Write-Host "✓ $uri (CORRECT)" -ForegroundColor Green
                }
                else {
                    Write-Host "• $uri" -ForegroundColor White
                }
            }
        }
        catch {
            Write-Host "Failed to update application. Error: $_" -ForegroundColor Red
            Write-Host "Please update the redirect URIs manually." -ForegroundColor Yellow
        }
    }
    elseif (-not $hasCorrectUri) {
        Write-Host ""
        Write-Host "The correct URI is not configured. Adding it..." -ForegroundColor Yellow
        
        # Add correct URI
        $newUris = $app.ReplyUrls + $correctUri
        
        # Update the application
        try {
            Set-AzureADApplication -ObjectId $app.ObjectId -ReplyUrls $newUris
            Write-Host "Successfully added the correct redirect URI!" -ForegroundColor Green
            
            # Verify the changes
            $updatedApp = Get-AzureADApplication -Filter "AppId eq '$clientId'"
            
            Write-Host ""
            Write-Host "Updated redirect URIs:" -ForegroundColor Cyan
            foreach ($uri in $updatedApp.ReplyUrls) {
                if ($uri -eq $correctUri) {
                    Write-Host "✓ $uri (CORRECT)" -ForegroundColor Green
                }
                else {
                    Write-Host "• $uri" -ForegroundColor White
                }
            }
        }
        catch {
            Write-Host "Failed to update application. Error: $_" -ForegroundColor Red
            Write-Host "Please update the redirect URIs manually." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host ""
        Write-Host "No issues found! The correct URI is already configured." -ForegroundColor Green
    }
}
catch {
    Write-Host "Failed to connect to Azure AD or perform operations. Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please follow these manual steps instead:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Sign in to Azure Portal" -ForegroundColor White
    Write-Host "2. Go to Azure Active Directory > App registrations" -ForegroundColor White
    Write-Host "3. Find your iBridge application (ID: $clientId)" -ForegroundColor White
    Write-Host "4. Click Authentication in the left menu" -ForegroundColor White
    Write-Host "5. Check the list of redirect URIs and remove:" -ForegroundColor White
    Write-Host "   $incorrectUri" -ForegroundColor Red
    Write-Host "6. Make sure this URI is present:" -ForegroundColor White
    Write-Host "   $correctUri" -ForegroundColor Green
    Write-Host "7. Click Save" -ForegroundColor White
    
    # Copy correct URI to clipboard
    try {
        Set-Clipboard -Value $correctUri
        Write-Host ""
        Write-Host "The correct URI has been copied to your clipboard." -ForegroundColor Green
    }
    catch {
        Write-Host ""
        Write-Host "Couldn't copy to clipboard. Please manually copy the correct URI above." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "                  Next Steps" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "1. Wait for Azure AD changes to propagate (may take a few minutes)" -ForegroundColor Yellow
Write-Host "2. Clear browser cache or use an incognito/private window" -ForegroundColor Yellow
Write-Host "3. Try signing in again at: $correctUri" -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan
