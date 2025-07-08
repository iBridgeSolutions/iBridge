# check-m365-permissions.ps1
# Script to check Microsoft 365 permissions and roles for current user
# Requires Microsoft Graph PowerShell SDK

# Check if modules are installed
function Check-ModuleInstalled {
    param (
        [string]$ModuleName
    )
    
    if (Get-Module -ListAvailable -Name $ModuleName) {
        Write-Host "$ModuleName is already installed." -ForegroundColor Green
        return $true
    } else {
        Write-Host "$ModuleName is not installed." -ForegroundColor Yellow
        return $false
    }
}

# Install required modules if not present
function Install-RequiredModules {
    $modules = @(
        "Microsoft.Graph.Authentication",
        "Microsoft.Graph.Users",
        "Microsoft.Graph.Groups",
        "Microsoft.Graph.Identity.DirectoryManagement",
        "Microsoft.Graph.Sites",
        "Microsoft.Graph.Calendar"
    )

    foreach ($module in $modules) {
        if (-not (Check-ModuleInstalled -ModuleName $module)) {
            Write-Host "Installing $module module..." -ForegroundColor Cyan
            Install-Module -Name $module -Scope CurrentUser -Force
        }
    }
}

# Connect to Microsoft Graph with required scopes
function Connect-ToMicrosoftGraph {
    $scopes = @(
        "User.Read.All", 
        "Directory.Read.All", 
        "Group.Read.All", 
        "RoleManagement.Read.Directory",
        "Sites.Read.All",
        "Calendars.Read"
    )
    
    try {
        Write-Host "Connecting to Microsoft Graph API..." -ForegroundColor Cyan
        Connect-MgGraph -Scopes $scopes
        
        # Check if connection was successful
        $context = Get-MgContext
        if ($null -eq $context) {
            Write-Error "Failed to connect to Microsoft Graph."
            return $false
        }
        
        Write-Host "Successfully connected to Microsoft Graph as: $($context.Account)" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Error "Error connecting to Microsoft Graph: $_"
        return $false
    }
}

# Get current user information
function Get-CurrentUserInfo {
    try {
        $currentUser = Get-MgUser -UserId $me.Id -Property Id, DisplayName, UserPrincipalName, Mail, JobTitle, Department
        return $currentUser
    } catch {
        Write-Error "Error retrieving current user info: $_"
        return $null
    }
}

# Get user's directory roles (admin roles)
function Get-UserDirectoryRoles {
    param (
        [string]$UserId
    )
    
    try {
        # Get directory role assignments for the user
        $roleAssignments = Get-MgUserDirectoryRoleAssignment -UserId $UserId
        
        $roles = @()
        foreach ($assignment in $roleAssignments) {
            $role = Get-MgDirectoryRole -DirectoryRoleId $assignment.DirectoryRoleId
            $roles += $role
        }
        
        return $roles
    } catch {
        Write-Error "Error retrieving directory roles: $_"
        return @()
    }
}

# Get user's group memberships
function Get-UserGroupMemberships {
    param (
        [string]$UserId
    )
    
    try {
        $groups = Get-MgUserMemberOf -UserId $UserId
        $groupsInfo = @()
        
        foreach ($group in $groups) {
            if ($group.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.group') {
                $groupsInfo += @{
                    Id = $group.Id
                    DisplayName = $group.AdditionalProperties['displayName']
                    Description = $group.AdditionalProperties['description']
                    GroupTypes = $group.AdditionalProperties['groupTypes']
                }
            }
        }
        
        return $groupsInfo
    } catch {
        Write-Error "Error retrieving group memberships: $_"
        return @()
    }
}

# Check SharePoint site permissions
function Get-SharePointPermissions {
    try {
        # Get root SharePoint site
        $sites = Get-MgSite -Search "*"
        
        $sitePermissions = @()
        foreach ($site in $sites) {
            try {
                # For demonstration - just return site info, you'd need more code to get actual permissions
                $sitePermissions += @{
                    SiteId = $site.Id
                    DisplayName = $site.DisplayName
                    WebUrl = $site.WebUrl
                }
            } catch {
                Write-Warning "Couldn't retrieve permissions for site $($site.DisplayName): $_"
            }
        }
        
        return $sitePermissions
    } catch {
        Write-Error "Error retrieving SharePoint permissions: $_"
        return @()
    }
}

# Check if user can access various M365 services
function Test-ServiceAccess {
    $serviceAccess = @{}
    
    # Test Exchange/Outlook access
    try {
        $calendarView = Get-MgUserCalendarView -UserId $me.Id -StartDateTime (Get-Date).AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ss") -EndDateTime (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ss")
        $serviceAccess["Exchange/Outlook"] = $true
    } catch {
        $serviceAccess["Exchange/Outlook"] = $false
    }
    
    # Test SharePoint access
    try {
        $sites = Get-MgSite -Search "*" -Top 1
        $serviceAccess["SharePoint"] = $true
    } catch {
        $serviceAccess["SharePoint"] = $false
    }
    
    return $serviceAccess
}

