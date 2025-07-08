# Microsoft 365 Complete Data Extraction for Portal Mirroring
# This script extracts comprehensive data from Microsoft 365, Azure AD, and Microsoft Admin Center
# For use by: lwandile.gasela@ibridge.co.za (IBDG054)

# Configuration
$adminUsername = "lwandile.gasela@ibridge.co.za"
$employeeCode = "IBDG054"
$outputDir = ".\intranet\data\m365-mirror"
$profilesDir = ".\intranet\images\profiles"
$exclusiveAccess = $true  # Set to true to restrict portal access to just the admin

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "       Microsoft 365/Azure/Entra ID Complete Data Extractor" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will extract comprehensive data from Microsoft 365 admin centers" -ForegroundColor White
Write-Host "Administrator: $adminUsername ($employeeCode)" -ForegroundColor Yellow
Write-Host ""

# Ensure output directories exist
if (-not (Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Host "Created output directory at $outputDir" -ForegroundColor Green
}

if (-not (Test-Path -Path $profilesDir)) {
    New-Item -ItemType Directory -Path $profilesDir -Force | Out-Null
    Write-Host "Created profiles directory at $profilesDir" -ForegroundColor Green
}

# Helper function to create timestamp for filenames
function Get-Timestamp {
    return (Get-Date).ToString("yyyyMMdd-HHmmss")
}

# Install and import required modules
Write-Host "Step 1: Installing and importing required modules..." -ForegroundColor Blue
$modules = @(
    "Microsoft.Graph",
    "AzureAD",
    "MSOnline",
    "ExchangeOnlineManagement",
    "Microsoft.Online.SharePoint.PowerShell",
    "MicrosoftTeams"
)

foreach ($module in $modules) {
    try {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-Host "  Installing module: $module..." -ForegroundColor Yellow
            Install-Module -Name $module -Force -Scope CurrentUser -AllowClobber -SkipPublisherCheck
        }
        
        # Import only if not already imported
        if (-not (Get-Module -Name $module)) {
            Write-Host "  Importing module: $module..." -ForegroundColor Yellow
            Import-Module -Name $module -Force -DisableNameChecking
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
    # Microsoft Graph authentication
    Write-Host "  Connecting to Microsoft Graph..." -ForegroundColor White
    Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All", "Organization.Read.All", "Group.Read.All", "Application.Read.All", "Policy.Read.All" -NoWelcome
    
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
    Write-Host "  Error during authentication: $_" -ForegroundColor Red
    Write-Host "  Continuing with limited functionality..." -ForegroundColor Yellow
}

# Function to safely extract data with error handling
function Extract-SafeData {
    param (
        [string]$DataType,
        [scriptblock]$Extraction,
        [string]$OutputFile
    )
    
    Write-Host "  Extracting $DataType data..." -ForegroundColor White
    try {
        $data = & $Extraction
        if ($null -ne $data) {
            $data | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\$OutputFile" -Encoding UTF8
            Write-Host "    ✓ Saved $DataType data to $outputDir\$OutputFile" -ForegroundColor Green
            return $data
        }
        else {
            Write-Host "    ! No $DataType data found" -ForegroundColor Yellow
            return $null
        }
    }
    catch {
        Write-Host "    ✗ Error extracting $DataType data: $_" -ForegroundColor Red
        return $null
    }
}

# Step 3: Extract organizational data
Write-Host "`nStep 3: Extracting organizational data..." -ForegroundColor Blue
$orgData = Extract-SafeData -DataType "Organization" -OutputFile "organization.json" -Extraction {
    $org = Get-MgOrganization
    if ($org) {
        return @{
            id = $org.Id
            displayName = $org.DisplayName
            verifiedDomains = $org.VerifiedDomains | ForEach-Object {
                @{
                    name = $_.Name
                    isDefault = $_.IsDefault
                    isInitial = $_.IsInitial
                    type = $_.Type
                }
            }
            street = $org.Street
            city = $org.City
            state = $org.State
            postalCode = $org.PostalCode
            countryOrRegion = $org.CountryOrRegion
            businessPhones = $org.BusinessPhones
            technicalNotificationEmails = $org.TechnicalNotificationMails
            securityComplianceNotificationEmails = $org.SecurityComplianceNotificationMails
            privacyProfile = $org.PrivacyProfile
            securityComplianceCenter = $org.SecurityComplianceCenter
            logoUrl = "https://image-placeholder.com/logo.png" # Placeholder, actual logo extraction is complex
        }
    }
}

# Step 4: Extract user data
Write-Host "`nStep 4: Extracting user data..." -ForegroundColor Blue

# Get all users from Microsoft Graph
$users = Extract-SafeData -DataType "Users" -OutputFile "users.json" -Extraction {
    Get-MgUser -All -Property Id, DisplayName, GivenName, Surname, UserPrincipalName, Mail, JobTitle, 
                Department, OfficeLocation, MobilePhone, BusinessPhones, AccountEnabled, 
                UsageLocation, PreferredLanguage, UserType, EmployeeId, EmployeeHireDate | 
        ForEach-Object {
            @{
                id = $_.Id
                displayName = $_.DisplayName
                givenName = $_.GivenName
                surname = $_.Surname
                userPrincipalName = $_.UserPrincipalName
                mail = $_.Mail
                jobTitle = $_.JobTitle
                department = $_.Department
                officeLocation = $_.OfficeLocation
                mobilePhone = $_.MobilePhone
                businessPhones = $_.BusinessPhones
                accountEnabled = $_.AccountEnabled
                usageLocation = $_.UsageLocation
                preferredLanguage = $_.PreferredLanguage
                userType = $_.UserType
                employeeId = $_.EmployeeId
                employeeHireDate = $_.EmployeeHireDate
                hasPhoto = $false # Will update below
            }
        }
}

# Step 5: Extract user photos
Write-Host "`nStep 5: Extracting user photos..." -ForegroundColor Blue
if ($null -ne $users) {
    foreach ($user in $users) {
        $userPrincipalName = $user.userPrincipalName
        $safeName = $userPrincipalName -replace '[^a-zA-Z0-9]', '-'
        $photoPath = "$profilesDir\$safeName.jpg"
        
        try {
            Write-Host "  Retrieving photo for $userPrincipalName..." -ForegroundColor White
            
            # Attempt to get photo via Graph API
            $photo = Get-MgUserPhotoContent -UserId $user.id -ErrorAction SilentlyContinue
            
            if ($null -ne $photo) {
                [System.IO.File]::WriteAllBytes($photoPath, $photo)
                Write-Host "    ✓ Saved photo to $photoPath" -ForegroundColor Green
                $user.hasPhoto = $true
            }
            else {
                # Generate placeholder image
                $nameParts = $user.displayName -split ' '
                $initials = $nameParts | ForEach-Object { $_.Substring(0, 1) } | Join-String
                $avatarUrl = "https://ui-avatars.com/api/?name=$($user.displayName -replace ' ', '+')&background=0D8ABC&color=fff&size=256"
                
                Invoke-WebRequest -Uri $avatarUrl -OutFile $photoPath
                Write-Host "    ✓ Created placeholder photo for $userPrincipalName" -ForegroundColor Yellow
                $user.hasPhoto = $true
            }
        }
        catch {
            Write-Host "    ✗ Error retrieving photo for $userPrincipalName: $_" -ForegroundColor Red
        }
    }
    
    # Update users file with hasPhoto property
    $users | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\users.json" -Encoding UTF8
}

# Step 6: Extract groups and teams
Write-Host "`nStep 6: Extracting groups and teams..." -ForegroundColor Blue
Extract-SafeData -DataType "Groups" -OutputFile "groups.json" -Extraction {
    Get-MgGroup -All -Property Id, DisplayName, Description, GroupTypes, Mail, IsAssignableToRole, SecurityEnabled, Visibility | ForEach-Object {
        @{
            id = $_.Id
            displayName = $_.DisplayName
            description = $_.Description
            groupTypes = $_.GroupTypes
            mail = $_.Mail
            isAssignableToRole = $_.IsAssignableToRole
            securityEnabled = $_.SecurityEnabled
            visibility = $_.Visibility
            members = @(Get-MgGroupMember -GroupId $_.Id | ForEach-Object { $_.Id })
        }
    }
}

# Extract Teams data if available
try {
    Extract-SafeData -DataType "Teams" -OutputFile "teams.json" -Extraction {
        Get-Team | ForEach-Object {
            $team = $_
            @{
                id = $team.GroupId
                displayName = $team.DisplayName
                description = $team.Description
                visibility = $team.Visibility
                channels = @(Get-TeamChannel -GroupId $team.GroupId | ForEach-Object {
                    @{
                        id = $_.Id
                        displayName = $_.DisplayName
                        description = $_.Description
                        membershipType = $_.MembershipType
                    }
                })
            }
        }
    }
}
catch {
    Write-Host "  Error extracting Teams data: $_" -ForegroundColor Red
}

# Step 7: Extract SharePoint sites
Write-Host "`nStep 7: Extracting SharePoint sites..." -ForegroundColor Blue
try {
    Extract-SafeData -DataType "SharePoint sites" -OutputFile "sharepoint-sites.json" -Extraction {
        Get-SPOSite -Limit All | ForEach-Object {
            @{
                url = $_.Url
                title = $_.Title
                owner = $_.Owner
                storageUsed = $_.StorageUsageCurrent
                lastModified = $_.LastContentModifiedDate
                template = $_.Template
                webCount = $_.WebsCount
            }
        }
    }
}
catch {
    Write-Host "  Error extracting SharePoint sites: $_" -ForegroundColor Red
}

# Step 8: Extract applications and service principals
Write-Host "`nStep 8: Extracting applications and service principals..." -ForegroundColor Blue
Extract-SafeData -DataType "Applications" -OutputFile "applications.json" -Extraction {
    Get-MgApplication -All | ForEach-Object {
        @{
            id = $_.Id
            appId = $_.AppId
            displayName = $_.DisplayName
            description = $_.Description
            publisherDomain = $_.PublisherDomain
            signInAudience = $_.SignInAudience
            webRedirectUris = $_.Web.RedirectUris
        }
    }
}

Extract-SafeData -DataType "Service Principals" -OutputFile "service-principals.json" -Extraction {
    Get-MgServicePrincipal -All -Top 50 | ForEach-Object {
        @{
            id = $_.Id
            appId = $_.AppId
            displayName = $_.DisplayName
            description = $_.Description
            servicePrincipalType = $_.ServicePrincipalType
            appRoles = $_.AppRoles | ForEach-Object {
                @{
                    id = $_.Id
                    displayName = $_.DisplayName
                    description = $_.Description
                    value = $_.Value
                }
            }
        }
    }
}

# Step 9: Extract roles and role assignments
Write-Host "`nStep 9: Extracting roles and assignments..." -ForegroundColor Blue
Extract-SafeData -DataType "Roles" -OutputFile "roles.json" -Extraction {
    Get-MgDirectoryRole -All | ForEach-Object {
        $role = $_
        @{
            id = $role.Id
            displayName = $role.DisplayName
            description = $role.Description
            members = @(Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id | ForEach-Object { 
                $member = $_
                $user = Get-MgUser -UserId $member.Id -ErrorAction SilentlyContinue
                if ($user) {
                    @{
                        id = $member.Id
                        displayName = $user.DisplayName
                        userPrincipalName = $user.UserPrincipalName
                        type = "User"
                    }
                }
                else {
                    $sp = Get-MgServicePrincipal -ServicePrincipalId $member.Id -ErrorAction SilentlyContinue
                    if ($sp) {
                        @{
                            id = $member.Id
                            displayName = $sp.DisplayName
                            appId = $sp.AppId
                            type = "ServicePrincipal"
                        }
                    }
                    else {
                        @{
                            id = $member.Id
                            type = "Unknown"
                        }
                    }
                }
            })
        }
    }
}

# Step 10: Extract policies
Write-Host "`nStep 10: Extracting policies..." -ForegroundColor Blue
Extract-SafeData -DataType "Identity Protection Policies" -OutputFile "identity-protection-policies.json" -Extraction {
    Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy | ForEach-Object {
        @{
            id = $_.Id
            displayName = $_.DisplayName
            description = $_.Description
            isEnabled = $_.IsEnabled
        }
    }
}

# Step 11: Extract audit logs (limited sample)
Write-Host "`nStep 11: Extracting audit logs (limited sample)..." -ForegroundColor Blue
try {
    Extract-SafeData -DataType "Audit Logs" -OutputFile "audit-logs-sample.json" -Extraction {
        # Get a limited sample of audit logs (last 24 hours, max 100 entries)
        $date = (Get-Date).AddDays(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
        Get-MgAuditLogSignIn -Top 100 -Filter "createdDateTime ge $date" | ForEach-Object {
            @{
                id = $_.Id
                createdDateTime = $_.CreatedDateTime
                userPrincipalName = $_.UserPrincipalName
                appDisplayName = $_.AppDisplayName
                ipAddress = $_.IpAddress
                clientAppUsed = $_.ClientAppUsed
                status = @{
                    errorCode = $_.Status.ErrorCode
                    failureReason = $_.Status.FailureReason
                }
                location = @{
                    city = $_.Location.City
                    state = $_.Location.State
                    countryOrRegion = $_.Location.CountryOrRegion
                }
                deviceDetail = @{
                    browser = $_.DeviceDetail.Browser
                    operatingSystem = $_.DeviceDetail.OperatingSystem
                }
            }
        }
    }
}
catch {
    Write-Host "  Error extracting audit logs: $_" -ForegroundColor Red
}

# Step 12: Extract licenses and subscriptions
Write-Host "`nStep 12: Extracting licenses and subscriptions..." -ForegroundColor Blue
Extract-SafeData -DataType "Subscribed SKUs" -OutputFile "subscribed-skus.json" -Extraction {
    Get-MgSubscribedSku | ForEach-Object {
        @{
            id = $_.Id
            skuId = $_.SkuId
            skuPartNumber = $_.SkuPartNumber
            appliesTo = $_.AppliesTo
            capabilityStatus = $_.CapabilityStatus
            consumedUnits = $_.ConsumedUnits
            prepaidUnits = @{
                enabled = $_.PrepaidUnits.Enabled
                suspended = $_.PrepaidUnits.Suspended
                warning = $_.PrepaidUnits.Warning
            }
            servicePlans = $_.ServicePlans | ForEach-Object {
                @{
                    servicePlanId = $_.ServicePlanId
                    servicePlanName = $_.ServicePlanName
                    provisioningStatus = $_.ProvisioningStatus
                    appliesTo = $_.AppliesTo
                }
            }
        }
    }
}

# Step 13: Extract Exchange mailbox data
Write-Host "`nStep 13: Extracting Exchange mailbox data..." -ForegroundColor Blue
try {
    Extract-SafeData -DataType "Mailboxes" -OutputFile "mailboxes.json" -Extraction {
        Get-Mailbox -ResultSize 100 | ForEach-Object {
            @{
                displayName = $_.DisplayName
                userPrincipalName = $_.UserPrincipalName
                primarySmtpAddress = $_.PrimarySmtpAddress
                recipientType = $_.RecipientType
                recipientTypeDetails = $_.RecipientTypeDetails
                isMailboxEnabled = $_.IsMailboxEnabled
                isResource = $_.IsResource
                isShared = $_.IsShared
                emailAddresses = $_.EmailAddresses
                forwardingAddress = $_.ForwardingAddress
                forwardingSmtpAddress = $_.ForwardingSmtpAddress
                litigationHoldEnabled = $_.LitigationHoldEnabled
                retentionPolicy = $_.RetentionPolicy
            }
        }
    }
}
catch {
    Write-Host "  Error extracting Exchange mailbox data: $_" -ForegroundColor Red
}

# Step 14: Generate departments summary
Write-Host "`nStep 14: Generating departments summary..." -ForegroundColor Blue
if ($null -ne $users) {
    $departments = $users | Where-Object { $null -ne $_.department -and $_.department -ne "" } | Group-Object -Property department | ForEach-Object {
        $departmentName = $_.Name
        $departmentMembers = $_.Group | ForEach-Object { $_.id }
        
        @{
            name = $departmentName
            memberCount = $_.Count
            members = $departmentMembers
        }
    }
    
    if ($departments) {
        $departments | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir\departments.json" -Encoding UTF8
        Write-Host "  ✓ Generated departments summary at $outputDir\departments.json" -ForegroundColor Green
    }
    else {
        Write-Host "  ! No department data could be generated" -ForegroundColor Yellow
    }
}

# Step 15: Create portal settings file
Write-Host "`nStep 15: Creating portal settings file..." -ForegroundColor Blue
try {
    # Update timestamp for settings
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $settings = @{
        allowedDomains = @("ibridge.co.za")
        dateUpdated = $timestamp
        editorUsers = @("$adminUsername")
        adminUsers = @("$adminUsername")
        useM365Data = $true
        devMode = $false
        exclusiveAccess = $exclusiveAccess
        employeeCodeLogin = $true
        adminEmployeeCode = $employeeCode
        companyName = if ($orgData -and $orgData.displayName) { $orgData.displayName } else { "iBridge Contact Solutions" }
        intranetTitle = if ($orgData -and $orgData.displayName) { "$($orgData.displayName) Staff Portal" } else { "iBridge Staff Portal" }
        companyDomain = if ($orgData -and $orgData.verifiedDomains -and $orgData.verifiedDomains.Count -gt 0) {
            ($orgData.verifiedDomains | Where-Object { $_.isDefault -eq $true } | Select-Object -First 1).name 
        } else { "ibridge.co.za" }
        microsoftConfig = @{
            adminEmail = $adminUsername
            tenantId = if ($tenantInfo) { $tenantInfo.Id } else { "feeb9a78-4032-4b89-ae79-2100a5dc16a8" }
            clientId = "6686c610-81cf-4ed7-8241-a91a20f01b06"
            redirectUri = "http://localhost:8090/auth-callback.html"
            scopes = @(
                "User.Read",
                "User.ReadBasic.All", 
                "Directory.Read.All",
                "Organization.Read.All",
                "Group.Read.All"
            )
        }
        features = @{
            calendar = $true
            adminPanel = $true
            helpdesk = $true
            news = $true
            companyProfile = $true
            documents = $true
            directory = $true
            microsoftIntegration = $true
            exchangeIntegration = $true
            teamsIntegration = $true
            sharepointIntegration = $true
            securityDashboard = $true
            userManagement = $true
            licenseManagement = $true
            auditLogs = $true
            employeeCode = $true
        }
    }
    
    # Save settings to file
    $settingsJson = $settings | ConvertTo-Json -Depth 10
    $settingsJson | Out-File -FilePath "$outputDir\settings.json" -Encoding UTF8
    $settingsJson | Out-File -FilePath ".\intranet\data\settings.json" -Encoding UTF8
    Write-Host "  ✓ Created portal settings at $outputDir\settings.json" -ForegroundColor Green
    Write-Host "  ✓ Updated main settings file at .\intranet\data\settings.json" -ForegroundColor Green
}
catch {
    Write-Host "  Error creating portal settings: $_" -ForegroundColor Red
}

# Step 16: Copy data files to main intranet directory
Write-Host "`nStep 16: Copying essential data files to intranet directory..." -ForegroundColor Blue
$essentialFiles = @("users.json", "organization.json", "departments.json")

foreach ($file in $essentialFiles) {
    $sourcePath = "$outputDir\$file"
    $destPath = ".\intranet\data\$file"
    
    if (Test-Path -Path $sourcePath) {
        try {
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            Write-Host "  ✓ Copied $file to $destPath" -ForegroundColor Green
        }
        catch {
            Write-Host "  ✗ Error copying $file: $_" -ForegroundColor Red
        }
    }
}

# Step 17: Create employee code mapping file
Write-Host "`nStep 17: Creating employee code mapping file..." -ForegroundColor Blue
try {
    $employeeCodes = @{
        mappings = @()
    }
    
    if ($null -ne $users) {
        foreach ($user in $users) {
            # Use existing employeeId if available, otherwise generate a synthetic one
            $code = if ($user.employeeId) { $user.employeeId } else { "IBDG" + (Get-Random -Minimum 100 -Maximum 999).ToString() }
            
            # Special case for the admin user
            if ($user.userPrincipalName -eq $adminUsername) {
                $code = $employeeCode
            }
            
            $employeeCodes.mappings += @{
                userPrincipalName = $user.userPrincipalName
                employeeCode = $code
            }
        }
        
        $employeeCodes | ConvertTo-Json -Depth 4 | Out-File -FilePath "$outputDir\employee-codes.json" -Encoding UTF8
        $employeeCodes | ConvertTo-Json -Depth 4 | Out-File -FilePath ".\intranet\data\employee-codes.json" -Encoding UTF8
        Write-Host "  ✓ Created employee code mappings at $outputDir\employee-codes.json" -ForegroundColor Green
        Write-Host "  ✓ Created employee code mappings at .\intranet\data\employee-codes.json" -ForegroundColor Green
    }
    else {
        Write-Host "  ! Could not create employee code mappings - no user data available" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "  ✗ Error creating employee code mappings: $_" -ForegroundColor Red
}

# Step 18: Create access control file
Write-Host "`nStep 18: Creating access control file..." -ForegroundColor Blue
try {
    $accessControl = @{
        restrictedAccess = $exclusiveAccess
        allowedUsers = @($adminUsername)
        allowedEmployeeCodes = @($employeeCode)
        lastUpdated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        accessPolicy = "exclusive" # Options: "exclusive", "domain", "open"
    }
    
    $accessControl | ConvertTo-Json -Depth 4 | Out-File -FilePath "$outputDir\access-control.json" -Encoding UTF8
    $accessControl | ConvertTo-Json -Depth 4 | Out-File -FilePath ".\intranet\data\access-control.json" -Encoding UTF8
    Write-Host "  ✓ Created access control configuration at $outputDir\access-control.json" -ForegroundColor Green
    Write-Host "  ✓ Created access control configuration at .\intranet\data\access-control.json" -ForegroundColor Green
}
catch {
    Write-Host "  ✗ Error creating access control configuration: $_" -ForegroundColor Red
}

# Step 19: Create feature definition file
Write-Host "`nStep 19: Creating feature definition file..." -ForegroundColor Blue
try {
    $features = @{
        core = @(
            @{
                id = "dashboard"
                name = "Dashboard"
                icon = "home"
                enabled = $true
                adminOnly = $false
                description = "Overview of important information and activities"
            },
            @{
                id = "directory"
                name = "Staff Directory"
                icon = "people"
                enabled = $true
                adminOnly = $false
                description = "Browse and search for staff members"
            },
            @{
                id = "departments"
                name = "Departments"
                icon = "business"
                enabled = $true
                adminOnly = $false
                description = "View department structure and members"
            }
        )
        admin = @(
            @{
                id = "admin-dashboard"
                name = "Admin Dashboard"
                icon = "admin_panel_settings"
                enabled = $true
                adminOnly = $true
                description = "Administrative controls and settings"
            },
            @{
                id = "user-management"
                name = "User Management"
                icon = "manage_accounts"
                enabled = $true
                adminOnly = $true
                description = "Manage users, permissions and profiles"
            },
            @{
                id = "security-dashboard"
                name = "Security Dashboard"
                icon = "security"
                enabled = $true
                adminOnly = $true
                description = "Security settings and monitoring"
            }
        )
        microsoft = @(
            @{
                id = "exchange"
                name = "Exchange & Email"
                icon = "email"
                enabled = $true
                adminOnly = $false
                description = "Email, calendar and contacts integration"
            },
            @{
                id = "teams"
                name = "Teams Integration"
                icon = "groups"
                enabled = $true
                adminOnly = $false
                description = "Microsoft Teams integration"
            },
            @{
                id = "sharepoint"
                name = "SharePoint"
                icon = "folder_shared"
                enabled = $true
                adminOnly = $false
                description = "Document management and sharing"
            },
            @{
                id = "onedrive"
                name = "OneDrive"
                icon = "cloud"
                enabled = $true
                adminOnly = $false
                description = "Personal file storage integration"
            }
        )
        custom = @(
            @{
                id = "employee-code-login"
                name = "Employee Code Login"
                icon = "badge"
                enabled = $true
                adminOnly = $false
                description = "Login using employee code"
            },
            @{
                id = "advanced-reporting"
                name = "Advanced Reporting"
                icon = "assessment"
                enabled = $true
                adminOnly = $true
                description = "Advanced reports and analytics"
            }
        )
    }
    
    $features | ConvertTo-Json -Depth 6 | Out-File -FilePath "$outputDir\features.json" -Encoding UTF8
    $features | ConvertTo-Json -Depth 6 | Out-File -FilePath ".\intranet\data\features.json" -Encoding UTF8
    Write-Host "  ✓ Created feature definitions at $outputDir\features.json" -ForegroundColor Green
    Write-Host "  ✓ Created feature definitions at .\intranet\data\features.json" -ForegroundColor Green
}
catch {
    Write-Host "  ✗ Error creating feature definitions: $_" -ForegroundColor Red
}

# Disconnect from services
Write-Host "`nDisconnecting from Microsoft services..." -ForegroundColor Blue
try {
    Disconnect-MgGraph | Out-Null
    Disconnect-AzureAD | Out-Null
    Disconnect-ExchangeOnline -Confirm:$false | Out-Null
    Disconnect-SPOService | Out-Null
    Disconnect-MicrosoftTeams | Out-Null
    Write-Host "  ✓ Successfully disconnected from all services" -ForegroundColor Green
}
catch {
    Write-Host "  ! Some disconnect operations failed: $_" -ForegroundColor Yellow
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "                 Data Extraction Complete!" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Data has been extracted and saved to:" -ForegroundColor White
Write-Host "$outputDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "Key actions completed:" -ForegroundColor White
Write-Host "✓ Extracted organizational data" -ForegroundColor Green
Write-Host "✓ Extracted user information" -ForegroundColor Green
Write-Host "✓ Generated user photos/avatars" -ForegroundColor Green
Write-Host "✓ Extracted groups and teams data" -ForegroundColor Green
Write-Host "✓ Created department structure" -ForegroundColor Green
Write-Host "✓ Generated employee code mapping" -ForegroundColor Green
Write-Host "✓ Updated intranet settings" -ForegroundColor Green
Write-Host "✓ Configured exclusive access for: $adminUsername ($employeeCode)" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "1. Start the intranet server: .\start-intranet-server.ps1" -ForegroundColor White
Write-Host "2. Access the portal at: http://localhost:8090/intranet/" -ForegroundColor White
Write-Host "3. Login using your admin email or employee code: $employeeCode" -ForegroundColor White
Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor White
Read-Host
