# Super-Simple iBridge Portal App Registration
# This script automates everything with minimal permissions requirements

# App registration details
$appName = "iBridge Portal"
$redirectUris = @(
    "http://localhost:8090/intranet/login.html",
    "http://localhost:8090/intranet/",
    "http://localhost:8090/intranet/index.html", 
    "http://localhost:8090/login.html"
)

Write-Host "===== AUTOMATED iBRIDGE PORTAL APP REGISTRATION =====" -ForegroundColor Cyan
Write-Host "This script will register the iBridge Portal app in Microsoft Entra ID" -ForegroundColor Cyan
Write-Host "with your Microsoft 365 admin account" -ForegroundColor Cyan
Write-Host ""

# Function to handle errors
function Handle-Error {
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
        Write-Host "  Installing AzureAD module (simpler than Microsoft.Graph)..." -ForegroundColor Yellow
        Install-Module AzureAD -Force -Scope CurrentUser
        Write-Host "  ✅ AzureAD module installed successfully" -ForegroundColor Green
    } catch {
        Handle-Error "Failed to install AzureAD module. Please run PowerShell as Administrator and try again."
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
    Handle-Error "Failed to connect to Microsoft 365. Please make sure you have admin permissions."
}

# Create app registration
Write-Host "`nStep 3: Creating app registration..." -ForegroundColor Green
try {
    # Check if app already exists
    $existingApp = Get-AzureADApplication -Filter "DisplayName eq '$appName'" -ErrorAction SilentlyContinue
    
    if ($existingApp) {
        Write-Host "  ⚠️ App '$appName' already exists" -ForegroundColor Yellow
        Write-Host "  ✅ Using existing app ID: $($existingApp.AppId)" -ForegroundColor Green
        $clientId = $existingApp.AppId
        $objectId = $existingApp.ObjectId
    } else {
        # Create new web app
        $appReplyUrls = New-Object System.Collections.Generic.List[string]
        foreach ($uri in $redirectUris) {
            $appReplyUrls.Add($uri)
        }
        
        # Create the app
        Write-Host "  Creating new app registration '$appName'..." -ForegroundColor Yellow
        $app = New-AzureADApplication -DisplayName $appName -ReplyUrls $appReplyUrls -PublicClient $false
        $clientId = $app.AppId
        $objectId = $app.ObjectId
        Write-Host "  ✅ App created successfully with ID: $clientId" -ForegroundColor Green
    }
} catch {
    Handle-Error "Failed to create app registration: $_"
}

# Configure implicit grant
Write-Host "`nStep 4: Configuring implicit grant settings..." -ForegroundColor Green
try {
    # Get current app
    $app = Get-AzureADApplication -ObjectId $objectId
    
    # Configure implicit grant
    $app.Oauth2AllowImplicitFlow = $true
    $app.Oauth2AllowIdTokenImplicitFlow = $true
    
    # Update the app
    Set-AzureADApplication -ObjectId $objectId -Oauth2AllowImplicitFlow $true -Oauth2AllowIdTokenImplicitFlow $true
    
    Write-Host "  ✅ Implicit grant configured successfully" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️ Warning: Could not configure implicit grant: $_" -ForegroundColor Yellow
    Write-Host "      You may need to do this step manually in the portal" -ForegroundColor Yellow
}

# Add API permissions
Write-Host "`nStep 5: Adding API permissions..." -ForegroundColor Green
try {
    # Microsoft Graph resource ID
    $msGraphResourceId = "00000003-0000-0000-c000-000000000000"
    
    # Get Microsoft Graph service principal
    $graphServicePrincipal = Get-AzureADServicePrincipal -Filter "AppId eq '$msGraphResourceId'"
    
    # Get User.Read permission
    $userReadPermission = $graphServicePrincipal.OAuth2Permissions | Where-Object { $_.Value -eq "User.Read" }
    
    # Create permission
    $reqResourceAccess = New-Object -TypeName Microsoft.Open.AzureAD.Model.RequiredResourceAccess
    $reqResourceAccess.ResourceAppId = $msGraphResourceId
    
    $resourceAccess = New-Object -TypeName Microsoft.Open.AzureAD.Model.ResourceAccess
    $resourceAccess.Id = $userReadPermission.Id
    $resourceAccess.Type = "Scope"
    
    $reqResourceAccess.ResourceAccess = @($resourceAccess)
    
    # Add permission to app
    Set-AzureADApplication -ObjectId $objectId -RequiredResourceAccess @($reqResourceAccess)
    
    Write-Host "  ✅ User.Read permission added successfully" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️ Warning: Could not add User.Read permission: $_" -ForegroundColor Yellow
    Write-Host "      You may need to add this permission manually in the portal" -ForegroundColor Yellow
}

