# Microsoft 365 Complete Mirror Data Extraction
# This script extracts ALL data from Microsoft 365, Azure AD, Entra ID, and Admin Center
# For exclusive use by: lwandile.gasela@ibridge.co.za (IBDG054)

# Configuration
$adminUsername = "lwandile.gasela@ibridge.co.za"
$employeeCode = "IBDG054"
$outputDir = ".\intranet\data\m365-mirror"
$profilesDir = ".\intranet\images\profiles"
$exclusiveAccess = $true  # Set to true to restrict portal access to just the admin

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "       MICROSOFT 365 COMPLETE MIRROR - DATA EXTRACTION" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script extracts ALL data from Microsoft services to create a complete mirror" -ForegroundColor White
Write-Host "Administrator: $adminUsername ($employeeCode)" -ForegroundColor Yellow
Write-Host ""

# Create timestamp for backup and versioning
$timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")

# Ensure output directories exist
if (-not (Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Host "Created output directory at $outputDir" -ForegroundColor Green
}

if (-not (Test-Path -Path $profilesDir)) {
    New-Item -ItemType Directory -Path $profilesDir -Force | Out-Null
    Write-Host "Created profiles directory at $profilesDir" -ForegroundColor Green
}

# Create subdirectories for organized data
$directories = @(
    "$outputDir\users",
    "$outputDir\groups",
    "$outputDir\applications",
    "$outputDir\policies",
    "$outputDir\devices",
    "$outputDir\licenses",
    "$outputDir\reports",
    "$outputDir\security",
    "$outputDir\compliance",
    "$outputDir\exchange",
    "$outputDir\sharepoint",
    "$outputDir\teams",
    "$outputDir\admin-center"
)

foreach ($dir in $directories) {
    if (-not (Test-Path -Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Install and import required modules
Write-Host "Step 1: Installing and importing required modules..." -ForegroundColor Blue
$modules = @(
    "Microsoft.Graph",
    "AzureAD",
    "MSOnline",
    "ExchangeOnlineManagement",
    "Microsoft.Online.SharePoint.PowerShell",
    "MicrosoftTeams",
    "Microsoft.PowerApps.Administration.PowerShell",
    "Microsoft.PowerApps.PowerShell",
    "Microsoft.Graph.Intune",
    "Microsoft.Graph.Identity.DirectoryManagement",
    "Microsoft.Graph.Users",
    "Microsoft.Graph.Groups",
    "Microsoft.Graph.Authentication",
    "Microsoft.Graph.Identity.Governance",
    "Microsoft.Graph.Identity.SignIns",
    "Microsoft.Graph.Security"
)

foreach ($module in $modules) {
    try {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-Host "  Installing module: $module..." -ForegroundColor Yellow
            Install-Module -Name $module -Force -Scope CurrentUser -AllowClobber -SkipPublisherCheck -ErrorAction SilentlyContinue
        }
        
        # Import only if not already imported
        if (-not (Get-Module -Name $module)) {
            Write-Host "  Importing module: $module..." -ForegroundColor Yellow
            Import-Module -Name $module -Force -DisableNameChecking -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Host "  Warning: Could not install/import module '$module': $_" -ForegroundColor Yellow
        Write-Host "  Some data extraction features may be limited." -ForegroundColor Yellow
    }
}

# Authenticate with various Microsoft services
Write-Host "`nStep 2: Authenticating with Microsoft services..." -ForegroundColor Blue
try {
    # Microsoft Graph authentication with maximum permissions
    Write-Host "  Connecting to Microsoft Graph..." -ForegroundColor White
    Connect-MgGraph -Scopes "Directory.Read.All", "Directory.ReadWrite.All", "Organization.Read.All", 
                    "User.Read.All", "Group.Read.All", "GroupMember.Read.All", "Application.Read.All", 
                    "Policy.Read.All", "AuditLog.Read.All", "Reports.Read.All", "Device.Read.All",
                    "SecurityEvents.Read.All", "IdentityRiskEvent.Read.All", "SecurityActions.Read.All",
                    "Policy.Read.ConditionalAccess", "Agreement.Read.All", "AccessReview.Read.All",
                    "RoleManagement.Read.Directory", "PrivilegedAccess.Read.AzureResources",
                    "TeamSettings.Read.All", "TeamMember.Read.All", "Channel.ReadBasic.All",
                    "Sites.Read.All", "Sites.FullControl.All" -NoWelcome
    
    # Azure AD authentication
    Write-Host "  Connecting to Azure AD..." -ForegroundColor White
    Connect-AzureAD

    # MSOL authentication
    Write-Host "  Connecting to MSOL service..." -ForegroundColor White
    Connect-MsolService
    
    # Exchange Online authentication
    Write-Host "  Connecting to Exchange Online..." -ForegroundColor White
    Connect-ExchangeOnline -ShowBanner:$false
    
    # Get tenant domain for SharePoint
    $tenantInfo = Get-MgOrganization
    if ($tenantInfo) {
        $defaultDomain = $tenantInfo.VerifiedDomains | Where-Object { $_.IsDefault -eq $true } | Select-Object -First 1 -ExpandProperty Name
        if ($defaultDomain) {
            $tenantName = $defaultDomain.Split('.')[0]
            
            # SharePoint Online authentication
            Write-Host "  Connecting to SharePoint Online..." -ForegroundColor White
            Connect-SPOService -Url "https://$tenantName-admin.sharepoint.com"
        }
    }
    
    # Teams authentication
    Write-Host "  Connecting to Microsoft Teams..." -ForegroundColor White
    Connect-MicrosoftTeams
    
    Write-Host "  Authentication successful!" -ForegroundColor Green
}
catch {
    Write-Host "Error connecting to Microsoft services: $_" -ForegroundColor Red
    Write-Host "Trying to continue with limited functionality..." -ForegroundColor Yellow
}

# Begin data extraction
Write-Host "`nStep 3: Extracting comprehensive Microsoft 365 data..." -ForegroundColor Blue

# 1. Extract Organization Data
Write-Host "  Extracting organization data..." -ForegroundColor White
try {
    $orgData = Get-MgOrganization
    $orgData | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\organization.json" -Encoding UTF8
    Write-Host "    - Organization data saved" -ForegroundColor Green
} catch {
    Write-Host "    - Error extracting organization data: $_" -ForegroundColor Red
}

# 2. Extract Users and Directory Data
Write-Host "  Extracting user directory..." -ForegroundColor White
try {
    # Get all users with detailed information
    $users = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, Mail, GivenName, Surname, 
                        JobTitle, Department, OfficeLocation, BusinessPhones, MobilePhone, 
                        AccountEnabled, CreatedDateTime, UserType, AssignedLicenses, UsageLocation,
                        CompanyName, StreetAddress, City, State, PostalCode, Country, Manager
    
    # Enrich with Azure AD data
    $enrichedUsers = $users | ForEach-Object {
        $user = $_
        try {
            # Get Azure AD user for additional properties
            $azureAdUser = Get-AzureADUser -ObjectId $user.UserPrincipalName -ErrorAction SilentlyContinue
            
            # Get manager information if available
            $managerInfo = $null
            if ($user.Manager) {
                $managerInfo = Get-MgUserManager -UserId $user.Id -ErrorAction SilentlyContinue | 
                               Select-Object DisplayName, UserPrincipalName
            }
            
            # Get group memberships
            $groups = Get-MgUserMemberOf -UserId $user.Id -ErrorAction SilentlyContinue | 
                      Where-Object { $_.AdditionalProperties."@odata.type" -eq "#microsoft.graph.group" } |
                      Select-Object -ExpandProperty AdditionalProperties |
                      Select-Object displayName, description

            # Create enriched user object
            [PSCustomObject]@{
                Id = $user.Id
                DisplayName = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                Mail = $user.Mail
                GivenName = $user.GivenName
                Surname = $user.Surname
                JobTitle = $user.JobTitle
                Department = $user.Department
                OfficeLocation = $user.OfficeLocation
                BusinessPhones = $user.BusinessPhones
                MobilePhone = $user.MobilePhone
                AccountEnabled = $user.AccountEnabled
                CreatedDateTime = $user.CreatedDateTime
                UserType = $user.UserType
                LicenseDetails = $azureAdUser.AssignedLicenses | ForEach-Object { 
                    Get-MsolAccountSku | Where-Object { $_.AccountSkuId -eq $_.SkuPartNumber } | Select-Object SkuPartNumber, ConsumedUnits, ActiveUnits 
                }
                UsageLocation = $user.UsageLocation
                CompanyName = $user.CompanyName
                StreetAddress = $user.StreetAddress
                City = $user.City
                State = $user.State
                PostalCode = $user.PostalCode
                Country = $user.Country
                Manager = $managerInfo
                Groups = $groups
                PhotoUrl = "/intranet/images/profiles/$($user.UserPrincipalName.Split('@')[0]).jpg"
                LastSignInDateTime = $azureAdUser.LastDirSyncTime
                AuthenticationMethods = $azureAdUser.StrongAuthenticationMethods
                RiskState = $azureAdUser.RiskState
            }
        }
        catch {
            # Return basic user if enrichment fails
            [PSCustomObject]@{
                Id = $user.Id
                DisplayName = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                Mail = $user.Mail
                GivenName = $user.GivenName
                Surname = $user.Surname
                JobTitle = $user.JobTitle
                Department = $user.Department
                OfficeLocation = $user.OfficeLocation
                BusinessPhones = $user.BusinessPhones
                MobilePhone = $user.MobilePhone
                AccountEnabled = $user.AccountEnabled
                CreatedDateTime = $user.CreatedDateTime
                UserType = $user.UserType
                PhotoUrl = "/intranet/images/profiles/default-profile.jpg"
            }
        }
    }
    
    # Save full user directory
    $enrichedUsers | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\users\all-users.json" -Encoding UTF8
    
    # Save main users.json in intranet data for authentication
    $enrichedUsers | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\intranet\data\users.json" -Encoding UTF8
    
    # Extract profile photos when available
    foreach ($user in $users) {
        try {
            $photoPath = "$profilesDir\$($user.UserPrincipalName.Split('@')[0]).jpg"
            Get-MgUserPhotoContent -UserId $user.Id -OutFile $photoPath -ErrorAction SilentlyContinue
        } catch {
            # Silently continue if no photo available
        }
    }
    
    Write-Host "    - User directory saved with $($enrichedUsers.Count) users" -ForegroundColor Green
} catch {
    Write-Host "    - Error extracting user directory: $_" -ForegroundColor Red
}

# 3. Extract Groups and Team Data
Write-Host "  Extracting groups and teams data..." -ForegroundColor White
try {
    # Get all groups
    $groups = Get-MgGroup -All -Property Id, DisplayName, Description, GroupTypes, 
                         MailEnabled, SecurityEnabled, CreatedDateTime, Visibility, 
                         Mail, ProxyAddresses, MailNickname
    
    # Enrich with members and owners
    $enrichedGroups = $groups | ForEach-Object {
        $group = $_
        try {
            # Get members
            $members = Get-MgGroupMember -GroupId $group.Id -ErrorAction SilentlyContinue | ForEach-Object {
                Get-MgUser -UserId $_.Id -ErrorAction SilentlyContinue | Select-Object DisplayName, UserPrincipalName
            }
            
            # Get owners
            $owners = Get-MgGroupOwner -GroupId $group.Id -ErrorAction SilentlyContinue | ForEach-Object {
                Get-MgUser -UserId $_.Id -ErrorAction SilentlyContinue | Select-Object DisplayName, UserPrincipalName
            }
            
            # Create enriched group object
            [PSCustomObject]@{
                Id = $group.Id
                DisplayName = $group.DisplayName
                Description = $group.Description
                GroupTypes = $group.GroupTypes
                MailEnabled = $group.MailEnabled
                SecurityEnabled = $group.SecurityEnabled
                CreatedDateTime = $group.CreatedDateTime
                Visibility = $group.Visibility
                Mail = $group.Mail
                MailNickname = $group.MailNickname
                Members = $members
                Owners = $owners
                MemberCount = ($members | Measure-Object).Count
            }
        }
        catch {
            # Return basic group if enrichment fails
            [PSCustomObject]@{
                Id = $group.Id
                DisplayName = $group.DisplayName
                Description = $group.Description
                GroupTypes = $group.GroupTypes
                MailEnabled = $group.MailEnabled
                SecurityEnabled = $group.SecurityEnabled
                CreatedDateTime = $group.CreatedDateTime
                Visibility = $group.Visibility
                Mail = $group.Mail
                MailNickname = $group.MailNickname
            }
        }
    }
    
    # Save groups data
    $enrichedGroups | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\groups\all-groups.json" -Encoding UTF8
    Write-Host "    - Groups data saved with $($enrichedGroups.Count) groups" -ForegroundColor Green
    
    # Extract Teams data if available
    try {
        $teams = Get-Team
        $enrichedTeams = $teams | ForEach-Object {
            $team = $_
            try {
                # Get team details
                $teamDetails = Get-Team -GroupId $team.GroupId
                
                # Get team channels
                $channels = Get-TeamChannel -GroupId $team.GroupId
                
                # Get team members
                $teamUsers = Get-TeamUser -GroupId $team.GroupId
                
                [PSCustomObject]@{
                    Id = $team.GroupId
                    DisplayName = $team.DisplayName
                    Description = $team.Description
                    Visibility = $team.Visibility
                    MailNickname = $team.MailNickname
                    Classification = $team.Classification
                    Archived = $team.Archived
                    AllowGiphy = $teamDetails.AllowGiphy
                    AllowStickersAndMemes = $teamDetails.AllowStickersAndMemes
                    AllowCustomMemes = $teamDetails.AllowCustomMemes
                    AllowGuestCreateUpdateChannels = $teamDetails.AllowGuestCreateUpdateChannels
                    AllowGuestDeleteChannels = $teamDetails.AllowGuestDeleteChannels
                    AllowCreateUpdateChannels = $teamDetails.AllowCreateUpdateChannels
                    AllowDeleteChannels = $teamDetails.AllowDeleteChannels
                    AllowAddRemoveApps = $teamDetails.AllowAddRemoveApps
                    AllowCreateUpdateRemoveTabs = $teamDetails.AllowCreateUpdateRemoveTabs
                    AllowCreateUpdateRemoveConnectors = $teamDetails.AllowCreateUpdateRemoveConnectors
                    AllowUserEditMessages = $teamDetails.AllowUserEditMessages
                    AllowUserDeleteMessages = $teamDetails.AllowUserDeleteMessages
                    AllowOwnerDeleteMessages = $teamDetails.AllowOwnerDeleteMessages
                    AllowTeamMentions = $teamDetails.AllowTeamMentions
                    AllowChannelMentions = $teamDetails.AllowChannelMentions
                    ShowInTeamsSearchAndSuggestions = $teamDetails.ShowInTeamsSearchAndSuggestions
                    Channels = $channels | Select-Object DisplayName, Description, MembershipType
                    Members = $teamUsers | Select-Object Name, Role, User
                }
            }
            catch {
                # Return basic team info if details retrieval fails
                [PSCustomObject]@{
                    Id = $team.GroupId
                    DisplayName = $team.DisplayName
                    Description = $team.Description
                    Visibility = $team.Visibility
                    MailNickname = $team.MailNickname
                    Classification = $team.Classification
                    Archived = $team.Archived
                }
            }
        }
        
        # Save teams data
        $enrichedTeams | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\teams\all-teams.json" -Encoding UTF8
        Write-Host "    - Teams data saved with $($enrichedTeams.Count) teams" -ForegroundColor Green
    }
    catch {
        Write-Host "    - Error extracting Teams data: $_" -ForegroundColor Yellow
    }
} catch {
    Write-Host "    - Error extracting groups data: $_" -ForegroundColor Red
}

# 4. Extract Applications and Service Principals
Write-Host "  Extracting applications and service principals..." -ForegroundColor White
try {
    # Get all applications
    $applications = Get-MgApplication -All
    
    # Get all service principals
    $servicePrincipals = Get-MgServicePrincipal -All -Filter "tags/any(t:t eq 'WindowsAzureActiveDirectoryIntegratedApp')"
    
    # Save applications data
    $applications | Select-Object AppId, DisplayName, Description, GroupMembershipClaims, IdentifierUris, PublisherDomain, SignInAudience, Tags, Web, Api, CreatedDateTime | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\applications\all-applications.json" -Encoding UTF8
    
    # Save service principals data
    $servicePrincipals | Select-Object AppId, Id, DisplayName, AccountEnabled, AppRoleAssignmentRequired, Description, AppRoles, Homepage, LogoutUrl, ServicePrincipalType, Tags | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\applications\service-principals.json" -Encoding UTF8
    
    Write-Host "    - Application data saved" -ForegroundColor Green
} catch {
    Write-Host "    - Error extracting applications data: $_" -ForegroundColor Red
}

# 5. Extract Policies and Compliance Data
Write-Host "  Extracting policies and compliance data..." -ForegroundColor White
try {
    # Get conditional access policies
    $conditionalAccessPolicies = Get-MgIdentityConditionalAccessPolicy -All
    $conditionalAccessPolicies | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\policies\conditional-access-policies.json" -Encoding UTF8
    
    # Get authentication methods policies
    $authMethodsPolicies = Get-MgPolicyAuthenticationMethodPolicy
    $authMethodsPolicies | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\policies\authentication-methods-policies.json" -Encoding UTF8
    
    # Get authorization policies
    $authorizationPolicy = Get-MgPolicyAuthorizationPolicy
    $authorizationPolicy | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\policies\authorization-policy.json" -Encoding UTF8
    
    # Get identity security defaults enforcement policy
    $securityDefaultsPolicy = Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy
    $securityDefaultsPolicy | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\policies\security-defaults-policy.json" -Encoding UTF8
    
    # Get token issuance policies
    $tokenIssuancePolicies = Get-MgPolicyTokenIssuancePolicy -All
    $tokenIssuancePolicies | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\policies\token-issuance-policies.json" -Encoding UTF8
    
    # Get token lifetime policies
    $tokenLifetimePolicies = Get-MgPolicyTokenLifetimePolicy -All
    $tokenLifetimePolicies | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\policies\token-lifetime-policies.json" -Encoding UTF8
    
    # Get admin consent request policies
    $adminConsentRequestPolicies = Get-MgPolicyAdminConsentRequestPolicy
    $adminConsentRequestPolicies | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\policies\admin-consent-request-policies.json" -Encoding UTF8
    
    Write-Host "    - Policies data saved" -ForegroundColor Green
} catch {
    Write-Host "    - Error extracting policies data: $_" -ForegroundColor Red
}

# 6. Extract Role Information
Write-Host "  Extracting role information..." -ForegroundColor White
try {
    # Get directory roles
    $directoryRoles = Get-MgDirectoryRole -All
    $enrichedRoles = $directoryRoles | ForEach-Object {
        $role = $_
        try {
            # Get role members
            $members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -ErrorAction SilentlyContinue | ForEach-Object {
                Get-MgUser -UserId $_.Id -ErrorAction SilentlyContinue | Select-Object DisplayName, UserPrincipalName
            }
            
            [PSCustomObject]@{
                Id = $role.Id
                DisplayName = $role.DisplayName
                Description = $role.Description
                RoleTemplateId = $role.RoleTemplateId
                Members = $members
            }
        }
        catch {
            [PSCustomObject]@{
                Id = $role.Id
                DisplayName = $role.DisplayName
                Description = $role.Description
                RoleTemplateId = $role.RoleTemplateId
                Members = @()
            }
        }
    }
    
    $enrichedRoles | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\admin-center\directory-roles.json" -Encoding UTF8
    Write-Host "    - Role information saved" -ForegroundColor Green
} catch {
    Write-Host "    - Error extracting role information: $_" -ForegroundColor Red
}

# 7. Extract Licensing Information
Write-Host "  Extracting licensing information..." -ForegroundColor White
try {
    # Get license details
    $licenseDetails = Get-MsolAccountSku
    $licenseDetails | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\licenses\license-details.json" -Encoding UTF8
    
    # Get user license assignments
    $userLicenses = @()
    foreach ($user in $enrichedUsers) {
        try {
            $msUser = Get-MsolUser -UserPrincipalName $user.UserPrincipalName -ErrorAction SilentlyContinue
            if ($msUser -and $msUser.Licenses) {
                $userLicenses += [PSCustomObject]@{
                    UserPrincipalName = $user.UserPrincipalName
                    DisplayName = $user.DisplayName
                    Licenses = $msUser.Licenses | ForEach-Object { 
                        [PSCustomObject]@{
                            AccountSkuId = $_.AccountSkuId
                            ServiceStatus = $_.ServiceStatus | ForEach-Object {
                                [PSCustomObject]@{
                                    ServicePlan = $_.ServicePlan.ServiceName
                                    ProvisioningStatus = $_.ProvisioningStatus
                                }
                            }
                        }
                    }
                }
            }
        }
        catch {
            # Skip user if error occurs
        }
    }
    
    $userLicenses | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\licenses\user-licenses.json" -Encoding UTF8
    Write-Host "    - Licensing information saved" -ForegroundColor Green
} catch {
    Write-Host "    - Error extracting licensing information: $_" -ForegroundColor Red
}

# 8. Extract Device Information
Write-Host "  Extracting device information..." -ForegroundColor White
try {
    # Get devices
    $devices = Get-MgDevice -All
    $devices | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\devices\all-devices.json" -Encoding UTF8
    Write-Host "    - Device information saved" -ForegroundColor Green
} catch {
    Write-Host "    - Error extracting device information: $_" -ForegroundColor Red
}

# 9. Extract Exchange Online Data
Write-Host "  Extracting Exchange Online data..." -ForegroundColor White
try {
    # Get mailboxes
    $mailboxes = Get-EXOMailbox -ResultSize Unlimited | Select-Object DisplayName, UserPrincipalName, RecipientTypeDetails, PrimarySmtpAddress, IsMailboxEnabled
    $mailboxes | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\exchange\mailboxes.json" -Encoding UTF8
    
    # Get distribution groups
    $distributionGroups = Get-DistributionGroup -ResultSize Unlimited | Select-Object DisplayName, PrimarySmtpAddress, GroupType, MemberJoinRestriction, MemberDepartRestriction
    $distributionGroups | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\exchange\distribution-groups.json" -Encoding UTF8
    
    # Get transport rules
    $transportRules = Get-TransportRule | Select-Object Name, State, Mode, Priority, Description
    $transportRules | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\exchange\transport-rules.json" -Encoding UTF8
    
    # Get accepted domains
    $acceptedDomains = Get-AcceptedDomain | Select-Object DomainName, DomainType, Default
    $acceptedDomains | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\exchange\accepted-domains.json" -Encoding UTF8
    
    Write-Host "    - Exchange Online data saved" -ForegroundColor Green
} catch {
    Write-Host "    - Error extracting Exchange Online data: $_" -ForegroundColor Red
}

# 10. Extract SharePoint Online Data
Write-Host "  Extracting SharePoint Online data..." -ForegroundColor White
try {
    # Get SharePoint sites
    $spSites = Get-SPOSite -Limit All | Select-Object Url, Title, Template, SharingCapability, StorageQuota, Status
    $spSites | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\sharepoint\sites.json" -Encoding UTF8
    
    # Get tenant settings
    $spTenantSettings = Get-SPOTenant | Select-Object SharingCapability, DefaultSharingLinkType, FileAnonymousLinkType, FolderAnonymousLinkType, DisableCompanyWideSharingLinks
    $spTenantSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\sharepoint\tenant-settings.json" -Encoding UTF8
    
    Write-Host "    - SharePoint Online data saved" -ForegroundColor Green
} catch {
    Write-Host "    - Error extracting SharePoint Online data: $_" -ForegroundColor Red
}

# 11. Extract Security and Compliance Data
Write-Host "  Extracting security and compliance data..." -ForegroundColor White
try {
    # Get secure scores
    $secureScores = Get-MgSecuritySecureScore -Top 5
    $secureScores | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\security\secure-scores.json" -Encoding UTF8
    
    # Get alerts
    $alerts = Get-MgSecurityAlert -Top 100
    $alerts | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\security\alerts.json" -Encoding UTF8
    
    Write-Host "    - Security and compliance data saved" -ForegroundColor Green
} catch {
    Write-Host "    - Error extracting security and compliance data: $_" -ForegroundColor Red
}

# Create mirror configuration file that documents all the mirrored features
$mirrorConfig = @{
    dateExtracted = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    exclusiveUser = $adminUsername
    exclusiveEmployeeCode = $employeeCode
    restrictedAccess = $exclusiveAccess
    featuresExtracted = @(
        "Microsoft 365 Users & Groups",
        "Azure AD/Entra ID Directory",
        "Microsoft Teams",
        "Exchange Online",
        "SharePoint Online",
        "Applications & Service Principals",
        "Policies & Compliance",
        "Security & Access Management",
        "Directory Roles",
        "Licensing",
        "Device Management"
    )
    portalCapabilities = @(
        "User Management",
        "Group Management",
        "Role Assignment",
        "License Management",
        "Policy Configuration",
        "Security Monitoring",
        "Compliance Reporting",
        "Application Management",
        "Device Management",
        "Exchange Administration",
        "SharePoint Administration",
        "Teams Administration"
    )
}

$mirrorConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\mirror-configuration.json" -Encoding UTF8
$mirrorConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\intranet\data\mirror-configuration.json" -Encoding UTF8

Write-Host "`nData extraction complete! Portal now has all data from Microsoft services." -ForegroundColor Green
Write-Host "Extracted data is available in: $outputDir" -ForegroundColor Cyan
Write-Host "`nYou can now access the full Microsoft 365 mirror at:" -ForegroundColor White
Write-Host "http://localhost:8090/intranet/" -ForegroundColor Yellow
Write-Host "`nUse your employee code IBDG054 or Microsoft account lwandile.gasela@ibridge.co.za to login." -ForegroundColor White
