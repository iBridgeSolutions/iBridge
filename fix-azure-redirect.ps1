# Simple script to fix Azure AD redirect URI for GitHub Pages
# This works with both PowerShell Core and Windows PowerShell

$githubPagesRedirectUri = "https://ibridgesolutions.github.io/iBridge/intranet/login.html"
$appId = "6686c610-81cf-4ed7-8241-a91a20f01b06"

Write-Host "======================================================"
Write-Host "         Azure AD Redirect URI Fix Script"
Write-Host "======================================================"
Write-Host ""
Write-Host "This script will help fix the GitHub Pages redirect URI issue."
Write-Host "Please follow these steps:"
Write-Host ""

Write-Host "1. Sign in to the Azure Portal: https://portal.azure.com" -ForegroundColor Yellow
Write-Host "2. Navigate to Azure Active Directory > App registrations" -ForegroundColor Yellow  
Write-Host "3. Find and select your application with ID: $appId" -ForegroundColor Yellow
Write-Host "4. Click on 'Authentication' in the left menu" -ForegroundColor Yellow
Write-Host "5. Under 'Platform configurations' > 'Web' > 'Redirect URIs'" -ForegroundColor Yellow
Write-Host "6. Add the following URI:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   $githubPagesRedirectUri" -ForegroundColor Cyan
Write-Host ""
Write-Host "7. Click 'Save' at the top of the page" -ForegroundColor Yellow
Write-Host "8. Wait a few minutes for changes to propagate" -ForegroundColor Yellow
Write-Host "9. Clear your browser cache or use an incognito/private window" -ForegroundColor Yellow
Write-Host "10. Try signing in at: $githubPagesRedirectUri" -ForegroundColor Yellow
Write-Host ""

# Check if Azure AD module is installed
$hasAzureAD = $null -ne (Get-Module -ListAvailable -Name AzureAD)

if ($hasAzureAD) {
    Write-Host "Would you like to try to update the redirect URI automatically? (y/n)" -ForegroundColor Green
    $response = Read-Host
    
    if ($response -eq "y") {
        Write-Host "Attempting to connect to Azure AD..." -ForegroundColor Blue
        try {
            # Try to import the module
            Import-Module AzureAD -ErrorAction Stop
            
            # Try to connect
            Connect-AzureAD -ErrorAction Stop
            
            # Get the application
            $app = Get-AzureADApplication -Filter "AppId eq '$appId'" -ErrorAction Stop
            
            if ($null -eq $app) {
                Write-Host "Application with ID $appId not found." -ForegroundColor Red
            } else {
                Write-Host "Found application: $($app.DisplayName)" -ForegroundColor Green
                
                # Check if URI exists
                $uriExists = $false
                foreach ($uri in $app.ReplyUrls) {
                    if ($uri -eq $githubPagesRedirectUri) {
                        $uriExists = $true
                        break
                    }
                }
                
                if ($uriExists) {
                    Write-Host "The redirect URI is already configured correctly." -ForegroundColor Green
                } else {
                    # Add the URI
                    $newReplyUrls = $app.ReplyUrls + $githubPagesRedirectUri
                    Set-AzureADApplication -ObjectId $app.ObjectId -ReplyUrls $newReplyUrls
                    Write-Host "Successfully added redirect URI!" -ForegroundColor Green
                }
            }
        }
        catch {
            Write-Host "Error: $_" -ForegroundColor Red
            Write-Host "Please follow the manual steps above instead." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "The AzureAD module is not installed. Please follow the manual steps above." -ForegroundColor Yellow
}

# Copy to clipboard
Write-Host ""
Write-Host "Would you like to copy the redirect URI to clipboard? (y/n)" -ForegroundColor Green
$copyResponse = Read-Host

if ($copyResponse -eq "y") {
    $githubPagesRedirectUri | Set-Clipboard
    Write-Host "Copied to clipboard: $githubPagesRedirectUri" -ForegroundColor Green
}
