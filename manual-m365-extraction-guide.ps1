# Manual Microsoft 365 Data Extraction Guide
# This script will guide you through manually extracting data from Microsoft 365 admin centers
# and configuring the iBridge intranet to use real data

# Color definitions for console output
$colors = @{
    Title = "Cyan"
    Section = "Green"
    Instruction = "White"
    Warning = "Yellow"
    Error = "Red"
    Success = "Green"
    Code = "DarkGray"
    URL = "Blue"
}

# Clear the console
Clear-Host

# Display title
Write-Host "=====================================================================" -ForegroundColor $colors.Title
Write-Host "     iBridge Intranet - Manual Microsoft 365 Data Extraction Guide    " -ForegroundColor $colors.Title
Write-Host "=====================================================================" -ForegroundColor $colors.Title
Write-Host ""

# Function to update settings file to use real M365 data
function Set-ProductionMode {
    $settingsFile = ".\intranet\data\settings.json"
    
    if (Test-Path $settingsFile) {
        try {
            # Read the settings file
            $settings = Get-Content -Path $settingsFile -Raw | ConvertFrom-Json
            
            # Update the mode settings
            $settings.devMode = $false
            $settings.useM365Data = $true
            $settings.dateUpdated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            
            # Write updated settings back to file
            $settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsFile -Encoding UTF8
            
            Write-Host "✅ Settings updated to production mode successfully!" -ForegroundColor $colors.Success
        }
        catch {
            Write-Host "❌ Error updating settings file: $_" -ForegroundColor $colors.Error
        }
    }
    else {
        Write-Host "❌ Settings file not found at $settingsFile" -ForegroundColor $colors.Error
    }
}

# Step 1: Guide to accessing Microsoft 365 Admin Center
function Show-AdminCenterGuide {
    Write-Host "STEP 1: Accessing Microsoft 365 Admin Center" -ForegroundColor $colors.Section
    Write-Host "--------------------------------------------" -ForegroundColor $colors.Section
    Write-Host ""
    Write-Host "1. Open your browser and go to: " -NoNewline -ForegroundColor $colors.Instruction
    Write-Host "https://admin.microsoft.com" -ForegroundColor $colors.URL
    Write-Host "2. Sign in with your admin account: " -NoNewline -ForegroundColor $colors.Instruction
    Write-Host "lwandile.gasela@ibridge.co.za" -ForegroundColor $colors.Code
    Write-Host "3. Once signed in, you'll see the Microsoft 365 admin center dashboard" -ForegroundColor $colors.Instruction
    Write-Host ""
    Write-Host "Press Enter to continue..." -ForegroundColor $colors.Instruction
    Read-Host | Out-Null
}

# Step 2: Guide to accessing Azure AD / Entra ID
function Show-EntraIDGuide {
    Write-Host "STEP 2: Accessing Microsoft Entra ID (Azure AD)" -ForegroundColor $colors.Section
    Write-Host "---------------------------------------------" -ForegroundColor $colors.Section
    Write-Host ""
    Write-Host "1. From the Microsoft 365 admin center, click on 'Show all' in the left navigation" -ForegroundColor $colors.Instruction
    Write-Host "2. Click on 'Admin centers' and then select 'Entra ID' or 'Azure Active Directory'" -ForegroundColor $colors.Instruction
    Write-Host "3. Alternatively, go directly to: " -NoNewline -ForegroundColor $colors.Instruction
    Write-Host "https://entra.microsoft.com" -ForegroundColor $colors.URL
    Write-Host ""
    Write-Host "Press Enter to continue..." -ForegroundColor $colors.Instruction
    Read-Host | Out-Null
}