# Generate report of permissions and access rights
function Generate-PermissionsReport {
    param (
        $UserInfo,
        $DirectoryRoles,
        $GroupMemberships,
        $SharePointAccess,
        $ServiceAccess
    )
    
    $report = @{
        UserInformation = $UserInfo
        AdminRoles = $DirectoryRoles
        GroupMemberships = $GroupMemberships
        SharePointAccess = $SharePointAccess
        ServiceAccess = $ServiceAccess
        IntegrationPossibilities = @()
    }
    
    # Suggest integrations based on permissions
    if ($ServiceAccess["Exchange/Outlook"]) {
        $report.IntegrationPossibilities += "Calendar integration - Display upcoming meetings on intranet"
        $report.IntegrationPossibilities += "Email notifications - Send notifications from intranet actions"
    }
    
    if ($ServiceAccess["SharePoint"]) {
        $report.IntegrationPossibilities += "Document library - Embed document libraries in intranet"
        $report.IntegrationPossibilities += "News feed - Display company news from SharePoint"
        $report.IntegrationPossibilities += "Team sites - Link to collaborative workspaces"
    }
    
    if ($DirectoryRoles.Count -gt 0) {
        $report.IntegrationPossibilities += "User directory - Show employee profiles and contact information"
        $report.IntegrationPossibilities += "Organization charts - Display company structure"
    }
    
    return $report
}

# Main execution
Clear-Host
Write-Host "Microsoft 365 Permissions Checker" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Check and install required modules
Install-RequiredModules

# Connect to Microsoft Graph
$connected = Connect-ToMicrosoftGraph
if (-not $connected) {
    Write-Error "Failed to connect to Microsoft Graph. Exiting."
    exit 1
}

# Get current user
$me = Get-MgMe
$userInfo = Get-CurrentUserInfo

if ($null -eq $userInfo) {
    Write-Error "Failed to retrieve user information. Exiting."
    exit 1
}

Write-Host "`nChecking permissions and access rights for: $($me.DisplayName) ($($me.UserPrincipalName))" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

# Get directory roles (admin roles)
$directoryRoles = Get-UserDirectoryRoles -UserId $me.Id
Write-Host "`nDirectory Roles (Admin Roles):" -ForegroundColor Yellow
if ($directoryRoles.Count -gt 0) {
    foreach ($role in $directoryRoles) {
        Write-Host " - $($role.DisplayName)" -ForegroundColor White
    }
} else {
    Write-Host " - No admin roles found" -ForegroundColor Gray
}

# Get group memberships
$groupMemberships = Get-UserGroupMemberships -UserId $me.Id
Write-Host "`nGroup Memberships:" -ForegroundColor Yellow
if ($groupMemberships.Count -gt 0) {
    foreach ($group in $groupMemberships) {
        Write-Host " - $($group.DisplayName)" -ForegroundColor White
    }
} else {
    Write-Host " - No group memberships found" -ForegroundColor Gray
}

# Check SharePoint site permissions
$sharePointAccess = Get-SharePointPermissions
Write-Host "`nSharePoint Sites Access:" -ForegroundColor Yellow
if ($sharePointAccess.Count -gt 0) {
    foreach ($site in $sharePointAccess) {
        Write-Host " - $($site.DisplayName) ($($site.WebUrl))" -ForegroundColor White
    }
} else {
    Write-Host " - No SharePoint sites found or accessible" -ForegroundColor Gray
}

# Test service access
$serviceAccess = Test-ServiceAccess
Write-Host "`nService Access:" -ForegroundColor Yellow
foreach ($service in $serviceAccess.Keys) {
    $status = if ($serviceAccess[$service]) { "Access Granted" } else { "No Access" }
    Write-Host " - $service`: $status" -ForegroundColor $(if ($serviceAccess[$service]) { "Green" } else { "Gray" })
}

# Generate complete report
$report = Generate-PermissionsReport -UserInfo $userInfo -DirectoryRoles $directoryRoles -GroupMemberships $groupMemberships -SharePointAccess $sharePointAccess -ServiceAccess $serviceAccess

Write-Host "`nRecommended M365 Integrations for Your Intranet:" -ForegroundColor Yellow
foreach ($suggestion in $report.IntegrationPossibilities) {
    Write-Host " - $suggestion" -ForegroundColor White
}

# Export report to JSON file
$reportPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "m365-permissions-report.json"
$report | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath

Write-Host "`nPermissions report exported to: $reportPath" -ForegroundColor Green
Write-Host "`nDisconnecting from Microsoft Graph..." -ForegroundColor Cyan
Disconnect-MgGraph

Write-Host "`nSee the generated JSON report for detailed information about your permissions and integration possibilities." -ForegroundColor Cyan
