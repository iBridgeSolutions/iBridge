# Script to generate sample Microsoft 365 data for intranet
# This script creates sample data files that simulate Microsoft 365 integration

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "         iBridge Microsoft 365 Integration - DEV MODE SYNC" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

# Dev mode configuration
$adminUser = "lwandile.gasela@ibridge.co.za"
$currentDate = Get-Date -Format "yyyy-MM-dd"

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
}

# Generate sample profile images for employees
$employees = @(
    @{name = "Lwandile Gasela"; email = "lwandile.gasela@ibridge.co.za"},
    @{name = "John Smith"; email = "john.smith@ibridge.co.za"},
    @{name = "Sarah Johnson"; email = "sarah.johnson@ibridge.co.za"},
    @{name = "Michael Thompson"; email = "michael.thompson@ibridge.co.za"},
    @{name = "Thandi Mbeki"; email = "thandi.mbeki@ibridge.co.za"},
    @{name = "David van der Merwe"; email = "david.vandermerwe@ibridge.co.za"},
    @{name = "Priya Sharma"; email = "priya.sharma@ibridge.co.za"},
    @{name = "Robert Moyo"; email = "robert.moyo@ibridge.co.za"},
    @{name = "Olivia Pretorius"; email = "olivia.pretorius@ibridge.co.za"},
    @{name = "James Zulu"; email = "james.zulu@ibridge.co.za"},
    @{name = "Emma Smith"; email = "emma.smith@ibridge.co.za"},
    @{name = "Sipho Ndlovu"; email = "sipho.ndlovu@ibridge.co.za"}
)

