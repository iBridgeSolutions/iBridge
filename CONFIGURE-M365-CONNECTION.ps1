# CONFIGURE-M365-CONNECTION.ps1
# This script helps configure and test Microsoft 365 connection

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion
Write-Host "`nPowerShell Version: $($psVersion.ToString())" -ForegroundColor Cyan

# Check execution policy
$executionPolicy = Get-ExecutionPolicy
Write-Host "Current Execution Policy: $executionPolicy" -ForegroundColor Cyan

# Function to check if a module is installed
function Test-ModuleInstalled {
    param (
        [string]$ModuleName
    )
    
    $module = Get-Module -Name $ModuleName -ListAvailable
    return ($null -ne $module)
}

# List of required modules
$requiredModules = @(
    "Microsoft.Graph.Authentication",
    "Microsoft.Graph.Users",
    "Microsoft.Graph.Groups",
    "Microsoft.Graph.Identity.DirectoryManagement",
    "Microsoft.Graph.Sites",
    "Microsoft.Graph.Calendar"
)

Write-Host "`nChecking required modules..." -ForegroundColor Yellow
foreach ($module in $requiredModules) {
    $installed = Test-ModuleInstalled -ModuleName $module
    if (-not $installed) {
        Write-Host "$module is not installed. Installing..." -ForegroundColor Cyan
        try {
            Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
            Write-Host "$module installed successfully." -ForegroundColor Green
        } catch {
            Write-Host "Error installing $module : $_" -ForegroundColor Red
        }
    } else {
        Write-Host "$module is already installed." -ForegroundColor Green
        
        # Check for updates
        try {
            $currentVersion = (Get-Module -Name $module -ListAvailable).Version | Sort-Object -Descending | Select-Object -First 1
            Write-Host "  Current version: $currentVersion" -ForegroundColor Gray
        } catch {
            Write-Host "  Could not check version for $module" -ForegroundColor Yellow
        }
    }
}

# Test network connectivity to Microsoft Graph endpoints
Write-Host "`nTesting network connectivity..." -ForegroundColor Yellow

$graphEndpoints = @(
    "graph.microsoft.com",
    "login.microsoftonline.com",
    "account.activedirectory.windowsazure.com"
)

foreach ($endpoint in $graphEndpoints) {
    try {
        $result = Test-NetConnection -ComputerName $endpoint -Port 443
        if ($result.TcpTestSucceeded) {
            Write-Host "Connection to $endpoint successful" -ForegroundColor Green
        } else {
            Write-Host "Connection to $endpoint failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "Error testing connection to $endpoint : $_" -ForegroundColor Red
    }
}

# Attempt to connect to Microsoft Graph
Write-Host "`nAttempting to connect to Microsoft Graph..." -ForegroundColor Yellow

try {
    Connect-MgGraph -Scopes @(
        "User.Read.All",
        "Directory.Read.All",
        "Group.Read.All",
        "Sites.Read.All",
        "Calendars.Read"
    )
    
    $context = Get-MgContext
    if ($null -ne $context) {
        Write-Host "Successfully connected as: $($context.Account)" -ForegroundColor Green
        
        # Get basic user info to verify access
        try {
            $user = Get-MgUser -UserId $context.Account
            Write-Host "Successfully retrieved user information" -ForegroundColor Green
            Write-Host "Display Name: $($user.DisplayName)" -ForegroundColor Cyan
            Write-Host "User Principal Name: $($user.UserPrincipalName)" -ForegroundColor Cyan
            
            # Export connection details for reference
            $connectionInfo = @{
                Account = $context.Account
                TenantId = $context.TenantId
                Scopes = $context.Scopes
                AuthType = $context.AuthType
                Connected = $true
            }
            
            $outputPath = Join-Path $PSScriptRoot "m365-connection-info.json"
            $connectionInfo | ConvertTo-Json | Out-File -FilePath $outputPath
            Write-Host "`nConnection details saved to: $outputPath" -ForegroundColor Green
            
        } catch {
            Write-Host "Error retrieving user information: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Failed to establish Microsoft Graph context" -ForegroundColor Red
    }
} catch {
    Write-Host "Error connecting to Microsoft Graph: $_" -ForegroundColor Red
    
    # Provide troubleshooting guidance
    Write-Host "`nTroubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Ensure you have admin consent for the required permissions" -ForegroundColor Gray
    Write-Host "2. Check if your account has MFA enabled and respond to any prompts" -ForegroundColor Gray
    Write-Host "3. Verify your network can reach Microsoft Graph endpoints" -ForegroundColor Gray
    Write-Host "4. Try running PowerShell as administrator" -ForegroundColor Gray
    Write-Host "5. Check if your organization has any conditional access policies" -ForegroundColor Gray
}

Write-Host "`nConfiguration complete. Check the output above for any issues that need to be resolved." -ForegroundColor Cyan
Write-Host "After resolving any issues, run check-m365-permissions.ps1 again to proceed with permissions analysis." -ForegroundColor Cyan

# Prompt for next steps
Write-Host "`nWould you like to:" -ForegroundColor Yellow
Write-Host "1. Try connecting to Microsoft Graph again" -ForegroundColor Gray
Write-Host "2. View detailed troubleshooting steps" -ForegroundColor Gray
Write-Host "3. Exit" -ForegroundColor Gray

$choice = Read-Host "`nEnter your choice (1-3)"

switch ($choice) {
    "1" { 
        Write-Host "`nRunning check-m365-permissions.ps1..." -ForegroundColor Cyan
        & "$PSScriptRoot\check-m365-permissions.ps1"
    }
    "2" {
        Write-Host "`nDetailed Troubleshooting Steps:" -ForegroundColor Yellow
        Write-Host "1. Check network connectivity:" -ForegroundColor Cyan
        Write-Host "   - Ensure you can reach graph.microsoft.com"
        Write-Host "   - Verify any proxy settings"
        Write-Host "   - Check firewall rules"
        
        Write-Host "`n2. Verify Azure AD App Registration:" -ForegroundColor Cyan
        Write-Host "   - Confirm the application has required permissions"
        Write-Host "   - Check if admin consent is granted"
        Write-Host "   - Verify redirect URIs"
        
        Write-Host "`n3. Check Account Permissions:" -ForegroundColor Cyan
        Write-Host "   - Verify your account has appropriate roles"
        Write-Host "   - Check for any conditional access policies"
        Write-Host "   - Ensure MFA is properly configured"
        
        Write-Host "`n4. Module Configuration:" -ForegroundColor Cyan
        Write-Host "   - Try removing and reinstalling Microsoft.Graph modules"
        Write-Host "   - Clear PowerShell module cache"
        Write-Host "   - Update to latest module versions"
        
        Write-Host "`nWould you like to open the Microsoft Graph permissions documentation?" -ForegroundColor Yellow
        $openDocs = Read-Host "(y/n)"
        if ($openDocs -eq 'y') {
            Start-Process "https://docs.microsoft.com/en-us/graph/permissions-reference"
        }
    }
    "3" { 
        Write-Host "`nExiting..." -ForegroundColor Cyan
        exit 
    }
    default { 
        Write-Host "`nInvalid choice. Exiting..." -ForegroundColor Red
        exit 
    }
}
