# Simple iBridge Portal Integration Helper
# This script helps with manual integration by automatically opening relevant pages
# and updating the login.html file without requiring PowerShell modules

# Define your Microsoft 365 tenant domain
$tenantDomain = ""

# Get tenant domain from user if not set
if ([string]::IsNullOrEmpty($tenantDomain)) {
    $tenantDomain = Read-Host "Please enter your Microsoft 365 tenant domain (e.g., yourdomain.onmicrosoft.com or your custom domain)"
}

Write-Host "===== iBRIDGE PORTAL INTEGRATION HELPER =====" -ForegroundColor Cyan
Write-Host "This script will help you integrate iBridge Portal with Microsoft 365" -ForegroundColor Cyan
Write-Host "by opening the necessary configuration pages in your browser" -ForegroundColor Cyan
Write-Host ""

# Function to open URLs
function Open-Url {
    param (
        [string]$Url,
        [string]$Description
    )
    
    Write-Host "Opening: $Description" -ForegroundColor Yellow
    Write-Host "URL: $Url" -ForegroundColor White
    Start-Process $Url
    Start-Sleep -Seconds 1
}

# Step 1: Open Microsoft 365 admin center
Write-Host "Step 1: Open Microsoft 365 admin center" -ForegroundColor Green
Open-Url -Url "https://admin.microsoft.com" -Description "Microsoft 365 admin center"

Write-Host "`nOnce you're in the admin center:" -ForegroundColor Cyan
Write-Host "1. Expand 'All admin centers' in the left navigation" -ForegroundColor White
Write-Host "2. Click on 'Identity (Entra ID)'" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter when you've navigated to the Microsoft Entra admin center"

# Step 2: Open App Registrations
Write-Host "`nStep 2: Opening App Registrations in Microsoft Entra admin center" -ForegroundColor Green
Open-Url -Url "https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade" -Description "App Registrations page"

Write-Host "`nOn the App Registrations page:" -ForegroundColor Cyan
Write-Host "1. Click '+New registration'" -ForegroundColor White
Write-Host "2. Enter 'iBridge Portal' as the name" -ForegroundColor White
Write-Host "3. Select 'Accounts in this organizational directory only'" -ForegroundColor White
Write-Host "4. For Redirect URI, select 'Web' and enter: http://localhost:8090/intranet/login.html" -ForegroundColor White
Write-Host "5. Click 'Register'" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter after you've registered the app (or found an existing registration)"

# Step 3: Update login.html with the new client/tenant IDs
Write-Host "`nStep 3: Update login.html with the new IDs" -ForegroundColor Green
Write-Host "Please provide the IDs from your app registration:" -ForegroundColor Cyan

$clientId = Read-Host "Enter the Application (client) ID"
$tenantId = Read-Host "Enter the Directory (tenant) ID"

