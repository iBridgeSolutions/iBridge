# Automated Microsoft Entra ID App Registration Setup
# This script registers and configures the iBridge Portal app in Microsoft Entra ID (Azure AD)

# Parameters
$appName = "iBridge Portal"
$redirectUris = @(
    "http://localhost:8090/intranet/login.html",
    "http://localhost:8090/intranet/",
    "http://localhost:8090/intranet/index.html",
    "http://localhost:8090/login.html"
)

Write-Host "===== iBridge Portal - Automated Microsoft Entra ID Setup =====" -ForegroundColor Cyan
Write-Host ""

# Step 1: Connect to Microsoft Entra ID
Write-Host "Step 1: Connecting to Microsoft Entra ID..." -ForegroundColor Green
try {
    # Install the module if not already installed
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        Write-Host "Installing Microsoft.Graph PowerShell module..." -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force
    }

    # Import the modules
    Import-Module Microsoft.Graph.Authentication
    Import-Module Microsoft.Graph.Applications

    # For admins: Use admin consent flow to avoid permission prompts
    Write-Host "Connecting with admin consent flow..." -ForegroundColor Yellow
    Connect-MgGraph -NoWelcome -UseDeviceAuthentication
    
    Write-Host "Successfully connected to Microsoft Entra ID" -ForegroundColor Green
}
catch {
    Write-Host "Error connecting to Microsoft Entra ID: $_" -ForegroundColor Red
    Write-Host "Please ensure you have Microsoft Graph PowerShell modules installed and proper permissions." -ForegroundColor Red
    exit 1
}

# Step 2: Register the application
Write-Host "`nStep 2: Creating app registration for '$appName'..." -ForegroundColor Green
try {
    # Check if app already exists
    $existingApp = Get-MgApplication -Filter "displayName eq '$appName'"
    
    if ($existingApp) {
        Write-Host "Application '$appName' already exists with ID: $($existingApp.Id)" -ForegroundColor Yellow
        $app = $existingApp
    }
    else {
        # Create new app registration
        $app = New-MgApplication -DisplayName $appName -SignInAudience "AzureADMyOrg" -Web @{
            RedirectUris = $redirectUris
            ImplicitGrantSettings = @{
                EnableIdTokenIssuance = $true
                EnableAccessTokenIssuance = $true
            }
        }
        Write-Host "Successfully created app registration '$appName' with ID: $($app.Id)" -ForegroundColor Green
    }
}
catch {
    Write-Host "Error creating app registration: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Configure API permissions
Write-Host "`nStep 3: Configuring API permissions..." -ForegroundColor Green
try {
    # Microsoft Graph User.Read permission ID
    $userReadPermissionId = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read delegated permission

    # Microsoft Graph resource ID
    $graphResourceId = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    # Add User.Read permission
    $requiredResourceAccess = @{
        ResourceAppId = $graphResourceId
        ResourceAccess = @(
            @{
                Id = $userReadPermissionId
                Type = "Scope" # Delegated permission
            }
        )
    }
    
    # Update the application with required permissions
    Update-MgApplication -ApplicationId $app.Id -RequiredResourceAccess @($requiredResourceAccess)
    Write-Host "API permissions configured successfully" -ForegroundColor Green
}
catch {
    Write-Host "Error configuring API permissions: $_" -ForegroundColor Red
}

# Step 4: Enable implicit grant flow (if not already done in app creation)
Write-Host "`nStep 4: Enabling implicit grant flow..." -ForegroundColor Green
try {
    # Update web settings to ensure implicit grant is enabled
    Update-MgApplication -ApplicationId $app.Id -Web @{
        ImplicitGrantSettings = @{
            EnableIdTokenIssuance = $true
            EnableAccessTokenIssuance = $true
        }
    }
    Write-Host "Implicit grant flow enabled successfully" -ForegroundColor Green
}
catch {
    Write-Host "Error enabling implicit grant flow: $_" -ForegroundColor Red
}

# Step 5: Output important info for configuration
Write-Host "`nStep 5: Configuration Complete!" -ForegroundColor Green

# Get the updated app details
$appDetails = Get-MgApplication -ApplicationId $app.Id
$tenantId = (Get-MgContext).TenantId

Write-Host "`n===== IMPORTANT INFORMATION =====" -ForegroundColor Yellow
Write-Host "Application Name: $appName" -ForegroundColor White
Write-Host "Application (Client) ID: $($appDetails.AppId)" -ForegroundColor White
Write-Host "Directory (Tenant) ID: $tenantId" -ForegroundColor White
Write-Host "Configured Redirect URIs:" -ForegroundColor White
foreach ($uri in $appDetails.Web.RedirectUris) {
    Write-Host "  - $uri" -ForegroundColor White
}

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Update your login.html file with the client ID and tenant ID shown above (if different)" -ForegroundColor White
Write-Host "2. Start your intranet server with: .\intranet\serve-intranet.ps1" -ForegroundColor White
Write-Host "3. Navigate to http://localhost:8090/intranet/login.html to test authentication" -ForegroundColor White
Write-Host "`nNOTE: Admin consent may still need to be granted in the Microsoft Entra admin center." -ForegroundColor Yellow

# Disconnect from Microsoft Graph
Disconnect-MgGraph | Out-Null
Write-Host "`nDisconnected from Microsoft Graph. Setup completed." -ForegroundColor Green