# Step 3: Guide to getting app registration details
function Show-AppRegistrationGuide {
    Write-Host "STEP 3: Setting Up App Registration" -ForegroundColor $colors.Section
    Write-Host "-------------------------------" -ForegroundColor $colors.Section
    Write-Host ""
    Write-Host "1. In Microsoft Entra ID (Azure AD), go to 'App registrations' in the left menu" -ForegroundColor $colors.Instruction
    Write-Host "2. Click on '+ New registration'" -ForegroundColor $colors.Instruction
    Write-Host "3. Enter the following details:" -ForegroundColor $colors.Instruction
    Write-Host "   - Name: iBridge Portal" -ForegroundColor $colors.Code
    Write-Host "   - Supported account types: Accounts in this organizational directory only" -ForegroundColor $colors.Code
    Write-Host "   - Redirect URI: Web - http://localhost:8090/intranet/login.html" -ForegroundColor $colors.Code
    Write-Host "4. Click 'Register' to create the app registration" -ForegroundColor $colors.Instruction
    Write-Host "5. On the app's Overview page, note down the following information:" -ForegroundColor $colors.Instruction
    Write-Host "   - Application (client) ID" -ForegroundColor $colors.Code
    Write-Host "   - Directory (tenant) ID" -ForegroundColor $colors.Code
    Write-Host ""
    
    # Create data files directory if it doesn't exist
    if (-not (Test-Path ".\intranet\data")) {
        New-Item -ItemType Directory -Path ".\intranet\data" -Force | Out-Null
    }
    
    # Get app registration details
    Write-Host "Enter the Application (client) ID:" -ForegroundColor $colors.Instruction
    $clientId = Read-Host
    
    Write-Host "Enter the Directory (tenant) ID:" -ForegroundColor $colors.Instruction
    $tenantId = Read-Host
    
    # Save to a file for easy reference
    @"
Application (client) ID: $clientId
Directory (tenant) ID: $tenantId
"@ | Out-File -FilePath ".\intranet\data\app-registration-details.txt" -Encoding UTF8
    
    Write-Host "✅ App registration details saved to intranet\data\app-registration-details.txt" -ForegroundColor $colors.Success
    Write-Host ""
    Write-Host "Press Enter to continue..." -ForegroundColor $colors.Instruction
    Read-Host | Out-Null
    
    return @{
        clientId = $clientId
        tenantId = $tenantId
    }
}

# Step 4: Configure API permissions
function Show-APIPermissionsGuide {
    Write-Host "STEP 4: Configuring API Permissions" -ForegroundColor $colors.Section
    Write-Host "----------------------------------" -ForegroundColor $colors.Section
    Write-Host ""
    Write-Host "1. In your app registration, go to 'API permissions' in the left menu" -ForegroundColor $colors.Instruction
    Write-Host "2. Click on '+ Add a permission'" -ForegroundColor $colors.Instruction
    Write-Host "3. Select 'Microsoft Graph'" -ForegroundColor $colors.Instruction
    Write-Host "4. Choose 'Delegated permissions'" -ForegroundColor $colors.Instruction
    Write-Host "5. Add the following permissions:" -ForegroundColor $colors.Instruction
    Write-Host "   - User.Read (required)" -ForegroundColor $colors.Code
    Write-Host "   - User.ReadBasic.All" -ForegroundColor $colors.Code
    Write-Host "   - Directory.Read.All" -ForegroundColor $colors.Code
    Write-Host "   - Organization.Read.All" -ForegroundColor $colors.Code
    Write-Host "   - Group.Read.All" -ForegroundColor $colors.Code
    Write-Host "6. Click 'Add permissions' to add these permissions to your app" -ForegroundColor $colors.Instruction
    Write-Host "7. Click on 'Grant admin consent for [your organization]' to approve these permissions" -ForegroundColor $colors.Instruction
    Write-Host ""
    Write-Host "Press Enter to continue..." -ForegroundColor $colors.Instruction
    Read-Host | Out-Null
}

