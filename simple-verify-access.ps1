# Simple verification script for exclusive access
# For use with the iBridge Portal

Write-Host "===== iBridge Portal Access Verification =====" -ForegroundColor Cyan
Write-Host ""

# Configuration settings
$expectedAdmin = "lwandile.gasela@ibridge.co.za"
$expectedEmployeeCode = "IBDG054"

# Check settings.json
$settingsFile = ".\intranet\data\settings.json"
if (Test-Path $settingsFile) {
    Write-Host "Found settings.json" -ForegroundColor Green
    $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json
    
    # Check dev mode
    if ($settings.devMode -eq $false) {
        Write-Host "Development mode is disabled: OK" -ForegroundColor Green
    } else {
        Write-Host "Development mode is enabled: ISSUE" -ForegroundColor Red
    }
    
    # Check M365 data usage
    if ($settings.useM365Data -eq $true) {
        Write-Host "Microsoft 365 data usage is enabled: OK" -ForegroundColor Green
    } else {
        Write-Host "Microsoft 365 data usage is disabled: ISSUE" -ForegroundColor Red
    }
    
    # Check admin users
    if ($settings.adminUsers -contains $expectedAdmin) {
        Write-Host "$expectedAdmin is an admin: OK" -ForegroundColor Green
    } else {
        Write-Host "$expectedAdmin should be an admin: ISSUE" -ForegroundColor Red
    }
} else {
    Write-Host "settings.json not found" -ForegroundColor Red
}

Write-Host ""

# Check access control
$accessFile = ".\intranet\data\access-control.json"
if (Test-Path $accessFile) {
    Write-Host "Found access-control.json" -ForegroundColor Green
    $access = Get-Content $accessFile -Raw | ConvertFrom-Json
    
    # Check restricted access
    if ($access.restrictedAccess -eq $true) {
        Write-Host "Restricted access is enabled: OK" -ForegroundColor Green
    } else {
        Write-Host "Restricted access is disabled: ISSUE" -ForegroundColor Red
    }
    
    # Check allowed users
    if ($access.allowedUsers -contains $expectedAdmin) {
        Write-Host "$expectedAdmin is allowed: OK" -ForegroundColor Green
    } else {
        Write-Host "$expectedAdmin should be allowed: ISSUE" -ForegroundColor Red
    }
    
    # Check allowed employee codes
    if ($access.allowedEmployeeCodes -contains $expectedEmployeeCode) {
        Write-Host "Employee code $expectedEmployeeCode is allowed: OK" -ForegroundColor Green
    } else {
        Write-Host "Employee code $expectedEmployeeCode should be allowed: ISSUE" -ForegroundColor Red
    }
} else {
    Write-Host "access-control.json not found" -ForegroundColor Red
}

Write-Host ""

# Check employee codes
$codesFile = ".\intranet\data\employee-codes.json"
if (Test-Path $codesFile) {
    Write-Host "Found employee-codes.json" -ForegroundColor Green
    $codes = Get-Content $codesFile -Raw | ConvertFrom-Json
    
    $mapping = $codes.mappings | Where-Object { 
        $_.userPrincipalName -eq $expectedAdmin -and $_.employeeCode -eq $expectedEmployeeCode 
    }
    
    if ($mapping) {
        Write-Host "Correct mapping found for $expectedAdmin -> $expectedEmployeeCode: OK" -ForegroundColor Green
    } else {
        Write-Host "Correct mapping not found for $expectedAdmin -> $expectedEmployeeCode: ISSUE" -ForegroundColor Red
    }
} else {
    Write-Host "employee-codes.json not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "===== Verification Complete =====" -ForegroundColor Cyan
Write-Host ""
Write-Host "Instructions to access the portal:"
Write-Host "1. Start the server (if not running): START-UNIFIED-SERVER.bat"
Write-Host "2. Navigate to: http://localhost:8090/intranet/"
Write-Host "3. Login with employee code: $expectedEmployeeCode"
Write-Host ""

Read-Host "Press Enter to exit"
