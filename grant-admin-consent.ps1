# Script to check and request admin consent for iBridge Portal Azure AD application
# This script can be used to verify and fix "Need admin approval" errors

# App registration details
$clientId = "6686c610-81cf-4ed7-8241-a91a20f01b06"
$tenantId = "feeb9a78-4032-4b89-ae79-2100a5dc16a8"
$appName = "iBridge Portal"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "           iBridge Portal Admin Consent Helper Tool" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Microsoft Graph PowerShell SDK is installed
$mgGraphModule = Get-Module -ListAvailable -Name Microsoft.Graph.Applications
if ($null -eq $mgGraphModule) {
    Write-Host "The Microsoft Graph PowerShell module is not installed." -ForegroundColor Red
    Write-Host "Installing Microsoft Graph PowerShell module..." -ForegroundColor Yellow
    
    try {
        Install-Module -Name Microsoft.Graph -Force -Scope CurrentUser -AllowClobber
    }
    catch {
        Write-Host "Failed to install Microsoft Graph module." -ForegroundColor Red
        Write-Host "Please run this command manually in PowerShell as administrator:" -ForegroundColor Yellow
        Write-Host "Install-Module -Name Microsoft.Graph -Force -Scope CurrentUser -AllowClobber" -ForegroundColor White
        
        # Provide direct consent URL as fallback
        Write-Host ""
        Write-Host "Alternative: Use the direct admin consent URL in your browser:" -ForegroundColor Yellow
        Write-Host "https://login.microsoftonline.com/$tenantId/adminconsent?client_id=$clientId" -ForegroundColor White
        
        exit 1
    }
}

# Connect to Microsoft Graph with the needed permissions
try {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Blue
    Connect-MgGraph -TenantId $tenantId -Scopes "Application.ReadWrite.All", "Directory.ReadWrite.All"
    
    # Set output type to beta for more detailed application information
    Select-MgProfile -Name "beta"
}
catch {
    Write-Host "Failed to connect to Microsoft Graph. Please check your credentials and try again." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    
    # Provide direct consent URL as fallback
    Write-Host ""
    Write-Host "Alternative: Use the direct admin consent URL in your browser:" -ForegroundColor Yellow
    Write-Host "https://login.microsoftonline.com/$tenantId/adminconsent?client_id=$clientId" -ForegroundColor White
    
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

# Check API permissions and consent status
try {
    Write-Host ""
    Write-Host "Checking API permissions and consent status..." -ForegroundColor Blue
    
    # Get service principal for the application
    $sp = Get-MgServicePrincipal -Filter "appId eq '$clientId'"
    
    if ($null -eq $sp) {
        Write-Host "Service principal for application $clientId not found." -ForegroundColor Red
        Write-Host "This likely means the app hasn't been used in your tenant yet." -ForegroundColor Yellow
        
        # Provide direct consent URL
        Write-Host ""
        Write-Host "To grant admin consent, use this URL in your browser:" -ForegroundColor Yellow
        Write-Host "https://login.microsoftonline.com/$tenantId/adminconsent?client_id=$clientId" -ForegroundColor White
        
        exit 1
    }
    
    # Get app role assignments to check consent status
    $appRoleAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id
    
    # Display current permissions and their consent status
    Write-Host ""
    Write-Host "Current API permissions for $($app.DisplayName):" -ForegroundColor Cyan
    
    $hasConsent = $false
    
    if ($appRoleAssignments.Count -eq 0) {
        Write-Host "No API permissions have been consented." -ForegroundColor Yellow
        $hasConsent = $false
    }
    else {
        foreach ($assignment in $appRoleAssignments) {
            $resourceSp = Get-MgServicePrincipal -ServicePrincipalId $assignment.ResourceId
            $appRoleName = ($resourceSp.AppRoles | Where-Object { $_.Id -eq $assignment.AppRoleId }).Value
            
            Write-Host "✓ $($resourceSp.DisplayName) - $appRoleName (Consented)" -ForegroundColor Green
            $hasConsent = $true
        }
    }
}
catch {
    Write-Host "Error checking permission consent status: $_" -ForegroundColor Red
}

# Provide guidance based on consent status
Write-Host ""
if ($hasConsent) {
    Write-Host "✅ Admin consent appears to be granted for this application." -ForegroundColor Green
    Write-Host "If you're still seeing the ""Need admin approval"" message, try these steps:" -ForegroundColor Cyan
    Write-Host "1. Clear your browser cache and cookies" -ForegroundColor White
    Write-Host "2. Try signing in using an incognito/private browser window" -ForegroundColor White
    Write-Host "3. Wait a few minutes for consent to propagate through Azure AD" -ForegroundColor White
}
else {
    Write-Host "❌ Admin consent has NOT been granted for this application." -ForegroundColor Red
    Write-Host ""
    Write-Host "Would you like to grant admin consent now? (Y/N)" -ForegroundColor Yellow
    $grantConsent = Read-Host
    
    if ($grantConsent -eq "Y" -or $grantConsent -eq "y") {
        Write-Host ""
        Write-Host "Opening admin consent URL in your default browser..." -ForegroundColor Blue
        
        # Construct and open the admin consent URL
        $adminConsentUrl = "https://login.microsoftonline.com/$tenantId/adminconsent?client_id=$clientId"
        Start-Process $adminConsentUrl
        
        Write-Host "✅ Please complete the consent process in your browser." -ForegroundColor Green
        Write-Host "   Sign in with an administrator account when prompted." -ForegroundColor White
    }
    else {
        Write-Host ""
        Write-Host "To grant admin consent later, use this URL in your browser:" -ForegroundColor Yellow
        Write-Host "https://login.microsoftonline.com/$tenantId/adminconsent?client_id=$clientId" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "For more detailed guidance, open the admin consent guide:" -ForegroundColor White
Write-Host "intranet\admin-consent-guide.html" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor White
Read-Host