foreach ($employee in $employees) {
    $filename = $employee.name.ToLower() -replace " ", "-"
    $outputPath = "$profilesPath\$filename.jpg"
    
    if (-not (Test-Path $outputPath)) {
        try {
            $avatarUrl = "https://ui-avatars.com/api/?name=$($employee.name -replace " ", "+")&background=0D8ABC&color=fff&size=256"
            
            Write-Host "Generating profile photo for $($employee.name)..." -ForegroundColor Blue
            Invoke-WebRequest -Uri $avatarUrl -OutFile $outputPath
            
            if (Test-Path $outputPath) {
                Write-Host "✓ Profile photo created at $outputPath" -ForegroundColor Green
            }
        } catch {
            Write-Host "✗ Failed to create profile photo for $($employee.name): $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✓ Profile photo already exists for $($employee.name)" -ForegroundColor Green
    }
}

# Step 1: Create Organization Information
Write-Host ""
Write-Host "Creating organization information..." -ForegroundColor Blue

$organization = @{
    displayName = "iBridge Contact Solutions"
    verifiedDomains = @(
        @{
            name = "ibridge.co.za"
            isDefault = $true
            isInitial = $true
            type = "Managed"
        }
    )
    street = "123 Main Street"
    city = "Bryanston"
    state = "Gauteng"
    country = "ZA"
    postalCode = "2191"
    phoneNumber = "+27 11 540 8450"
    technicalNotificationEmails = @("it.support@ibridge.co.za")
    privacyProfile = @{
        contactEmail = "privacy@ibridge.co.za"
        statementUrl = "https://www.ibridge.co.za/privacy"
    }
    securityComplianceNotificationPhones = @("+27 11 540 8450")
    securityComplianceNotificationMails = @("security@ibridge.co.za")
    marketingNotificationEmails = @("marketing@ibridge.co.za")
    logoBase64 = ""  # Placeholder for logo
    lastUpdated = $currentDate
    source = "Microsoft 365 Admin Center (Dev Mode)"
}

# Save organization info to file
$orgInfoJson = $organization | ConvertTo-Json -Depth 4
$orgInfoJson | Out-File -FilePath "$dataPath\organization.json" -Encoding UTF8
Write-Host "✅ Organization information saved to $dataPath\organization.json" -ForegroundColor Green

# Step 2: Create Employee Information
Write-Host ""
Write-Host "Creating employee information..." -ForegroundColor Blue

$employeesInfo = @(
    @{
        id = "1"
        displayName = "Lwandile Gasela"
        firstName = "Lwandile"
        lastName = "Gasela"
        email = "lwandile.gasela@ibridge.co.za"
        userPrincipalName = "lwandile.gasela@ibridge.co.za"
        jobTitle = "IT Systems Administrator"
        department = "Information Technology"
        office = "Bryanston Office"
        businessPhone = "+27 11 540 8450"
        mobilePhone = "+27 71 123 4567"
        city = "Johannesburg"
        country = "South Africa"
        isActive = $true
        photoUrl = "images/profiles/lwandile-gasela.jpg"
        profilePhoto = "images/profiles/lwandile-gasela.jpg"
        skills = @("IT Infrastructure", "Azure", "Microsoft 365", "Networking", "Web Development")
        languages = @("English", "Xhosa")
        hireDate = "2020-03-15"
        manager = @{
            id = "4"
            displayName = "Michael Thompson"
            email = "michael.thompson@ibridge.co.za"
        }
        roles = @("admin", "editor", "user")
        bio = "Lwandile is responsible for managing and maintaining the company's IT infrastructure and intranet portal. He has extensive experience in Microsoft technologies and cloud solutions."
        socialMedia = @{
            linkedin = "https://www.linkedin.com/in/lwandilegasela/"
            github = "https://github.com/lwandilegasela"
        }
        lastUpdated = $currentDate
        source = "Microsoft 365 Admin Center (Dev Mode)"
    },
    @{
        id = "2"
        displayName = "John Smith"
        firstName = "John"
        lastName = "Smith"
        email = "john.smith@ibridge.co.za"
        userPrincipalName = "john.smith@ibridge.co.za"
        jobTitle = "Contact Center Manager"
        department = "Operations"
        office = "Bryanston Office"
        businessPhone = "+27 11 540 8451"
        mobilePhone = "+27 72 234 5678"
        city = "Johannesburg"
        country = "South Africa"
        isActive = $true
        photoUrl = "images/profiles/john-smith.jpg"
        lastUpdated = $currentDate
        source = "Microsoft 365 Admin Center (Dev Mode)"
    },
    @{
        id = "3"
        displayName = "Sarah Johnson"
        firstName = "Sarah"
        lastName = "Johnson"
        email = "sarah.johnson@ibridge.co.za"
        userPrincipalName = "sarah.johnson@ibridge.co.za"
        jobTitle = "HR Director"
        department = "Human Resources"
        office = "Bryanston Office"
        businessPhone = "+27 11 540 8452"
        mobilePhone = "+27 73 345 6789"
        city = "Johannesburg"
        country = "South Africa"
        isActive = $true
        photoUrl = "images/profiles/sarah-johnson.jpg"
        lastUpdated = $currentDate
        source = "Microsoft 365 Admin Center (Dev Mode)"
    },
    @{
        id = "4"
        displayName = "Michael Thompson"
        firstName = "Michael"
        lastName = "Thompson"
        email = "michael.thompson@ibridge.co.za"
        userPrincipalName = "michael.thompson@ibridge.co.za"
        jobTitle = "IT Director"
        department = "Information Technology"
        office = "Bryanston Office"
        businessPhone = "+27 11 540 8453"
        mobilePhone = "+27 74 456 7890"
        city = "Johannesburg"
        country = "South Africa"
        isActive = $true
        photoUrl = "images/profiles/michael-thompson.jpg"
        roles = @("admin", "user")
        lastUpdated = $currentDate
        source = "Microsoft 365 Admin Center (Dev Mode)"
    },
    @{
        id = "5"
        displayName = "Thandi Mbeki"
        firstName = "Thandi"
        lastName = "Mbeki"
        email = "thandi.mbeki@ibridge.co.za"
        userPrincipalName = "thandi.mbeki@ibridge.co.za"
        jobTitle = "Marketing Specialist"
        department = "Marketing"
        office = "Bryanston Office"
        businessPhone = "+27 11 540 8454"
        mobilePhone = "+27 75 567 8901"
        city = "Johannesburg"
        country = "South Africa"
        isActive = $true
        photoUrl = "images/profiles/thandi-mbeki.jpg"
        lastUpdated = $currentDate
        source = "Microsoft 365 Admin Center (Dev Mode)"
    },
    @{
        id = "6"
        displayName = "David van der Merwe"
        firstName = "David"
        lastName = "van der Merwe"
        email = "david.vandermerwe@ibridge.co.za"
        userPrincipalName = "david.vandermerwe@ibridge.co.za"
        jobTitle = "Customer Success Manager"
        department = "Customer Success"
        office = "Bryanston Office"
        businessPhone = "+27 11 540 8455"
        mobilePhone = "+27 76 678 9012"
        city = "Johannesburg"
        country = "South Africa"
        isActive = $true
        photoUrl = "images/profiles/david-van-der-merwe.jpg"
        lastUpdated = $currentDate
        source = "Microsoft 365 Admin Center (Dev Mode)"
    },
    @{
        id = "7"
        displayName = "Priya Sharma"
        firstName = "Priya"
        lastName = "Sharma"
        email = "priya.sharma@ibridge.co.za"
        userPrincipalName = "priya.sharma@ibridge.co.za"
        jobTitle = "Software Developer"
        department = "Information Technology"
        office = "Bryanston Office"
        businessPhone = "+27 11 540 8456"
        mobilePhone = "+27 77 789 0123"
        city = "Johannesburg"
        country = "South Africa"
        isActive = $true
        photoUrl = "images/profiles/priya-sharma.jpg"
        lastUpdated = $currentDate
        source = "Microsoft 365 Admin Center (Dev Mode)"
    },
    @{
        id = "8"
        displayName = "Robert Moyo"
        firstName = "Robert"
        lastName = "Moyo"
        email = "robert.moyo@ibridge.co.za"
        userPrincipalName = "robert.moyo@ibridge.co.za"
        jobTitle = "Support Specialist"
        department = "Information Technology"
        office = "Bryanston Office"
        businessPhone = "+27 11 540 8457"
        mobilePhone = "+27 78 890 1234"
        city = "Johannesburg"
        country = "South Africa"
        isActive = $true
        photoUrl = "images/profiles/robert-moyo.jpg"
        lastUpdated = $currentDate
        source = "Microsoft 365 Admin Center (Dev Mode)"
    },
    @{
        id = "9"
        displayName = "Olivia Pretorius"
        firstName = "Olivia"
        lastName = "Pretorius"
        email = "olivia.pretorius@ibridge.co.za"
        userPrincipalName = "olivia.pretorius@ibridge.co.za"
        jobTitle = "Call Center Agent"
        department = "Operations"
        office = "Bryanston Office"
        businessPhone = "+27 11 540 8458"
        mobilePhone = "+27 79 901 2345"
        city = "Johannesburg"
        country = "South Africa"
        isActive = $true
        photoUrl = "images/profiles/olivia-pretorius.jpg"
        lastUpdated = $currentDate
        source = "Microsoft 365 Admin Center (Dev Mode)"
    },
    @{
        id = "10"
        displayName = "James Zulu"
        firstName = "James"
        lastName = "Zulu"
        email = "james.zulu@ibridge.co.za"
        userPrincipalName = "james.zulu@ibridge.co.za"
        jobTitle = "Sales Executive"
        department = "Sales"
        office = "Bryanston Office"
        businessPhone = "+27 11 540 8459"
        mobilePhone = "+27 70 012 3456"
        city = "Johannesburg"
        country = "South Africa"
        isActive = $true
        photoUrl = "images/profiles/james-zulu.jpg"
        lastUpdated = $currentDate
        source = "Microsoft 365 Admin Center (Dev Mode)"
    },
    @{
        id = "11"
        displayName = "Emma Smith"
        firstName = "Emma"
        lastName = "Smith"
        email = "emma.smith@ibridge.co.za"
        userPrincipalName = "emma.smith@ibridge.co.za"
        jobTitle = "Project Manager"
        department = "Project Management"
        office = "Bryanston Office"
        businessPhone = "+27 11 540 8460"
        mobilePhone = "+27 71 123 4567"
        city = "Johannesburg"
        country = "South Africa"
        isActive = $true
        photoUrl = "images/profiles/emma-smith.jpg"
        lastUpdated = $currentDate
        source = "Microsoft 365 Admin Center (Dev Mode)"
    },
    @{
        id = "12"
        displayName = "Sipho Ndlovu"
        firstName = "Sipho"
        lastName = "Ndlovu"
        email = "sipho.ndlovu@ibridge.co.za"
        userPrincipalName = "sipho.ndlovu@ibridge.co.za"
        jobTitle = "Business Analyst"
        department = "Business Intelligence"
        office = "Bryanston Office"
        businessPhone = "+27 11 540 8461"
        mobilePhone = "+27 72 234 5678"
        city = "Johannesburg"
        country = "South Africa"
        isActive = $true
        photoUrl = "images/profiles/sipho-ndlovu.jpg"
        lastUpdated = $currentDate
        source = "Microsoft 365 Admin Center (Dev Mode)"
    }
)

# Save employee info to file
$employeesInfoJson = $employeesInfo | ConvertTo-Json -Depth 4
$employeesInfoJson | Out-File -FilePath "$dataPath\employees.json" -Encoding UTF8
Write-Host "✅ Employee information saved to $dataPath\employees.json" -ForegroundColor Green

# Step 3: Create Department Information
Write-Host ""
Write-Host "Creating department information..." -ForegroundColor Blue

# Group employees by department
$departments = @{}
foreach ($employee in $employeesInfo) {
    $dept = $employee.department
    if (-not [string]::IsNullOrEmpty($dept)) {
        if (-not $departments.ContainsKey($dept)) {
            $departments[$dept] = @{
                name = $dept
                count = 0
                members = @()
            }
        }
        
        $departments[$dept].count++
        $departments[$dept].members += @{
            id = $employee.id
            displayName = $employee.displayName
            email = $employee.email
            jobTitle = $employee.jobTitle
            photoUrl = $employee.photoUrl
        }
    }
}

# Enhance IT department with additional details
if ($departments.ContainsKey("Information Technology")) {
    $departments["Information Technology"] = @{
        id = "IT-001"
        name = "Information Technology"
        count = $departments["Information Technology"].count
        description = "Responsible for managing and maintaining the company's technology infrastructure, software systems, and providing technical support to all departments."
        headOfDepartment = @{
            id = "4"
            displayName = "Michael Thompson"
            email = "michael.thompson@ibridge.co.za"
            jobTitle = "IT Director"
        }
        location = "Floor 2, Bryanston Office"
        contactEmail = "it.support@ibridge.co.za"
        contactPhone = "+27 11 540 8450"
        members = $departments["Information Technology"].members
        lastUpdated = $currentDate
        source = "Microsoft 365 Admin Center (Dev Mode)"
    }
}

# Convert departments to array
$departmentsArray = $departments.Values | Sort-Object -Property name

# Save department info to file
$departmentsJson = $departmentsArray | ConvertTo-Json -Depth 4
$departmentsJson | Out-File -FilePath "$dataPath\departments.json" -Encoding UTF8
Write-Host "✅ Department information saved to $dataPath\departments.json" -ForegroundColor Green

# Step 4: Create intranet settings
Write-Host ""
Write-Host "Creating intranet settings file..." -ForegroundColor Blue

$settings = @{
    companyName = "iBridge Contact Solutions"
    companyDomain = "ibridge.co.za"
    intranetTitle = "iBridge Staff Portal"
    dateUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    adminUsers = @("lwandile.gasela@ibridge.co.za", "michael.thompson@ibridge.co.za")
    editorUsers = @("lwandile.gasela@ibridge.co.za", "michael.thompson@ibridge.co.za", "sarah.johnson@ibridge.co.za")
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
    devMode = $true
    useM365Data = $true
    microsoftConfig = @{
        adminEmail = $adminUser
        tenantId = "feeb9a78-4032-4b89-ae79-2100a5dc16a8"
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
}

# Save settings to file
$settingsJson = $settings | ConvertTo-Json -Depth 4
$settingsJson | Out-File -FilePath "$dataPath\settings.json" -Encoding UTF8
Write-Host "✅ Intranet settings saved to $dataPath\settings.json" -ForegroundColor Green

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "                Microsoft 365 Integration Complete!" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Microsoft 365 data has been simulated and saved to:" -ForegroundColor White
Write-Host "$dataPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "You can now use this data in the intranet by:" -ForegroundColor White
Write-Host "1. Starting the unified server: .\start-unified-server.ps1" -ForegroundColor White
Write-Host "2. Accessing the intranet at: http://localhost:8090/intranet/" -ForegroundColor White
Write-Host ""
Write-Host "The following users have admin access:" -ForegroundColor White
foreach ($admin in $settings.adminUsers) {
    Write-Host "- $admin" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "Press Enter to continue..." -ForegroundColor White
Read-Host
