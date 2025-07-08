# Script to switch from development mode to real Microsoft 365 data
# For use with the iBridge Intranet Portal

# Show header
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "         iBridge Portal - Switch to Real Microsoft 365 Data" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Update settings.json
Write-Host "Step 1: Updating settings.json to use real Microsoft 365 data..." -ForegroundColor Green
$dataPath = ".\intranet\data\settings.json"
try {
    # Read the current settings
    $settings = Get-Content -Path $dataPath -Raw | ConvertFrom-Json
    
    # Update the settings
    $settings.devMode = $false
    $settings.useM365Data = $true
    $settings.microsoftConfig.adminEmail = "lwandile.gasela@ibridge.co.za"
    $settings.dateUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    
    # Save the updated settings
    $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $dataPath
    Write-Host "✅ Successfully updated settings to use real Microsoft 365 data" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error updating settings: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Verify connection to Microsoft Graph
Write-Host "`nStep 2: Verifying Microsoft Graph connection..." -ForegroundColor Green

try {
    # Install the module if not already installed
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        Write-Host "Installing Microsoft.Graph PowerShell module..." -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force
    }

    # Import the modules
    Import-Module Microsoft.Graph.Authentication
    Import-Module Microsoft.Graph.Users
    Import-Module Microsoft.Graph.Groups
    Import-Module Microsoft.Graph.Organizations
    
    # Connect to Microsoft Graph
    Write-Host "Connecting to Microsoft Graph with the account: lwandile.gasela@ibridge.co.za" -ForegroundColor Yellow
    Write-Host "Please login with this account when the browser window opens..." -ForegroundColor Yellow
    Connect-MgGraph -Scopes "User.Read.All", "Organization.Read.All", "Directory.Read.All" -NoWelcome
    
    # Check connection
    $context = Get-MgContext
    if ($null -eq $context) {
        Write-Host "❌ Failed to connect to Microsoft Graph" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Successfully connected to Microsoft Graph as: $($context.Account)" -ForegroundColor Green
    Write-Host "   Tenant ID: $($context.TenantId)" -ForegroundColor White
}
catch {
    Write-Host "❌ Error connecting to Microsoft Graph: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Register app in Microsoft Entra ID
Write-Host "`nStep 3: Registering app in Microsoft Entra ID..." -ForegroundColor Green

try {
    # Check if App Registration modules are available
    Import-Module Microsoft.Graph.Applications

    # App details
    $appName = "iBridge Portal"
    $redirectUris = @(
        "http://localhost:8090/intranet/login.html",
        "http://localhost:8090/intranet/",
        "http://localhost:8090/intranet/index.html",
        "http://localhost:8090/login.html"
    )
    
    # Check if app already exists
    $existingApp = Get-MgApplication -Filter "displayName eq '$appName'"
    
    if ($existingApp) {
        Write-Host "Application '$appName' already exists with ID: $($existingApp.AppId)" -ForegroundColor Yellow
        $app = $existingApp
        
        # Update redirectURIs
        Update-MgApplication -ApplicationId $app.Id -Web @{
            RedirectUris = $redirectUris
        }
        Write-Host "✅ Updated redirect URIs for existing app" -ForegroundColor Green
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
        Write-Host "✅ Successfully created new app registration '$appName'" -ForegroundColor Green
    }

    # Configure API permissions
    $graphResourceId = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
    
    # Permission IDs
    $userReadId = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
    $userReadAllId = "a154be20-db9c-4678-8ab7-66f6cc099a59" # User.ReadBasic.All
    $directoryReadAllId = "7ab1d382-f21e-4acd-a863-ba3e13f7da61" # Directory.Read.All
    $orgReadAllId = "498476ce-e0fe-48b0-b801-37ba7e2685c6" # Organization.Read.All
    $groupReadAllId = "5f8c59db-677d-491f-a6b8-5f174b11ec1d" # Group.Read.All

    # Add required permissions
    $requiredResourceAccess = @{
        ResourceAppId = $graphResourceId
        ResourceAccess = @(
            @{
                Id = $userReadId
                Type = "Scope" # Delegated permission
            },
            @{
                Id = $userReadAllId
                Type = "Scope" # Delegated permission
            },
            @{
                Id = $directoryReadAllId
                Type = "Scope" # Delegated permission
            },
            @{
                Id = $orgReadAllId
                Type = "Scope" # Delegated permission
            },
            @{
                Id = $groupReadAllId
                Type = "Scope" # Delegated permission
            }
        )
    }
    
    # Update the application with required permissions
    Update-MgApplication -ApplicationId $app.Id -RequiredResourceAccess @($requiredResourceAccess)
    Write-Host "✅ API permissions configured successfully" -ForegroundColor Green

    # Enable implicit grant flow
    Update-MgApplication -ApplicationId $app.Id -Web @{
        ImplicitGrantSettings = @{
            EnableIdTokenIssuance = $true
            EnableAccessTokenIssuance = $true
        }
    }
    Write-Host "✅ Implicit grant flow enabled successfully" -ForegroundColor Green

    # Update settings.json with new app details
    $settings = Get-Content -Path $dataPath -Raw | ConvertFrom-Json
    $settings.microsoftConfig.clientId = $app.AppId
    $settings.microsoftConfig.tenantId = $context.TenantId
    $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $dataPath
    
    Write-Host "`n✅ Updated settings.json with new app registration details" -ForegroundColor Green
    Write-Host "   Client ID: $($app.AppId)" -ForegroundColor White
    Write-Host "   Tenant ID: $($context.TenantId)" -ForegroundColor White
}
catch {
    Write-Host "❌ Error registering app: $_" -ForegroundColor Red
}

# Step 4: Fetch real Microsoft 365 data
Write-Host "`nStep 4: Fetching real Microsoft 365 data..." -ForegroundColor Green

try {
    # Create directory for the data if it doesn't exist
    $dataPath = ".\intranet\data"
    if (-not (Test-Path -Path $dataPath)) {
        New-Item -ItemType Directory -Path $dataPath -Force | Out-Null
    }

    # Fetch Organization Information
    Write-Host "Fetching organization information..." -ForegroundColor Blue
    $organization = Get-MgOrganization
    
    if ($null -eq $organization) {
        Write-Host "No organization information found." -ForegroundColor Yellow
    }
    else {
        # Create organization info object
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
            postalCode = $organization.PostalCode
            countryOrRegion = $organization.CountryOrRegion
            businessPhones = $organization.BusinessPhones
            technicalNotificationEmails = $organization.TechnicalNotificationEmails
            privacyProfile = $organization.PrivacyProfile
            securityComplianceNotificationPhones = $organization.SecurityComplianceNotificationPhones
            securityComplianceNotificationEmails = $organization.SecurityComplianceNotificationEmails
            source = "Microsoft 365 Admin Center (Live Data)"
            lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
        
        # Save organization info to file
        $orgJson = $orgInfo | ConvertTo-Json -Depth 5
        $orgJson | Out-File -FilePath "$dataPath\organization.json" -Encoding UTF8
        Write-Host "✅ Organization information saved to $dataPath\organization.json" -ForegroundColor Green
    }

    # Fetch User Information
    Write-Host "Fetching employee information..." -ForegroundColor Blue
    $users = Get-MgUser -All -Property Id, DisplayName, GivenName, Surname, JobTitle, Mail, Department, OfficeLocation, BusinessPhones, MobilePhone, City, PostalCode, State, StreetAddress, Country
    
    if ($null -eq $users -or $users.Count -eq 0) {
        Write-Host "No user information found." -ForegroundColor Yellow
    }
    else {
        # Create employee info object for each user
        $employeeInfo = $users | Where-Object { $_.Mail -ne $null } | ForEach-Object {
            @{
                id = $_.Id
                displayName = $_.DisplayName
                givenName = $_.GivenName
                surname = $_.Surname
                email = $_.Mail
                jobTitle = $_.JobTitle
                department = $_.Department
                office = $_.OfficeLocation
                businessPhone = if ($_.BusinessPhones -and $_.BusinessPhones.Count -gt 0) { $_.BusinessPhones[0] } else { $null }
                mobilePhone = $_.MobilePhone
                city = $_.City
                postalCode = $_.PostalCode
                state = $_.State
                streetAddress = $_.StreetAddress
                country = $_.Country
                photoUrl = "/intranet/images/profiles/$($_.GivenName.ToLower())-$($_.Surname.ToLower()).jpg"
                lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                isActive = $true
                source = "Microsoft 365"
            }
        }
        
        # Save employee info to file
        $empJson = $employeeInfo | ConvertTo-Json -Depth 5
        $empJson | Out-File -FilePath "$dataPath\employees.json" -Encoding UTF8
        Write-Host "✅ Employee information saved to $dataPath\employees.json" -ForegroundColor Green
        
        # Generate a simple department summary from employee data
        $departments = $employeeInfo | Where-Object { $_.department -ne $null -and $_.department -ne "" } | Group-Object -Property department | ForEach-Object {
            @{
                name = $_.Name
                displayName = $_.Name
                description = "Department: $($_.Name)"
                manager = ($employeeInfo | Where-Object { $_.department -eq $_.Name } | Select-Object -First 1).displayName
                email = "$($_.Name.ToLower().Replace(' ', '.'))@ibridge.co.za"
                members = $_.Group | Measure-Object | Select-Object -ExpandProperty Count
                membersList = $_.Group | ForEach-Object { $_.displayName }
                lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                source = "Microsoft 365"
            }
        }
        
        # Save department info to file
        $deptJson = $departments | ConvertTo-Json -Depth 5
        $deptJson | Out-File -FilePath "$dataPath\departments.json" -Encoding UTF8
        Write-Host "✅ Department information saved to $dataPath\departments.json" -ForegroundColor Green
    }
    
    Write-Host "`n✅ All Microsoft 365 data has been successfully fetched and saved!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error fetching Microsoft 365 data: $_" -ForegroundColor Red
}

# Step 5: Final verification
Write-Host "`nStep 5: Final verification..." -ForegroundColor Green
$settings = Get-Content -Path ".\intranet\data\settings.json" -Raw | ConvertFrom-Json
Write-Host "Current settings:" -ForegroundColor Blue
Write-Host "  Development Mode: $($settings.devMode)" -ForegroundColor $(if (-not $settings.devMode) { "Green" } else { "Red" })
Write-Host "  Using Microsoft 365 Data: $($settings.useM365Data)" -ForegroundColor $(if ($settings.useM365Data) { "Green" } else { "Red" })
Write-Host "  Admin Email: $($settings.microsoftConfig.adminEmail)" -ForegroundColor White
Write-Host "  Client ID: $($settings.microsoftConfig.clientId)" -ForegroundColor White
Write-Host "  Tenant ID: $($settings.microsoftConfig.tenantId)" -ForegroundColor White

# Final instructions
Write-Host "`n====================================================================" -ForegroundColor Cyan
Write-Host "                     Setup Complete!" -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "`nYour iBridge Portal is now configured to use real Microsoft 365 data." -ForegroundColor White
Write-Host "To start using it, run the following steps:" -ForegroundColor White
Write-Host "1. Run the unified server: .\START-UNIFIED-SERVER.bat" -ForegroundColor Yellow
Write-Host "2. Access the intranet at: http://localhost:8090/intranet/" -ForegroundColor Yellow
Write-Host "3. Log in with your Microsoft 365 credentials: lwandile.gasela@ibridge.co.za" -ForegroundColor Yellow
Write-Host "`nNote: If you encounter any issues, you may need to grant admin consent for the API permissions in the Microsoft Entra admin center." -ForegroundColor Cyan

# Disconnect from Microsoft Graph
Disconnect-MgGraph | Out-Null
Write-Host "`nDisconnected from Microsoft Graph. Setup completed." -ForegroundColor Green
Write-Host "`nPress Enter to exit..." -ForegroundColor White
Read-Host