if (-not [string]::IsNullOrEmpty($clientId) -and -not [string]::IsNullOrEmpty($tenantId)) {
    # Update login.html with the new IDs
    $loginHtmlPath = Join-Path $PSScriptRoot "intranet\login.html"
    
    if (Test-Path $loginHtmlPath) {
        try {
            Write-Host "Updating login.html with your new IDs..." -ForegroundColor Yellow
            
            $content = Get-Content -Path $loginHtmlPath -Raw
            
            # Update client ID and tenant ID in MSAL config
            $content = $content -replace "clientId: `"2f833c55-f976-4d6c-ad96-fa357119f0ee`"", "clientId: `"$clientId`""
            $content = $content -replace "authority: `"https://login.microsoftonline.com/feeb9a78-4032-4b89-ae79-2100a5dc16a8`"", "authority: `"https://login.microsoftonline.com/$tenantId`""
            
            # Also update the standalone client ID variable
            $content = $content -replace "const clientId = `"2f833c55-f976-4d6c-ad96-fa357119f0ee`"", "const clientId = `"$clientId`""
            
            # Save the changes
            Set-Content -Path $loginHtmlPath -Value $content
            
            Write-Host "✅ login.html updated successfully" -ForegroundColor Green
        } catch {
            Write-Host "❌ Error updating login.html: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Could not find login.html at $loginHtmlPath" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Client ID or Tenant ID not provided. You'll need to update login.html manually." -ForegroundColor Yellow
}

# Step 4: Open Authentication config page to add redirect URIs and enable implicit grant
Write-Host "`nStep 4: Configure Authentication settings" -ForegroundColor Green
if (-not [string]::IsNullOrEmpty($clientId)) {
    $authUrl = "https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Authentication/appId/$clientId"
    Open-Url -Url $authUrl -Description "Authentication configuration page"
    
    Write-Host "`nOn the Authentication page:" -ForegroundColor Cyan
    Write-Host "1. Add these additional redirect URIs:" -ForegroundColor White
    Write-Host "   - http://localhost:8090/intranet/" -ForegroundColor White
    Write-Host "   - http://localhost:8090/intranet/index.html" -ForegroundColor White
    Write-Host "   - http://localhost:8090/login.html" -ForegroundColor White
    Write-Host "2. Check the boxes for ID tokens and Access tokens under Implicit grant" -ForegroundColor White
    Write-Host "3. Click 'Save'" -ForegroundColor White
} else {
    Write-Host "❌ Client ID not provided. Please configure Authentication settings manually." -ForegroundColor Yellow
}

# Step 5: Open API permissions page to add User.Read and grant admin consent
Write-Host "`nStep 5: Configure API permissions" -ForegroundColor Green
if (-not [string]::IsNullOrEmpty($clientId)) {
    $permissionsUrl = "https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/$clientId"
    Open-Url -Url $permissionsUrl -Description "API permissions page"
    
    Write-Host "`nOn the API permissions page:" -ForegroundColor Cyan
    Write-Host "1. Click '+ Add a permission'" -ForegroundColor White
    Write-Host "2. Select 'Microsoft Graph'" -ForegroundColor White
    Write-Host "3. Select 'Delegated permissions'" -ForegroundColor White
    Write-Host "4. Search for and select 'User.Read'" -ForegroundColor White
    Write-Host "5. Click 'Add permissions'" -ForegroundColor White
    Write-Host "6. Click 'Grant admin consent for [Your Org]' and confirm" -ForegroundColor White
} else {
    Write-Host "❌ Client ID not provided. Please configure API permissions manually." -ForegroundColor Yellow
}

# Step 6: Admin consent URL (direct approach if needed)
if (-not [string]::IsNullOrEmpty($clientId) -and -not [string]::IsNullOrEmpty($tenantId)) {
    Write-Host "`nStep 6: Manual Admin Consent URL (use if needed)" -ForegroundColor Green
    $adminConsentUrl = "https://login.microsoftonline.com/$tenantId/adminconsent?client_id=$clientId"
    Write-Host "If you have issues with admin consent, open this URL:" -ForegroundColor White
    Write-Host $adminConsentUrl -ForegroundColor Cyan
}

# Step 7: Start testing
Write-Host "`n===== INTEGRATION COMPLETE =====" -ForegroundColor Cyan
Write-Host "`n📝 NEXT STEPS:" -ForegroundColor Green
Write-Host "1. Start your intranet server:" -ForegroundColor White
Write-Host "   .\intranet\serve-intranet.ps1" -ForegroundColor White
Write-Host "2. Open this URL in your browser:" -ForegroundColor White
Write-Host "   http://localhost:8090/intranet/login.html" -ForegroundColor White
Write-Host "3. Click 'Sign in with Microsoft 365'" -ForegroundColor White
Write-Host "4. You should be redirected to the intranet after successful login" -ForegroundColor White

# Ask if user wants to start the server now
$startServer = Read-Host "`nDo you want to start the intranet server now? (y/n)"
if ($startServer -eq "y" -or $startServer -eq "Y") {
    Write-Host "Starting intranet server..." -ForegroundColor Green
    Start-Process -FilePath "powershell" -ArgumentList "-File `"$PSScriptRoot\intranet\serve-intranet.ps1`""
}

Write-Host "`nPress any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
