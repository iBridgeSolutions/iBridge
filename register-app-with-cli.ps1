# Simple Azure CLI Script to Register iBridge Portal App
# This script uses Azure CLI which often has fewer permission issues

# Define app parameters
$appName = "iBridge Portal"
$redirectUris = "http://localhost:8090/intranet/login.html http://localhost:8090/intranet/ http://localhost:8090/intranet/index.html http://localhost:8090/login.html"

Write-Host "===== iBridge Portal - Azure CLI App Registration =====" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if Azure CLI is installed
$azCommand = Get-Command az -ErrorAction SilentlyContinue
if (-not $azCommand) {
    Write-Host "Azure CLI is not installed. Please install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Red
    Write-Host "After installing, rerun this script." -ForegroundColor Red
    exit 1
}

# Step 2: Sign in to Azure
Write-Host "Step 1: Sign in to Azure with your Microsoft 365 admin account..." -ForegroundColor Green
az login

# Step 3: Register the application
Write-Host "`nStep 2: Creating app registration for '$appName'..." -ForegroundColor Green
$appCreationResult = az ad app create --display-name "$appName" --available-to-other-tenants false --web-redirect-uris $redirectUris | ConvertFrom-Json

if (-not $appCreationResult) {
    Write-Host "Error creating application. Please try again or create it manually through the portal." -ForegroundColor Red
    exit 1
}

$appId = $appCreationResult.appId
$objectId = $appCreationResult.id

Write-Host "App created successfully:" -ForegroundColor Green
Write-Host "  - App (Client) ID: $appId" -ForegroundColor White

# Step 4: Enable implicit grant
Write-Host "`nStep 3: Enabling implicit grant flow..." -ForegroundColor Green
az ad app update --id $appId --enable-id-token-issuance true --enable-access-token-issuance true

# Step 5: Add Microsoft Graph permissions
Write-Host "`nStep 4: Adding Microsoft Graph User.Read permission..." -ForegroundColor Green

# Microsoft Graph information
$graphResourceAppId = "00000003-0000-0000-c000-000000000000"  # Microsoft Graph App ID
$userReadPermissionId = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read permission ID

az ad app permission add --id $appId --api $graphResourceAppId --api-permissions "${userReadPermissionId}=Scope"

# Step 6: Grant admin consent
Write-Host "`nStep 5: Granting admin consent..." -ForegroundColor Green
az ad app permission admin-consent --id $appId

# Get tenant ID
$tenantInfo = az account show | ConvertFrom-Json
$tenantId = $tenantInfo.tenantId

# Final summary
Write-Host "`n===== CONFIGURATION COMPLETE =====" -ForegroundColor Yellow
Write-Host "Application Name: $appName" -ForegroundColor White
Write-Host "Application (Client) ID: $appId" -ForegroundColor White
Write-Host "Directory (Tenant) ID: $tenantId" -ForegroundColor White
Write-Host "Redirect URIs configured:" -ForegroundColor White
foreach ($uri in $redirectUris.Split(" ")) {
    Write-Host "  - $uri" -ForegroundColor White
}

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Update your login.html file with the client ID and tenant ID shown above" -ForegroundColor White
Write-Host "2. Start your intranet server with: .\intranet\serve-intranet.ps1" -ForegroundColor White
Write-Host "3. Test authentication at http://localhost:8090/intranet/login.html" -ForegroundColor White
