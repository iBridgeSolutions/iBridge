# Script to verify Microsoft 365 integration with the intranet

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "         iBridge Microsoft 365 Integration - Verification" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

# Data file paths
$dataPath = ".\intranet\data"
$profilesPath = ".\intranet\images\profiles"

# Check if data directory exists
if (-not (Test-Path -Path $dataPath)) {
    Write-Host "✗ Data directory not found at $dataPath" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✓ Data directory found at $dataPath" -ForegroundColor Green
}

# Check if profiles directory exists
if (-not (Test-Path -Path $profilesPath)) {
    Write-Host "✗ Profiles directory not found at $profilesPath" -ForegroundColor Red
} else {
    Write-Host "✓ Profiles directory found at $profilesPath" -ForegroundColor Green
}

# Check for required data files
$requiredFiles = @(
    "organization.json",
    "employees.json",
    "departments.json",
    "settings.json"
)

$allFilesExist = $true
foreach ($file in $requiredFiles) {
    $filePath = Join-Path -Path $dataPath -ChildPath $file
    if (Test-Path -Path $filePath) {
        Write-Host "✓ Found data file: $file" -ForegroundColor Green
    } else {
        Write-Host "✗ Missing data file: $file" -ForegroundColor Red
        $allFilesExist = $false
    }
}

if (-not $allFilesExist) {
    Write-Host "`n✗ Some required data files are missing. Please run sync-m365-dev-data.ps1" -ForegroundColor Red
    exit 1
}

# Check data file contents
Write-Host "`nVerifying data file contents..." -ForegroundColor Cyan

# Check organization.json
try {
    $organization = Get-Content -Path (Join-Path -Path $dataPath -ChildPath "organization.json") -Raw | ConvertFrom-Json
    Write-Host "✓ Organization data: $($organization.displayName)" -ForegroundColor Green
    if ($organization.source -like "*Dev Mode*") {
        Write-Host "  Source: $($organization.source)" -ForegroundColor Yellow
    } else {
        Write-Host "  Source: $($organization.source)" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Failed to parse organization.json: $_" -ForegroundColor Red
}

# Check employees.json
try {
    $employees = Get-Content -Path (Join-Path -Path $dataPath -ChildPath "employees.json") -Raw | ConvertFrom-Json
    Write-Host "✓ Employee data: Found $($employees.Count) employees" -ForegroundColor Green
    
    # Check admin user
    $adminUsers = $employees | Where-Object { ($_.roles -contains "admin") -or ($_.email -eq "lwandile.gasela@ibridge.co.za") }
    if ($adminUsers) {
        Write-Host "✓ Found admin user: $($adminUsers[0].displayName)" -ForegroundColor Green
    } else {
        Write-Host "✗ No admin user found" -ForegroundColor Red
    }
    
} catch {
    Write-Host "✗ Failed to parse employees.json: $_" -ForegroundColor Red
}

# Check departments.json
try {
    $departments = Get-Content -Path (Join-Path -Path $dataPath -ChildPath "departments.json") -Raw | ConvertFrom-Json
    Write-Host "✓ Department data: Found $($departments.Count) departments" -ForegroundColor Green
    
    # Check if IT department exists
    $itDept = $departments | Where-Object { $_.name -eq "Information Technology" }
    if ($itDept) {
        Write-Host "✓ Found IT department with $($itDept.members.Count) members" -ForegroundColor Green
    } else {
        Write-Host "✗ IT department not found" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "✗ Failed to parse departments.json: $_" -ForegroundColor Red
}

# Check settings.json
try {
    $settings = Get-Content -Path (Join-Path -Path $dataPath -ChildPath "settings.json") -Raw | ConvertFrom-Json
    Write-Host "✓ Settings data: $($settings.intranetTitle)" -ForegroundColor Green
    Write-Host "  Dev Mode: $($settings.devMode)" -ForegroundColor $(if ($settings.devMode) { "Yellow" } else { "Green" })
    Write-Host "  Microsoft 365 Integration: $($settings.useM365Data)" -ForegroundColor $(if ($settings.useM365Data) { "Green" } else { "Red" })
} catch {
    Write-Host "✗ Failed to parse settings.json: $_" -ForegroundColor Red
}

# Check profile photos
Write-Host "`nVerifying profile photos..." -ForegroundColor Cyan
$photos = Get-ChildItem -Path $profilesPath -Filter "*.jpg"
Write-Host "✓ Found $($photos.Count) profile photos" -ForegroundColor Green

# Summary
Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "                   Verification Complete" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Cyan

if ($allFilesExist) {
    Write-Host "`n✅ Microsoft 365 integration is correctly set up!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Start the unified server: .\start-unified-server.ps1" -ForegroundColor White
    Write-Host "2. Access the intranet at: http://localhost:8090/intranet/" -ForegroundColor White
    Write-Host "3. View the employee directory and company profile pages to see the Microsoft 365 data" -ForegroundColor White
} else {
    Write-Host "`n⚠️ Some issues were found with the Microsoft 365 integration." -ForegroundColor Red
    Write-Host "`nTo fix these issues:" -ForegroundColor Cyan
    Write-Host "1. Run the Microsoft 365 sync script: .\sync-m365-dev-data.ps1" -ForegroundColor White
    Write-Host "2. Check for any error messages during the sync process" -ForegroundColor White
    Write-Host "3. Run this verification script again to confirm the fix" -ForegroundColor White
}

Write-Host "`n=====================================================================" -ForegroundColor Cyan