# Step 5: Configure authentication settings
function Show-AuthSettingsGuide {
    Write-Host "STEP 5: Configuring Authentication Settings" -ForegroundColor $colors.Section
    Write-Host "-----------------------------------------" -ForegroundColor $colors.Section
    Write-Host ""
    Write-Host "1. In your app registration, go to 'Authentication' in the left menu" -ForegroundColor $colors.Instruction
    Write-Host "2. Under 'Platform configurations', make sure 'Web' is configured with these redirect URIs:" -ForegroundColor $colors.Instruction
    Write-Host "   - http://localhost:8090/intranet/login.html" -ForegroundColor $colors.Code
    Write-Host "   - http://localhost:8090/intranet/" -ForegroundColor $colors.Code
    Write-Host "   - http://localhost:8090/intranet/index.html" -ForegroundColor $colors.Code
    Write-Host "   - http://localhost:8090/auth-callback.html" -ForegroundColor $colors.Code
    Write-Host "3. Under 'Implicit grant and hybrid flows', check these options:" -ForegroundColor $colors.Instruction
    Write-Host "   - Access tokens" -ForegroundColor $colors.Code
    Write-Host "   - ID tokens" -ForegroundColor $colors.Code
    Write-Host "4. Click 'Save' to apply these settings" -ForegroundColor $colors.Instruction
    Write-Host ""
    Write-Host "Press Enter to continue..." -ForegroundColor $colors.Instruction
    Read-Host | Out-Null
}

# Step 6: Manual data extraction guide
function Show-DataExtractionGuide {
    Write-Host "STEP 6: Manually Extracting Organization Data" -ForegroundColor $colors.Section
    Write-Host "-----------------------------------------" -ForegroundColor $colors.Section
    Write-Host ""
    Write-Host "Let's create the organization.json file with company details:" -ForegroundColor $colors.Instruction
    Write-Host ""
    
    # Get organization details
    Write-Host "Enter your company/organization name:" -ForegroundColor $colors.Instruction
    $companyName = Read-Host
    
    Write-Host "Enter city (leave blank if unknown):" -ForegroundColor $colors.Instruction
    $city = Read-Host
    
    Write-Host "Enter state/province (leave blank if unknown):" -ForegroundColor $colors.Instruction
    $state = Read-Host
    
    Write-Host "Enter country (leave blank if unknown):" -ForegroundColor $colors.Instruction
    $country = Read-Host
    
    Write-Host "Enter postal code (leave blank if unknown):" -ForegroundColor $colors.Instruction
    $postalCode = Read-Host
    
    # Create organization JSON
    $organization = @{
        displayName = $companyName
        city = $city
        state = $state
        country = $country
        postalCode = $postalCode
        verifiedDomains = @(
            @{
                name = "ibridge.co.za"
                isDefault = $true
                isInitial = $true
                type = "Managed"
            }
        )
    }
    
    # Save organization data
    $organization | ConvertTo-Json -Depth 5 | Out-File -FilePath ".\intranet\data\organization.json" -Encoding UTF8
    
    Write-Host "✅ Organization data saved to intranet\data\organization.json" -ForegroundColor $colors.Success
    Write-Host ""
    Write-Host "Press Enter to continue..." -ForegroundColor $colors.Instruction
    Read-Host | Out-Null
}

