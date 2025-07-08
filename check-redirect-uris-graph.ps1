# Script to check and fix redirect URIs for iBridge Azure AD application using Microsoft Graph SDK
# This script is compatible with both PowerShell Core (pwsh) and Windows PowerShell

# App registration details
$clientId = "6686c610-81cf-4ed7-8241-a91a20f01b06" 
$tenantId = "feeb9a78-4032-4b89-ae79-2100a5dc16a8"

# Define the correct redirect URI for GitHub Pages
$githubPagesRedirectUri = "https://ibridgesolutions.github.io/iBridge/intranet/login.html"
$incorrectRedirectUri = "https://ibridgesolutions.github.io/intranet/login.html" # Missing /iBridge/

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "    iBridge Azure AD Redirect URI Verification & Cleanup Tool" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Microsoft Graph PowerShell SDK is installed
$mgGraphModule = Get-Module -ListAvailable -Name Microsoft.Graph.Applications
if ($null -eq $mgGraphModule) {
    Write-Host "The Microsoft Graph PowerShell module is not installed." -ForegroundColor Red
    Write-Host "Please install it by running:" -ForegroundColor Yellow
    Write-Host "Install-Module -Name Microsoft.Graph -Force -Scope CurrentUser" -ForegroundColor White
    Write-Host ""
    Write-Host "If that fails, try first running:" -ForegroundColor Yellow
    Write-Host "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor White
    exit 1
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
}
catch {
    Write-Host "Failed to retrieve application. Please check your permissions and try again." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Show all redirect URIs and check for duplicates
Write-Host ""
Write-Host "Current redirect URIs for $($app.DisplayName):" -ForegroundColor Cyan

# Build a hashtable to check for case-insensitive duplicates
$uriCounts = @{}
$duplicateFound = $false

foreach ($uri in $app.Web.RedirectUris) {
    $uriLower = $uri.ToLower()
    
    # Count occurrences (case-insensitive)
    if ($uriCounts.ContainsKey($uriLower)) {
        $uriCounts[$uriLower] += 1
        $duplicateFound = $true
    } else {
        $uriCounts[$uriLower] = 1
    }
    
    # Display the URI with the appropriate status indicator
    if ($uri -eq $githubPagesRedirectUri) {
        Write-Host "✓ $uri (CORRECT GitHub Pages URI)" -ForegroundColor Green
    }
    elseif ($uri -eq $incorrectRedirectUri) {
        Write-Host "✗ $uri (INCORRECT GitHub Pages URI - missing /iBridge/ path)" -ForegroundColor Red
    }
    elseif ($uriCounts[$uriLower] > 1) {
        Write-Host "⚠️ $uri (DUPLICATE - case-sensitive variation exists)" -ForegroundColor Yellow
    }
    else {
        Write-Host "• $uri" -ForegroundColor White
    }
}

# Check for the correct GitHub Pages redirect URI
$hasCorrectUri = $app.Web.RedirectUris -contains $githubPagesRedirectUri
$hasIncorrectUri = $app.Web.RedirectUris -contains $incorrectRedirectUri

Write-Host ""
if ($hasCorrectUri) {
    Write-Host "✓ The correct GitHub Pages redirect URI is configured." -ForegroundColor Green
} 
else {
    Write-Host "✗ The correct GitHub Pages redirect URI is NOT configured!" -ForegroundColor Red
    Write-Host "  Missing: $githubPagesRedirectUri" -ForegroundColor Red
}

if ($hasIncorrectUri) {
    Write-Host "⚠️ WARNING: An incorrect GitHub Pages redirect URI was found!" -ForegroundColor Yellow
    Write-Host "  Found: $incorrectRedirectUri" -ForegroundColor Yellow
    Write-Host "  This URI is missing the '/iBridge/' repository name in the path" -ForegroundColor Yellow
}

# Check for case-insensitive duplicates
Write-Host ""
if ($duplicateFound) {
    Write-Host "⚠️ DUPLICATE URIs DETECTED! Azure AD considers URIs case-insensitive." -ForegroundColor Red
    Write-Host "The following URIs have case-insensitive duplicates:" -ForegroundColor Red
    
    foreach ($uri in $uriCounts.Keys) {
        if ($uriCounts[$uri] > 1) {
            Write-Host "  - '$uri' appears $($uriCounts[$uri]) times (with different case variations)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "This is likely causing the 'Redirect URIs must have distinct values' error!" -ForegroundColor Red
}

# Offer to fix the issue
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "                        FIX OPTIONS" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan

$fixOption = Read-Host "Would you like to fix the redirect URIs now? (Y/N)"

if ($fixOption -eq "Y" -or $fixOption -eq "y") {
    Write-Host ""
    Write-Host "Choose an option:" -ForegroundColor Cyan
    Write-Host "1. Add missing correct URI only" -ForegroundColor White
    Write-Host "2. Remove incorrect URI only" -ForegroundColor White
    Write-Host "3. Remove duplicates only" -ForegroundColor White
    Write-Host "4. RESET ALL - Keep only the correct GitHub Pages URI" -ForegroundColor Red
    Write-Host "5. Cancel - make no changes" -ForegroundColor Yellow
    
    $option = Read-Host "Enter your choice (1-5)"
    
    switch ($option) {
        "1" {
            if (-not $hasCorrectUri) {
                $newUris = $app.Web.RedirectUris + @($githubPagesRedirectUri)
                
                $params = @{
                    "Web" = @{
                        "RedirectUris" = $newUris
                    }
                }
                
                Update-MgApplication -ApplicationId $app.Id -BodyParameter $params
                Write-Host "✓ Added the correct GitHub Pages redirect URI." -ForegroundColor Green
            } else {
                Write-Host "The correct URI is already present. No changes made." -ForegroundColor Yellow
            }
        }
        "2" {
            if ($hasIncorrectUri) {
                $newUris = $app.Web.RedirectUris | Where-Object { $_ -ne $incorrectRedirectUri }
                
                $params = @{
                    "Web" = @{
                        "RedirectUris" = $newUris
                    }
                }
                
                Update-MgApplication -ApplicationId $app.Id -BodyParameter $params
                Write-Host "✓ Removed the incorrect GitHub Pages redirect URI." -ForegroundColor Green
            } else {
                Write-Host "The incorrect URI is not present. No changes made." -ForegroundColor Yellow
            }
        }
        "3" {
            # Remove duplicate URIs (keeping one instance of each, preferring the exact case match if possible)
            $uniqueUris = @{}
            $newUriList = @()
            
            foreach ($uri in $app.Web.RedirectUris) {
                $lowerUri = $uri.ToLower()
                if (-not $uniqueUris.ContainsKey($lowerUri)) {
                    $uniqueUris[$lowerUri] = $true
                    $newUriList += $uri
                }
            }
            
            $params = @{
                "Web" = @{
                    "RedirectUris" = $newUriList
                }
            }
            
            Update-MgApplication -ApplicationId $app.Id -BodyParameter $params
            Write-Host "✓ Removed duplicate URIs. Each URI now appears exactly once." -ForegroundColor Green
        }
        "4" {
            # Reset all URIs, keeping only the correct GitHub Pages URI
            $params = @{
                "Web" = @{
                    "RedirectUris" = @($githubPagesRedirectUri)
                }
            }
            
            Update-MgApplication -ApplicationId $app.Id -BodyParameter $params
            Write-Host "✓ RESET COMPLETE. All redirect URIs have been removed except for the correct GitHub Pages URI." -ForegroundColor Green
        }
        "5" {
            Write-Host "Operation cancelled. No changes were made." -ForegroundColor Yellow
        }
        default {
            Write-Host "Invalid option. No changes were made." -ForegroundColor Red
        }
    }
    
    # Verify changes if any were made
    if ($option -in @("1", "2", "3", "4")) {
        Write-Host ""
        Write-Host "Verifying changes..." -ForegroundColor Blue
        $updatedApp = Get-MgApplication -Filter "appId eq '$clientId'"
        
        Write-Host ""
        Write-Host "Updated redirect URIs:" -ForegroundColor Cyan
        foreach ($uri in $updatedApp.Web.RedirectUris) {
            if ($uri -eq $githubPagesRedirectUri) {
                Write-Host "✓ $uri (CORRECT GitHub Pages URI)" -ForegroundColor Green
            }
            else {
                Write-Host "• $uri" -ForegroundColor White
            }
        }
    }
}

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
