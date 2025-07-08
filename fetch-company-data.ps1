# Script to fetch company details and employee information from Microsoft 365
# This script generates JSON files that can be used in the intranet
# Updated version with dev mode support for lwandile.gasela@ibridge.co.za

# App registration details
$clientId = "6686c610-81cf-4ed7-8241-a91a20f01b06"
$tenantId = "feeb9a78-4032-4b89-ae79-2100a5dc16a8"

# Dev mode configuration
$devMode = $false
$adminUser = "lwandile.gasela@ibridge.co.za"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "         iBridge Company Data Fetcher for Intranet" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Microsoft Graph PowerShell SDK is installed
$mgGraphModule = Get-Module -ListAvailable -Name Microsoft.Graph.Users
if ($null -eq $mgGraphModule) {
    Write-Host "The Microsoft Graph PowerShell module is not installed." -ForegroundColor Red
    Write-Host "Installing Microsoft Graph PowerShell module..." -ForegroundColor Yellow
    
    try {
        Install-Module -Name Microsoft.Graph -Force -Scope CurrentUser
    }
    catch {
        Write-Host "Failed to install Microsoft Graph module." -ForegroundColor Red
        Write-Host "Please run this command manually in PowerShell as administrator:" -ForegroundColor Yellow
        Write-Host "Install-Module -Name Microsoft.Graph -Force -Scope CurrentUser" -ForegroundColor White
        exit 1
    }
}