# Step 7: Manually extracting employee data
function Show-EmployeeDataGuide {
    Write-Host "STEP 7: Manually Extracting Employee Data" -ForegroundColor $colors.Section
    Write-Host "--------------------------------------" -ForegroundColor $colors.Section
    Write-Host ""
    Write-Host "Now, we'll guide you through creating employees.json with your staff data:" -ForegroundColor $colors.Instruction
    Write-Host ""
    Write-Host "1. In Microsoft 365 Admin Center, go to 'Users > Active users'" -ForegroundColor $colors.Instruction
    Write-Host "2. You'll see a list of all users in your organization" -ForegroundColor $colors.Instruction
    Write-Host ""
    
    $employees = @()
    $departments = @{}
    
    Write-Host "Let's add your first employee (you can add more later):" -ForegroundColor $colors.Instruction
    
    # Add yourself first
    $employee = @{
        id = "1"
        displayName = "Lwandile Gasela"
        givenName = "Lwandile"
        surname = "Gasela"
        jobTitle = "Administrator"
        mail = "lwandile.gasela@ibridge.co.za"
        department = "Administration"
        officeLocation = ""
        businessPhones = @()
        mobilePhone = ""
    }
    
    $employees += $employee
    
    if (-not $departments.ContainsKey("Administration")) {
        $departments["Administration"] = @{
            name = "Administration"
            description = "Administrative department"
            employeeCount = 1
        }
    }
    
    # Ask if they want to add more employees
    $addMore = $true
    while ($addMore) {
        Write-Host ""
        Write-Host "Do you want to add another employee? (Y/N)" -ForegroundColor $colors.Instruction
        $response = Read-Host
        
        if ($response.ToLower() -eq "y") {
            $id = [string]($employees.Count + 1)
            
            Write-Host "Enter display name (First Last):" -ForegroundColor $colors.Instruction
            $displayName = Read-Host
            
            Write-Host "Enter first name:" -ForegroundColor $colors.Instruction
            $givenName = Read-Host
            
            Write-Host "Enter last name:" -ForegroundColor $colors.Instruction
            $surname = Read-Host
            
            Write-Host "Enter job title:" -ForegroundColor $colors.Instruction
            $jobTitle = Read-Host
            
            Write-Host "Enter email address:" -ForegroundColor $colors.Instruction
            $mail = Read-Host
            
            Write-Host "Enter department:" -ForegroundColor $colors.Instruction
            $department = Read-Host
            
            Write-Host "Enter office location (optional):" -ForegroundColor $colors.Instruction
            $officeLocation = Read-Host
            
            Write-Host "Enter business phone (optional):" -ForegroundColor $colors.Instruction
            $businessPhone = Read-Host
            
            Write-Host "Enter mobile phone (optional):" -ForegroundColor $colors.Instruction
            $mobilePhone = Read-Host
            
            $employee = @{
                id = $id
                displayName = $displayName
                givenName = $givenName
                surname = $surname
                jobTitle = $jobTitle
                mail = $mail
                department = $department
                officeLocation = $officeLocation
                businessPhones = @()
                mobilePhone = $mobilePhone
            }
            
            if ($businessPhone) {
                $employee.businessPhones += $businessPhone
            }
            
            $employees += $employee
            
            # Update department info
            if (-not $departments.ContainsKey($department)) {
                $departments[$department] = @{
                    name = $department
                    description = "$department department"
                    employeeCount = 1
                }
            }
            else {
                $departments[$department].employeeCount++
            }
        }
        else {
            $addMore = $false
        }
    }
    
    # Save employees data
    $employees | ConvertTo-Json -Depth 5 | Out-File -FilePath ".\intranet\data\employees.json" -Encoding UTF8
    
    # Convert departments to array and save
    $departmentsArray = @()
    foreach ($key in $departments.Keys) {
        $departmentsArray += $departments[$key]
    }
    
    $departmentsArray | ConvertTo-Json -Depth 5 | Out-File -FilePath ".\intranet\data\departments.json" -Encoding UTF8
    
    Write-Host "✅ Employee data saved to intranet\data\employees.json" -ForegroundColor $colors.Success
    Write-Host "✅ Department data saved to intranet\data\departments.json" -ForegroundColor $colors.Success
    Write-Host ""
    Write-Host "Press Enter to continue..." -ForegroundColor $colors.Instruction
    Read-Host | Out-Null
}