# Create service principal (enables admin consent)
Write-Host "`nStep 6: Creating service principal to enable admin consent..." -ForegroundColor Green
try {
    # Check if service principal exists
    $servicePrincipal = Get-AzureADServicePrincipal -Filter "AppId eq '$clientId'" -ErrorAction SilentlyContinue
    
    if (-not $servicePrincipal) {
        $servicePrincipal = New-AzureADServicePrincipal -AppId $clientId
        Write-Host "  ✅ Service principal created successfully" -ForegroundColor Green
    } else {
        Write-Host "  ✅ Service principal already exists" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️ Warning: Could not create service principal: $_" -ForegroundColor Yellow
    Write-Host "      Admin consent may need to be granted manually" -ForegroundColor Yellow
}

# Attempt to grant admin consent
Write-Host "`nStep 7: Granting admin consent..." -ForegroundColor Green
Write-Host "  ℹ️ This step may open a browser window for you to confirm admin consent" -ForegroundColor Cyan

try {
    $adminConsentUrl = "https://login.microsoftonline.com/$tenantId/adminconsent?client_id=$clientId"
    Write-Host "  Opening admin consent URL in your default browser..." -ForegroundColor Yellow
    Start-Process $adminConsentUrl
    Write-Host "  ⚠️ Complete the admin consent in your browser when prompted" -ForegroundColor Yellow
} catch {
    Write-Host "  ⚠️ Could not automatically open admin consent URL" -ForegroundColor Yellow
    Write-Host "  Please visit this URL in your browser to grant admin consent:" -ForegroundColor Yellow
    Write-Host "  $adminConsentUrl" -ForegroundColor Cyan
}

# Print summary and next steps
Write-Host "`n===== REGISTRATION COMPLETE =====" -ForegroundColor Green
Write-Host "`n📋 APP REGISTRATION DETAILS:" -ForegroundColor Cyan
Write-Host "Application Name: $appName" -ForegroundColor White
Write-Host "Application (Client) ID: $clientId" -ForegroundColor White
Write-Host "Directory (Tenant) ID: $tenantId" -ForegroundColor White
Write-Host "Redirect URIs:" -ForegroundColor White
foreach ($uri in $redirectUris) {
    Write-Host "  - $uri" -ForegroundColor White
}

# Check if we need to update the login.html file
Write-Host "`n⚠️ IMPORTANT: Check if the client ID in your login.html file matches!" -ForegroundColor Yellow
Write-Host "Current client ID in login.html: 2f833c55-f976-4d6c-ad96-fa357119f0ee" -ForegroundColor White
Write-Host "New client ID from registration: $clientId" -ForegroundColor White

if ($clientId -ne "2f833c55-f976-4d6c-ad96-fa357119f0ee") {
    Write-Host "`n❗ The client IDs don't match! Would you like to update login.html now? (y/n)" -ForegroundColor Red
    $updateChoice = Read-Host
    if ($updateChoice -eq "y" -or $updateChoice -eq "Y") {
        # Update the login.html file
        $loginHtmlPath = Join-Path $PSScriptRoot "intranet\login.html"
        if (Test-Path $loginHtmlPath) {
            try {
                $content = Get-Content -Path $loginHtmlPath -Raw
                $updatedContent = $content -replace "2f833c55-f976-4d6c-ad96-fa357119f0ee", $clientId
                $updatedContent = $updatedContent -replace "feeb9a78-4032-4b89-ae79-2100a5dc16a8", $tenantId
                Set-Content -Path $loginHtmlPath -Value $updatedContent
                Write-Host "  ✅ login.html updated successfully with new client ID and tenant ID" -ForegroundColor Green
            } catch {
                Write-Host "  ❌ Error updating login.html: $_" -ForegroundColor Red
                Write-Host "  Please update the client ID manually in login.html" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ❌ Could not find login.html at $loginHtmlPath" -ForegroundColor Red
            Write-Host "  Please update the client ID manually in login.html" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Please update the client ID manually in login.html" -ForegroundColor Yellow
    }
}

# Final steps
Write-Host "`n📝 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Start your intranet server:" -ForegroundColor White
Write-Host "   .\intranet\serve-intranet.ps1" -ForegroundColor White
Write-Host "2. Open this URL in your browser:" -ForegroundColor White
Write-Host "   http://localhost:8090/intranet/login.html" -ForegroundColor White
Write-Host "3. Click 'Sign in with Microsoft 365'" -ForegroundColor White
Write-Host "4. You should be redirected to the intranet after successful login" -ForegroundColor White
Write-Host "`nPress any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
