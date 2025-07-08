# iBridge Password Migration Script
# This script securely migrates plaintext passwords to hashed passwords

# Script configuration
$scriptVersion = "1.0"
$employeeCodesPath = ".\intranet\data\employee-codes.json"
$backupFolder = ".\intranet\data\backups"

# Create backup folder if it doesn't exist
if (-not (Test-Path $backupFolder)) {
    New-Item -Path $backupFolder -ItemType Directory | Out-Null
}

# Display header
Write-Host "====================================================" -ForegroundColor Green
Write-Host "  iBridge Password Migration Utility v$scriptVersion" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
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

# Function to generate secure password hash
function Generate-PasswordHash {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Password
    )
    
    # Generate random salt
    $saltSize = 16
    $salt = [System.Text.StringBuilder]::new($saltSize)
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $bytes = [byte[]]::new($saltSize)
    $rng.GetBytes($bytes)
    
    # Convert bytes to string
    foreach ($byte in $bytes) {
        [void]$salt.Append([char]($byte % 94 + 33)) # Printable ASCII characters
    }
    $saltStr = $salt.ToString()
    
    # Combine password and salt
    $passwordWithSalt = $Password + $saltStr
    
    # Hash using SHA-256
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($passwordWithSalt))
    $hashStr = [BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
    
    return @{
        Hash = $hashStr
        Salt = $saltStr
    }
}

# Migrate passwords
$migratedCount = 0
$skippedCount = 0
$errorCount = 0

Write-Host "Starting password migration..." -ForegroundColor Yellow

foreach ($employee in $employeeData.employees) {
    # Skip if already migrated
    if ($employee.PSObject.Properties.Name -contains "passwordHash" -and $employee.PSObject.Properties.Name -contains "salt") {
        Write-Host "Employee $($employee.code) already has hashed password, skipping" -ForegroundColor Gray
        $skippedCount++
        continue
    }
    
    # Skip if no password
    if (-not ($employee.PSObject.Properties.Name -contains "password") -or [string]::IsNullOrEmpty($employee.password)) {
        Write-Host "Employee $($employee.code) has no password, skipping" -ForegroundColor Yellow
        $skippedCount++
        continue
    }
    
    try {
        # Generate hash and salt
        $hashResult = Generate-PasswordHash -Password $employee.password
        
        # Add properties to employee object
        $employee | Add-Member -NotePropertyName "passwordHash" -NotePropertyValue $hashResult.Hash -Force
        $employee | Add-Member -NotePropertyName "salt" -NotePropertyValue $hashResult.Salt -Force
        
        # Don't remove original password yet to ensure backward compatibility during transition
        # Comment this line when you're ready to remove plaintext passwords
        # $employee.password = "[MIGRATED]"
        
        Write-Host "Migrated password for employee $($employee.code)" -ForegroundColor Green
        $migratedCount++
    } catch {
        Write-Host "Error migrating password for employee $($employee.code): $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
}

# Save updated employee codes
try {
    $employeeData | ConvertTo-Json -Depth 10 | Set-Content -Path $employeeCodesPath
    Write-Host "Successfully saved updated employee codes" -ForegroundColor Green
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
Write-Host "====================================================" -ForegroundColor Green
Write-Host "  Migration Summary" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host "Total employees: $employeeCount" -ForegroundColor Cyan
Write-Host "Passwords migrated: $migratedCount" -ForegroundColor Green
Write-Host "Employees skipped: $skippedCount" -ForegroundColor Yellow
Write-Host "Errors encountered: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "Password migration completed successfully!" -ForegroundColor Green
Write-Host ""

# Optional - Ask if plaintext passwords should be removed
$removePlaintext = Read-Host "Would you like to remove plaintext passwords now? (y/n)"
if ($removePlaintext -eq "y") {
    # Create another backup before removing plaintext passwords
    $backupPath2 = Join-Path $backupFolder "employee-codes_$timestamp-hashed.json.bak"
    Copy-Item -Path $employeeCodesPath -Destination $backupPath2
    
    # Remove plaintext passwords
    foreach ($employee in $employeeData.employees) {
        if ($employee.PSObject.Properties.Name -contains "password") {
            $employee.password = "[MIGRATED]"
        }
    }
    
    # Save again
    $employeeData | ConvertTo-Json -Depth 10 | Set-Content -Path $employeeCodesPath
    Write-Host "Plaintext passwords removed and replaced with [MIGRATED]" -ForegroundColor Green
}

Write-Host "Migration process complete. The system now supports both plaintext and hashed passwords for authentication." -ForegroundColor Cyan