# Step 8: Update settings.json with correct configuration
function Update-Settings {
    param (
        [string]$clientId,
        [string]$tenantId
    )
    
    Write-Host "STEP 8: Updating Intranet Settings" -ForegroundColor $colors.Section
    Write-Host "--------------------------------" -ForegroundColor $colors.Section
    Write-Host ""
    
    $settingsFile = ".\intranet\data\settings.json"
    
    if (Test-Path $settingsFile) {
        try {
            # Read the settings file
            $settings = Get-Content -Path $settingsFile -Raw | ConvertFrom-Json
            
            # Update the settings
            $settings.devMode = $false
            $settings.useM365Data = $true
            $settings.dateUpdated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            
            # Update Microsoft config
            $settings.microsoftConfig.clientId = $clientId
            $settings.microsoftConfig.tenantId = $tenantId
            $settings.microsoftConfig.redirectUri = "http://localhost:8090/auth-callback.html"
            $settings.microsoftConfig.adminEmail = "lwandile.gasela@ibridge.co.za"
            $settings.microsoftConfig.scopes = @(
                "User.Read",
                "User.ReadBasic.All",
                "Directory.Read.All",
                "Organization.Read.All",
                "Group.Read.All"
            )
            
            # Write updated settings back to file
            $settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsFile -Encoding UTF8
            
            Write-Host "✅ Settings updated successfully!" -ForegroundColor $colors.Success
        }
        catch {
            Write-Host "❌ Error updating settings file: $_" -ForegroundColor $colors.Error
        }
    }
    else {
        # Create a new settings file
        $settings = @{
            allowedDomains = @("ibridge.co.za")
            dateUpdated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            editorUsers = @(
                "lwandile.gasela@ibridge.co.za"
            )
            useM365Data = $true
            devMode = $false
            microsoftConfig = @{
                redirectUri = "http://localhost:8090/auth-callback.html"
                tenantId = $tenantId
                clientId = $clientId
                scopes = @(
                    "User.Read",
                    "User.ReadBasic.All",
                    "Directory.Read.All",
                    "Organization.Read.All",
                    "Group.Read.All"
                )
                adminEmail = "lwandile.gasela@ibridge.co.za"
            }
            companyName = "iBridge Contact Solutions"
            intranetTitle = "iBridge Staff Portal"
            companyDomain = "ibridge.co.za"
            adminUsers = @(
                "lwandile.gasela@ibridge.co.za"
            )
            features = @{
                calendar = $true
                adminPanel = $true
                helpdesk = $true
                news = $true
                companyProfile = $true
                documents = $true
                directory = $true
                microsoftIntegration = $true
            }
        }
        
        # Save the settings
        $settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsFile -Encoding UTF8
        
        Write-Host "✅ New settings file created successfully!" -ForegroundColor $colors.Success
    }
    
    Write-Host ""
    Write-Host "Press Enter to continue..." -ForegroundColor $colors.Instruction
    Read-Host | Out-Null
}

# Step 9: Start the intranet server
function Start-IntranetServer {
    Write-Host "STEP 9: Starting the Intranet Server" -ForegroundColor $colors.Section
    Write-Host "--------------------------------" -ForegroundColor $colors.Section
    Write-Host ""
    Write-Host "Now you can start the unified server to access your intranet with real Microsoft 365 data:" -ForegroundColor $colors.Instruction
    Write-Host ""
    Write-Host "1. Run the unified server:" -ForegroundColor $colors.Instruction
    Write-Host "   - Double-click on START-UNIFIED-SERVER.bat in File Explorer, or" -ForegroundColor $colors.Instruction
    Write-Host "   - Run the command: .\start-unified-server.ps1" -ForegroundColor $colors.Code
    Write-Host ""
    Write-Host "2. Open your browser and navigate to:" -ForegroundColor $colors.Instruction
    Write-Host "   http://localhost:8090/intranet/" -ForegroundColor $colors.URL
    Write-Host ""
    Write-Host "3. Log in with your Microsoft 365 account:" -ForegroundColor $colors.Instruction
    Write-Host "   lwandile.gasela@ibridge.co.za" -ForegroundColor $colors.Code
    Write-Host ""
    Write-Host "Press Enter to continue..." -ForegroundColor $colors.Instruction
    Read-Host | Out-Null
}

# Main execution flow
try {
    # Show guides for each step
    Show-AdminCenterGuide
    Show-EntraIDGuide
    $appDetails = Show-AppRegistrationGuide
    Show-APIPermissionsGuide
    Show-AuthSettingsGuide
    Show-DataExtractionGuide
    Show-EmployeeDataGuide
    Update-Settings -clientId $appDetails.clientId -tenantId $appDetails.tenantId
    Start-IntranetServer
    
    # Final message
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor $colors.Title
    Write-Host "     iBridge Intranet - Manual Configuration Complete!                " -ForegroundColor $colors.Title
    Write-Host "=====================================================================" -ForegroundColor $colors.Title
    Write-Host ""
    Write-Host "Your intranet has been configured to use real Microsoft 365 data." -ForegroundColor $colors.Success
    Write-Host "You can now access the intranet at: http://localhost:8090/intranet/" -ForegroundColor $colors.URL
    Write-Host ""
    Write-Host "Thank you for using the iBridge Intranet Configuration Guide!" -ForegroundColor $colors.Success
    Write-Host ""
}
catch {
    Write-Host "❌ An error occurred: $_" -ForegroundColor $colors.Error
    Write-Host "Please try again or contact support for assistance." -ForegroundColor $colors.Warning
}
