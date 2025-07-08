# Update Portal to Custom Authentication System
# This script updates the iBridge portal to use a custom authentication system instead of Microsoft 365

# Configuration
$portalDir = ".\intranet"
$loginHtmlPath = "$portalDir\login.html"
$loginCustomHtmlPath = "$portalDir\login-custom.html"
$settingsPath = "$portalDir\data\settings.json"
$accessControlPath = "$portalDir\data\access-control.json"
$employeeCodesPath = "$portalDir\data\employee-codes.json"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "        PORTAL CUSTOM AUTHENTICATION SYSTEM SETUP" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if file exists
function Test-FileExists {
    param (
        [string]$filePath,
        [string]$description
    )
    
    Write-Host "Checking for $description... " -NoNewline
    if (Test-Path $filePath) {
        Write-Host "Found" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Not Found" -ForegroundColor Red
        return $false
    }
}

# Ensure required files exist
$settingsExists = Test-FileExists -filePath $settingsPath -description "settings.json"
$accessControlExists = Test-FileExists -filePath $accessControlPath -description "access-control.json"
$employeeCodesExists = Test-FileExists -filePath $employeeCodesPath -description "employee-codes.json"
$loginCustomExists = Test-FileExists -filePath $loginCustomHtmlPath -description "custom login page"

if (!$settingsExists -or !$accessControlExists -or !$employeeCodesExists -or !$loginCustomExists) {
    Write-Host "`nSome required files are missing. Please ensure all portal files are in place." -ForegroundColor Red
    exit 1
}

# Step 1: Back up the original login.html
Write-Host "`nStep 1: Creating backup of the original login page..." -ForegroundColor Blue
$backupPath = "$loginHtmlPath.bak"
Copy-Item -Path $loginHtmlPath -Destination $backupPath -Force
Write-Host "  - Original login page backed up to $backupPath" -ForegroundColor Green

# Step 2: Replace login.html with custom version
Write-Host "`nStep 2: Installing custom login page..." -ForegroundColor Blue
Copy-Item -Path $loginCustomHtmlPath -Destination $loginHtmlPath -Force
Write-Host "  - Custom login page installed" -ForegroundColor Green

# Step 3: Update settings.json if needed
Write-Host "`nStep 3: Updating settings.json..." -ForegroundColor Blue
try {
    $settings = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json
    
    # Update settings for custom authentication
    $settings.useM365Data = $false
    $settings.useCustomAuth = $true
    $settings.employeeCodeLogin = $true
    $settings.credentialsLogin = $true
    
    if (!($settings | Get-Member -Name "authConfig")) {
        $settings | Add-Member -MemberType NoteProperty -Name "authConfig" -Value @{
            employeeCodeFormat = "IBD[Last Name Initials][Unique ID]"
            employeeCodeExample = "IBDG054"
            passwordPolicy = "Minimum 8 characters, at least 1 uppercase, 1 lowercase, and 1 number"
            adminEmail = "lwandile.gasela@ibridge.co.za"
        }
    } else {
        $settings.authConfig.employeeCodeFormat = "IBD[Last Name Initials][Unique ID]"
        $settings.authConfig.employeeCodeExample = "IBDG054"
    }
    
    # Remove Microsoft config if needed
    if ($settings.microsoftConfig) {
        $settings.microsoftConfig = $null
    }
    
    # Save the updated settings
    $settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsPath -Encoding UTF8
    Write-Host "  - Settings updated to use custom authentication" -ForegroundColor Green
} catch {
    Write-Host "  - Error updating settings.json: $_" -ForegroundColor Red
}

# Step 4: Ensure custom-authenticator.js exists
$authJsPath = "$portalDir\js\custom-authenticator.js"
Write-Host "`nStep 4: Checking for custom authenticator script..." -ForegroundColor Blue
if (Test-Path $authJsPath) {
    Write-Host "  - Custom authenticator script found" -ForegroundColor Green
} else {
    Write-Host "  - Custom authenticator script not found! Portal may not function correctly." -ForegroundColor Red
}

# Step 5: Verify employee-codes.json has correct format
Write-Host "`nStep 5: Verifying employee-codes.json format..." -ForegroundColor Blue
try {
    $employeeCodes = Get-Content -Path $employeeCodesPath -Raw | ConvertFrom-Json
    
    if (!($employeeCodes | Get-Member -Name "format")) {
        $employeeCodes | Add-Member -MemberType NoteProperty -Name "format" -Value "IBD[Last Name Initials][Unique ID]"
        $employeeCodes | Add-Member -MemberType NoteProperty -Name "lastUpdated" -Value (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    } else {
        $employeeCodes.format = "IBD[Last Name Initials][Unique ID]"
        $employeeCodes.lastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    # Save the updated employee codes
    $employeeCodes | ConvertTo-Json -Depth 10 | Out-File -FilePath $employeeCodesPath -Encoding UTF8
    Write-Host "  - Employee codes format verified and updated if needed" -ForegroundColor Green
} catch {
    Write-Host "  - Error updating employee-codes.json: $_" -ForegroundColor Red
}

Write-Host "`nSetup complete! The portal now uses a custom authentication system." -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Run MANAGE-EMPLOYEE-CODES.bat to add or update employee codes" -ForegroundColor White
Write-Host "2. Run CHECK-AND-START-UNIFIED-SERVER.bat to start the portal" -ForegroundColor White
Write-Host "3. Access the portal at http://localhost:8090/intranet/" -ForegroundColor White
Write-Host "4. Login with employee code IBDG054" -ForegroundColor White