# Connect to Microsoft Graph with the needed permissions
try {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Blue
    Connect-MgGraph -TenantId $tenantId -Scopes "User.Read.All", "Organization.Read.All", "Directory.Read.All" -NoWelcome
}
catch {
    Write-Host "Failed to connect to Microsoft Graph. Please check your credentials and try again." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Create directory for the data if it doesn't exist
$dataPath = ".\intranet\data"
if (-not (Test-Path -Path $dataPath)) {
    New-Item -ItemType Directory -Path $dataPath -Force | Out-Null
    Write-Host "Created data directory at $dataPath" -ForegroundColor Green
}

# Create profiles directory for user photos if it doesn't exist
$profilesPath = ".\intranet\images\profiles"
if (-not (Test-Path -Path $profilesPath)) {
    New-Item -ItemType Directory -Path $profilesPath -Force | Out-Null
    Write-Host "Created profiles directory at $profilesPath" -ForegroundColor Green
    
    # Create a sample profile image for Lwandile in dev mode
    if ($devMode) {
        try {
            $avatarUrl = "https://ui-avatars.com/api/?name=Lwandile+Gasela&background=0D8ABC&color=fff&size=256"
            $outputPath = "$profilesPath\lwandile-gasela.jpg"
            
            Write-Host "Generating sample profile photo for $adminUser..." -ForegroundColor Blue
            Invoke-WebRequest -Uri $avatarUrl -OutFile $outputPath
            
            if (Test-Path $outputPath) {
                Write-Host "Sample profile photo created successfully at $outputPath" -ForegroundColor Green
            }
        } catch {
            Write-Host "Warning: Failed to create sample profile photo: $_" -ForegroundColor Yellow
        }
    }
}

# Step 1: Fetch Organization Information
try {
    Write-Host ""
    Write-Host "Fetching organization information..." -ForegroundColor Blue
    $organization = Get-MgOrganization
    
    if ($null -eq $organization) {
        Write-Host "No organization information found." -ForegroundColor Yellow
    }
    else {
        # Create organization info object with selected properties
        $orgInfo = @{
            displayName = $organization.DisplayName
            verifiedDomains = $organization.VerifiedDomains | ForEach-Object { 
                @{
                    name = $_.Name
                    isDefault = $_.IsDefault
                    isInitial = $_.IsInitial
                    type = $_.Type
                }
            }
            street = $organization.Street
            city = $organization.City
            state = $organization.State
            country = $organization.CountryLetterCode
            postalCode = $organization.PostalCode
            phoneNumber = $organization.BusinessPhones[0]
            technicalNotificationEmails = $organization.TechnicalNotificationMails
            privacyProfile = $organization.PrivacyProfile
            securityComplianceNotificationPhones = $organization.SecurityComplianceNotificationPhones
            securityComplianceNotificationMails = $organization.SecurityComplianceNotificationMails
            marketingNotificationEmails = $organization.MarketingNotificationEmails
            logoBase64 = ""  # Placeholder, we'll try to get the logo separately
        }
        
        # Save organization info to file
        $orgInfoJson = $orgInfo | ConvertTo-Json -Depth 4
        $orgInfoJson | Out-File -FilePath "$dataPath\organization.json" -Encoding UTF8
        Write-Host "✅ Organization information saved to $dataPath\organization.json" -ForegroundColor Green
    }
}
catch {
    Write-Host "Error fetching organization information: $_" -ForegroundColor Red
}

# Step 2: Fetch User/Employee Information
try {
    Write-Host ""
    Write-Host "Fetching employee information..." -ForegroundColor Blue
    
    # Get all users with details
    $users = Get-MgUser -All -Property Id, DisplayName, GivenName, Surname, UserPrincipalName, Mail, 
                                    JobTitle, Department, OfficeLocation, BusinessPhones, MobilePhone, 
                                    City, Country, PreferredLanguage, AccountEnabled, UsageLocation
    
    if ($null -eq $users -or $users.Count -eq 0) {
        Write-Host "No user information found." -ForegroundColor Yellow
    }
    else {
        Write-Host "Found $($users.Count) users." -ForegroundColor Green
        
        # Create array of user objects with selected properties
        $employeesInfo = $users | Where-Object { $_.UserPrincipalName -match "@ibridge\.co\.za$" } | ForEach-Object {
            $employee = @{
                id = $_.Id
                displayName = $_.DisplayName
                firstName = $_.GivenName
                lastName = $_.Surname
                email = $_.Mail
                userPrincipalName = $_.UserPrincipalName
                jobTitle = $_.JobTitle
                department = $_.Department
                office = $_.OfficeLocation
                businessPhone = if ($_.BusinessPhones.Count -gt 0) { $_.BusinessPhones[0] } else { "" }
                mobilePhone = $_.MobilePhone
                city = $_.City
                country = $_.Country
                isActive = $_.AccountEnabled
                photoUrl = ""  # Placeholder, we'll try to get photos separately if possible
                lastUpdated = (Get-Date -Format "yyyy-MM-dd")
                source = if ($devMode) { "Microsoft 365 Admin Center (Dev Mode)" } else { "Microsoft 365 Admin Center" }
            }
            
            # Add special attributes for Lwandile Gasela
            if ($_.UserPrincipalName -eq $adminUser) {
                Write-Host "Adding admin privileges and extended data for $adminUser" -ForegroundColor Cyan
                
                $employee.photoUrl = "images/profiles/lwandile-gasela.jpg"
                $employee.profilePhoto = "https://graph.microsoft.com/v1.0/users/$adminUser/photo/`$value"
                $employee.skills = @("IT Infrastructure", "Azure", "Microsoft 365", "Networking", "Web Development")
                $employee.languages = @("English", "Xhosa")
                $employee.hireDate = "2020-03-15"
                $employee.manager = @{
                    id = "4";
                    displayName = "Michael Thompson";
                    email = "michael.thompson@ibridge.co.za"
                }
                $employee.roles = @("admin", "editor", "user")
                $employee.bio = "Lwandile is responsible for managing and maintaining the company's IT infrastructure and intranet portal. He has extensive experience in Microsoft technologies and cloud solutions."
                $employee.socialMedia = @{
                    linkedin = "https://www.linkedin.com/in/lwandilegasela/";
                    github = "https://github.com/lwandilegasela"
                }
            }
            
            $employee
        }
        
        # Save employee info to file
        $employeesInfoJson = $employeesInfo | ConvertTo-Json -Depth 4
        $employeesInfoJson | Out-File -FilePath "$dataPath\employees.json" -Encoding UTF8
        Write-Host "✅ Employee information saved to $dataPath\employees.json" -ForegroundColor Green
    }
}
catch {
    Write-Host "Error fetching employee information: $_" -ForegroundColor Red
}

# Step 3: Fetch Department Information
try {
    Write-Host ""
    Write-Host "Generating department summary..." -ForegroundColor Blue
    
    # Process departments from users
    $departments = @{}
    $users | Where-Object { -not [string]::IsNullOrEmpty($_.Department) } | ForEach-Object {
        $dept = $_.Department
        if (-not $departments.ContainsKey($dept)) {
            $departments[$dept] = @{
                name = $dept
                count = 0
                members = @()
            }
        }
        
        $departments[$dept].count++
        $departments[$dept].members += @{
            id = $_.Id
            displayName = $_.DisplayName
            email = $_.Mail
            jobTitle = $_.JobTitle
        }
    }
    
    # Convert departments to array
    $departmentsArray = $departments.Values | Sort-Object -Property name
    
    # Save department info to file
    $departmentsJson = $departmentsArray | ConvertTo-Json -Depth 4
    $departmentsJson | Out-File -FilePath "$dataPath\departments.json" -Encoding UTF8
    Write-Host "✅ Department information saved to $dataPath\departments.json" -ForegroundColor Green
}
catch {
    Write-Host "Error generating department summary: $_" -ForegroundColor Red
}

# Step 4: Create a file with basic settings for the intranet
try {
    Write-Host ""
    Write-Host "Creating intranet settings file..." -ForegroundColor Blue
    
    $settings = @{
        companyName = if ($organization) { $organization.DisplayName } else { "iBridge Contact Solutions" }
        companyDomain = if ($organization -and $organization.VerifiedDomains.Count -gt 0) { $organization.VerifiedDomains[0].Name } else { "ibridge.co.za" }
        intranetTitle = "iBridge Staff Portal"
        dateUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        adminUsers = @("lwandile.gasela@ibridge.co.za")
        editorUsers = @("lwandile.gasela@ibridge.co.za")
        allowedDomains = @("ibridge.co.za")
        features = @{
            directory = $true
            calendar = $true
            documents = $true
            news = $true
            helpdesk = $true
            companyProfile = $true
            adminPanel = $true
            microsoftIntegration = $true
        }
        devMode = $devMode
        useM365Data = $true
        microsoftConfig = @{
            adminEmail = $adminUser
            tenantId = $tenantId
            clientId = $clientId
            redirectUri = "http://localhost:8090/auth-callback.html"
            scopes = @(
                "User.Read",
                "User.ReadBasic.All",
                "Directory.Read.All",
                "Organization.Read.All",
                "Group.Read.All"
            )
        }
    }
    
    # Save settings to file
    $settingsJson = $settings | ConvertTo-Json -Depth 4
    $settingsJson | Out-File -FilePath "$dataPath\settings.json" -Encoding UTF8
    Write-Host "✅ Intranet settings saved to $dataPath\settings.json" -ForegroundColor Green
}
catch {
    Write-Host "Error creating intranet settings: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "                   Data Fetching Complete!" -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Company and employee data has been saved to the following location:" -ForegroundColor White
Write-Host "$dataPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "You can now use this data in the intranet's dev mode by:" -ForegroundColor White
Write-Host "1. Starting the intranet server: .\serve-intranet.ps1" -ForegroundColor White
Write-Host "2. Accessing the intranet at: http://localhost:8090/intranet/" -ForegroundColor White
Write-Host "3. Using the dev mode login with your admin details" -ForegroundColor White
Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor White
Read-Host
