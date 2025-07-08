# Setup Two-Factor Authentication for iBridge Users
# This script enables 2FA for specified users or all users

# Script configuration
$scriptVersion = "1.0"
$employeeCodesPath = ".\intranet\data\employee-codes.json"
$backupFolder = ".\intranet\data\backups"

# Create backup folder if it doesn't exist
if (-not (Test-Path $backupFolder)) {
    New-Item -Path $backupFolder -ItemType Directory | Out-Null
}

# Display header
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  iBridge Two-Factor Authentication Setup v$scriptVersion" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# Check if employee codes file exists
if (-not (Test-Path $employeeCodesPath)) {
    Write-Host "Error: Employee codes file not found at $employeeCodesPath" -ForegroundColor Red
    exit 1
}

# Create backup of original file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupPath = Join-Path $backupFolder "employee-codes_$timestamp.json.bak"
try {
    Copy-Item -Path $employeeCodesPath -Destination $backupPath
    Write-Host "Backup created at: $backupPath" -ForegroundColor Yellow
} catch {
    Write-Host "Warning: Failed to create backup. $($_.Exception.Message)" -ForegroundColor Red
    $continue = Read-Host "Continue without backup? (y/n)"
    if ($continue -ne "y") {
        exit 1
    }
}

# Load employee codes data
try {
    $employeeData = Get-Content -Path $employeeCodesPath -Raw | ConvertFrom-Json
    $employeeCount = $employeeData.employees.Count
    Write-Host "Loaded $employeeCount employee records" -ForegroundColor Cyan
} catch {
    Write-Host "Error: Failed to load employee data. $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Function to display employees
function Show-Employees {
    $i = 1
    foreach ($employee in $employeeData.employees) {
        $twoFaStatus = if ($employee.twoFactorEnabled) { "Enabled" } else { "Disabled" }
        Write-Host "$i. $($employee.code) - $($employee.name) ($($employee.email)) - 2FA: $twoFaStatus" -ForegroundColor $(if ($employee.twoFactorEnabled) { "Green" } else { "Gray" })
        $i++
    }
}

# Get selection mode
Write-Host ""
Write-Host "How would you like to enable Two-Factor Authentication?" -ForegroundColor Yellow
Write-Host "1. Enable for all users" -ForegroundColor White
Write-Host "2. Enable for specific users" -ForegroundColor White
Write-Host "3. Disable for specific users" -ForegroundColor White
Write-Host "4. View current 2FA status" -ForegroundColor White
Write-Host "5. Cancel" -ForegroundColor White
$mode = Read-Host "Select option (1-5)"

switch ($mode) {
    "1" {
        # Enable for all
        $confirmAll = Read-Host "This will enable 2FA for ALL users. Continue? (y/n)"
        if ($confirmAll -ne "y") {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
            exit 0
        }
        
        foreach ($employee in $employeeData.employees) {
            $employee | Add-Member -NotePropertyName "twoFactorEnabled" -NotePropertyValue $true -Force
        }
        
        Write-Host "Two-Factor Authentication enabled for all users" -ForegroundColor Green
    }
    "2" {
        # Enable for specific users
        Write-Host ""
        Write-Host "Available employees:" -ForegroundColor Yellow
        Show-Employees
        
        $selections = Read-Host "Enter the numbers of employees to enable 2FA for (comma-separated, e.g. 1,3,5)"
        $selectedIndices = $selections -split ',' | ForEach-Object { $_.Trim() }
        
        foreach ($idx in $selectedIndices) {
            if ($idx -match '^\d+$' -and [int]$idx -gt 0 -and [int]$idx -le $employeeData.employees.Count) {
                $employee = $employeeData.employees[[int]$idx - 1]
                $employee | Add-Member -NotePropertyName "twoFactorEnabled" -NotePropertyValue $true -Force
                Write-Host "Enabled 2FA for $($employee.name) ($($employee.code))" -ForegroundColor Green
            } else {
                Write-Host "Invalid selection: $idx - skipping" -ForegroundColor Red
            }
        }
    }
    "3" {
        # Disable for specific users
        Write-Host ""
        Write-Host "Available employees:" -ForegroundColor Yellow
        Show-Employees
        
        $selections = Read-Host "Enter the numbers of employees to disable 2FA for (comma-separated, e.g. 1,3,5)"
        $selectedIndices = $selections -split ',' | ForEach-Object { $_.Trim() }
        
        foreach ($idx in $selectedIndices) {
            if ($idx -match '^\d+$' -and [int]$idx -gt 0 -and [int]$idx -le $employeeData.employees.Count) {
                $employee = $employeeData.employees[[int]$idx - 1]
                $employee | Add-Member -NotePropertyName "twoFactorEnabled" -NotePropertyValue $false -Force
                Write-Host "Disabled 2FA for $($employee.name) ($($employee.code))" -ForegroundColor Yellow
            } else {
                Write-Host "Invalid selection: $idx - skipping" -ForegroundColor Red
            }
        }
    }
    "4" {
        # View status only
        Write-Host ""
        Write-Host "Current 2FA Status:" -ForegroundColor Yellow
        Show-Employees
        
        $saveChanges = Read-Host "Make any changes? (y/n)"
        if ($saveChanges -ne "y") {
            Write-Host "Operation cancelled - no changes made" -ForegroundColor Yellow
            exit 0
        }
    }
    "5" {
        # Cancel
        Write-Host "Operation cancelled - no changes made" -ForegroundColor Yellow
        exit 0
    }
    default {
        Write-Host "Invalid selection - no changes made" -ForegroundColor Red
        exit 1
    }
}

# Save updated employee codes
try {
    $employeeData | ConvertTo-Json -Depth 10 | Set-Content -Path $employeeCodesPath
    Write-Host "Successfully saved updated employee codes with 2FA settings" -ForegroundColor Green
} catch {
    Write-Host "Error: Failed to save updated employee data. $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Restoring backup..." -ForegroundColor Yellow
    
    try {
        Copy-Item -Path $backupPath -Destination $employeeCodesPath -Force
        Write-Host "Backup restored" -ForegroundColor Green
    } catch {
        Write-Host "Failed to restore backup. Manual intervention required." -ForegroundColor Red
    }
    
    exit 1
}

# Display summary
Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  Two-Factor Authentication Setup Complete" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The next steps for users will be:"
Write-Host "1. When users log in, they will be prompted for a verification code"
Write-Host "2. A code will be sent to their email address"
Write-Host "3. They must enter this code to complete login"
Write-Host ""
Write-Host "Note: For testing purposes, the verification code will also be displayed in the browser console"
Write-Host "In a production environment, you should implement a real email sending mechanism"
Write-Host ""
