# Test exclusive access configuration for iBridge Portal
# This script verifies that the portal is properly configured for exclusive access by lwandile.gasela@ibridge.co.za (IBDG054)

# Configuration settings
$expectedAdmin = "lwandile.gasela@ibridge.co.za"
$expectedEmployeeCode = "IBDG054"
$dataPath = ".\intranet\data"
$portalUrl = "http://localhost:8090/intranet/"

Write-Host "===== iBridge Portal Access Verification =====" -ForegroundColor Cyan
Write-Host ""

# Function to check if a string exists in a JSON file
function Test-JsonContains {
    param (
        [string]$FilePath,
        [string]$PropertyPath,
        [string]$ExpectedValue
    )
    
    if (!(Test-Path -Path $FilePath)) {
        Write-Host "  ❌ File not found: $FilePath" -ForegroundColor Red
        return $false
    }
    
    try {
        $json = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
        
        # Split property path by dots
        $pathParts = $PropertyPath -split '\.'
        $current = $json
        
        # Navigate through the property path
        foreach ($part in $pathParts) {
            if ($null -eq $current.$part) {
                Write-Host "  ❌ Property $PropertyPath not found in $FilePath" -ForegroundColor Red
                return $false
            }
            $current = $current.$part
        }
        
        # Check if the property contains the expected value
        if ($current -is [array]) {
            if ($current -contains $ExpectedValue) {
                return $true
            } else {
                Write-Host "  ❌ $PropertyPath does not contain $ExpectedValue in $FilePath" -ForegroundColor Red
                return $false
            }
        } elseif ($current -eq $ExpectedValue) {
            return $true
        } else {
            Write-Host "  ❌ $PropertyPath = $current, expected $ExpectedValue in $FilePath" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  Error reading $FilePath: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Step 1: Verify settings.json
Write-Host "Step 1: Verifying settings.json..." -ForegroundColor Green
$settingsFile = Join-Path -Path $dataPath -ChildPath "settings.json"
$settingsOk = $true

# Check if settings.json exists
if (!(Test-Path -Path $settingsFile)) {
    Write-Host "  ❌ settings.json not found at $settingsFile" -ForegroundColor Red
    $settingsOk = $false
} else {
    Write-Host "  ✅ settings.json found" -ForegroundColor Green
}

# Check devMode setting
if (Test-JsonContains -FilePath $settingsFile -PropertyPath "devMode" -ExpectedValue $false) {
    Write-Host "  ✅ Development mode is disabled" -ForegroundColor Green
} else {
    Write-Host "  ❌ Development mode should be disabled" -ForegroundColor Red
    $settingsOk = $false
}

# Check useM365Data setting
if (Test-JsonContains -FilePath $settingsFile -PropertyPath "useM365Data" -ExpectedValue $true) {
    Write-Host "  ✅ Microsoft 365 data usage is enabled" -ForegroundColor Green
} else {
    Write-Host "  ❌ Microsoft 365 data usage should be enabled" -ForegroundColor Red
    $settingsOk = $false
}

# Check admin user setting
if (Test-JsonContains -FilePath $settingsFile -PropertyPath "adminUsers" -ExpectedValue $expectedAdmin) {
    Write-Host "  ✅ $expectedAdmin is in the admin users list" -ForegroundColor Green
} else {
    Write-Host "  ❌ $expectedAdmin should be in the admin users list" -ForegroundColor Red
    $settingsOk = $false
}

# Step 2: Verify access-control.json
Write-Host "`nStep 2: Verifying access-control.json..." -ForegroundColor Green
$accessFile = Join-Path -Path $dataPath -ChildPath "access-control.json"
$accessOk = $true

# Check if access-control.json exists
if (!(Test-Path -Path $accessFile)) {
    Write-Host "  ❌ access-control.json not found at $accessFile" -ForegroundColor Red
    $accessOk = $false
} else {
    Write-Host "  ✅ access-control.json found" -ForegroundColor Green
}

# Check restrictedAccess setting
if (Test-JsonContains -FilePath $accessFile -PropertyPath "restrictedAccess" -ExpectedValue $true) {
    Write-Host "  ✅ Restricted access is enabled" -ForegroundColor Green
} else {
    Write-Host "  ❌ Restricted access should be enabled" -ForegroundColor Red
    $accessOk = $false
}

# Check allowedUsers setting
if (Test-JsonContains -FilePath $accessFile -PropertyPath "allowedUsers" -ExpectedValue $expectedAdmin) {
    Write-Host "  ✅ $expectedAdmin is in the allowed users list" -ForegroundColor Green
} else {
    Write-Host "  ❌ $expectedAdmin should be in the allowed users list" -ForegroundColor Red
    $accessOk = $false
}

# Check allowedEmployeeCodes setting
if (Test-JsonContains -FilePath $accessFile -PropertyPath "allowedEmployeeCodes" -ExpectedValue $expectedEmployeeCode) {
    Write-Host "  ✅ Employee code $expectedEmployeeCode is in the allowed codes list" -ForegroundColor Green
} else {
    Write-Host "  ❌ Employee code $expectedEmployeeCode should be in the allowed codes list" -ForegroundColor Red
    $accessOk = $false
}

# Step 3: Verify employee-codes.json
Write-Host "`nStep 3: Verifying employee-codes.json..." -ForegroundColor Green
$codesFile = Join-Path -Path $dataPath -ChildPath "employee-codes.json"
$codesOk = $true

# Check if employee-codes.json exists
if (!(Test-Path -Path $codesFile)) {
    Write-Host "  ❌ employee-codes.json not found at $codesFile" -ForegroundColor Red
    $codesOk = $false
} else {
    Write-Host "  ✅ employee-codes.json found" -ForegroundColor Green
    
    # Check if the file contains the correct mapping
    try {
        $codes = Get-Content -Path $codesFile -Raw | ConvertFrom-Json
        $mapping = $codes.mappings | Where-Object { $_.userPrincipalName -eq $expectedAdmin -and $_.employeeCode -eq $expectedEmployeeCode }
        
        if ($mapping) {
            Write-Host "  ✅ Correct mapping found for $expectedAdmin → $expectedEmployeeCode" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Correct mapping not found for $expectedAdmin → $expectedEmployeeCode" -ForegroundColor Red
            $codesOk = $false
        }
    } catch {
        Write-Host "  ❌ Error reading employee-codes.json: $_" -ForegroundColor Red
        $codesOk = $false
    }
}

# Step 4: Verify portal-authenticator.js
Write-Host "`nStep 4: Verifying portal-authenticator.js..." -ForegroundColor Green
$authFile = ".\intranet\js\portal-authenticator.js"

if (Test-Path -Path $authFile) {
    Write-Host "  ✅ portal-authenticator.js found" -ForegroundColor Green
} else {
    Write-Host "  ❌ portal-authenticator.js not found" -ForegroundColor Red
}

# Step 5: Verify login.html
Write-Host "`nStep 5: Verifying login.html..." -ForegroundColor Green
$loginFile = ".\intranet\login.html"

if (Test-Path -Path $loginFile) {
    Write-Host "  ✅ login.html found" -ForegroundColor Green
    
    # Check if login.html contains employee code login functionality
    $loginContent = Get-Content -Path $loginFile -Raw
    if ($loginContent -match "employeeCode" -and $loginContent -match "IBDG054") {
        Write-Host "  ✅ login.html contains employee code login functionality" -ForegroundColor Green
    } else {
        Write-Host "  ❌ login.html should contain employee code login functionality" -ForegroundColor Red
    }
} else {
    Write-Host "  ❌ login.html not found" -ForegroundColor Red
}

# Step 6: Check server availability
Write-Host "`nStep 6: Checking if intranet server is running..." -ForegroundColor Green
try {
    $response = Invoke-WebRequest -Uri $portalUrl -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Host "  ✅ Intranet server is running at $portalUrl" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Intranet server response code: $($response.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Intranet server not available at $portalUrl" -ForegroundColor Red
    Write-Host "  ℹ️ Start the server with START-UNIFIED-SERVER.bat" -ForegroundColor Yellow
}

# Overall verification result
Write-Host "`n===== Verification Results =====" -ForegroundColor Cyan
$overallOk = $settingsOk -and $accessOk -and $codesOk

if ($overallOk) {
    Write-Host "`n✅ SUCCESS: The portal is correctly configured for exclusive access by:" -ForegroundColor Green
    Write-Host "  - Email: $expectedAdmin" -ForegroundColor White
    Write-Host "  - Employee Code: $expectedEmployeeCode" -ForegroundColor White
    
    Write-Host "`nTo access the portal:" -ForegroundColor White
    Write-Host "1. Start the server (if not already running): START-UNIFIED-SERVER.bat" -ForegroundColor White
    Write-Host "2. Navigate to: $portalUrl" -ForegroundColor White
    Write-Host "3. Login with employee code: $expectedEmployeeCode" -ForegroundColor White
} else {
    Write-Host "`n❌ ISSUES FOUND: The portal is NOT correctly configured for exclusive access" -ForegroundColor Red
    Write-Host "Please run CONFIGURE-EXCLUSIVE-ACCESS.bat to fix the configuration" -ForegroundColor Yellow
}

Write-Host "`nPress Enter to exit..." -ForegroundColor White
Read-Host
