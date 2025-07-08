# Intranet Directory Structure Verification Script
# This script verifies that all required files for the intranet are present
# and that server scripts use a consistent port

Write-Host "iBridge Intranet File Structure Verification" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Yellow

# Define the standard port that should be used across all server scripts
$STANDARD_PORT = 8090

# Define required files
$requiredFiles = @(
    "index.html",
    "company.html",
    "directory.html",
    "login.html",
    "data/organization.json",
    "data/employees.json",
    "data/departments.json",
    "data/settings.json",
    "partials/header.html",
    "css/intranet-styles.css"
)

# Navigate to the intranet directory
Set-Location -Path "$PSScriptRoot\intranet"
Write-Host "Checking files in: $(Get-Location)" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Yellow

$allFilesExist = $true
$missingFiles = @()

# Check each required file
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✓ Found: $file" -ForegroundColor Green
    } else {
        Write-Host "✗ Missing: $file" -ForegroundColor Red
        $allFilesExist = $false
        $missingFiles += $file
    }
}

# Summary
Write-Host "=============================================" -ForegroundColor Yellow
if ($allFilesExist) {
    Write-Host "All required files are present!" -ForegroundColor Green
} else {
    Write-Host "Some required files are missing!" -ForegroundColor Red
    Write-Host "Missing files: $($missingFiles -join ", ")" -ForegroundColor Red
}

# Check navigation paths in header.html
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "Checking navigation links in header.html..." -ForegroundColor Cyan

$headerContent = Get-Content -Path "partials/header.html" -Raw
if ($headerContent -match "/intranet/") {
    Write-Host "✗ Warning: Found absolute paths with '/intranet/' prefix in header.html" -ForegroundColor Red
    Write-Host "  These paths may cause 404 errors when served from within the intranet directory" -ForegroundColor Red
} else {
    Write-Host "✓ Navigation links look good" -ForegroundColor Green
}

Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "Checking server port consistency..." -ForegroundColor Cyan

# Reset location to project root
Set-Location -Path "$PSScriptRoot"

# Find all PowerShell and Batch files that might contain server configuration
$serverScripts = Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" -Recurse | Where-Object { 
    $content = Get-Content -Path $_.FullName -Raw
    $content -match "http-server" -or $content -match "start-process.*http" 
}

$batchFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.bat" -Recurse | Where-Object { 
    $content = Get-Content -Path $_.FullName -Raw
    $content -match "server" -or $content -match "http-server" 
}

$serverScripts += $batchFiles

$portUsage = @{}
$inconsistentPorts = $false

foreach ($script in $serverScripts) {
    $content = Get-Content -Path $script.FullName -Raw
    $relativePath = $script.FullName.Replace($PSScriptRoot, "").TrimStart("\")
    
    # Check for PowerShell port references
    $portMatches = [regex]::Matches($content, "-p\s+(\d+)")
    if ($portMatches.Count -gt 0) {
        $port = $portMatches[0].Groups[1].Value
        
        if (-not $portUsage.ContainsKey($port)) {
            $portUsage[$port] = @()
        }
        
        $portUsage[$port] += $relativePath
        
        if ($port -ne $STANDARD_PORT) {
            $inconsistentPorts = $true
        }
    }
    
    # Also check for PORT variable assignments
    $portVarMatches = [regex]::Matches($content, "\`$PORT\s*=\s*(\d+)")
    if ($portVarMatches.Count -gt 0) {
        $port = $portVarMatches[0].Groups[1].Value
        
        if (-not $portUsage.ContainsKey($port)) {
            $portUsage[$port] = @()
        }
        
        if ($portUsage[$port] -notcontains $relativePath) {
            $portUsage[$port] += $relativePath
        }
        
        if ($port -ne $STANDARD_PORT) {
            $inconsistentPorts = $true
        }
    }
}

# Report findings
if ($portUsage.Keys.Count -gt 0) {
    foreach ($port in $portUsage.Keys) {
        $scriptsCount = $portUsage[$port].Count
        $scriptsText = if ($scriptsCount -eq 1) { "script" } else { "scripts" }
        
        if ($port -eq $STANDARD_PORT) {
            Write-Host "Port $port (Standard): Used in $scriptsCount $scriptsText" -ForegroundColor Green
        } else {
            Write-Host "Port $port (Non-standard): Used in $scriptsCount $scriptsText" -ForegroundColor Red
        }
    }
    
    if ($inconsistentPorts) {
        Write-Host "`n✗ Warning: Found inconsistent port usage. All scripts should use port $STANDARD_PORT" -ForegroundColor Red
        Write-Host "  Run standardize-server-ports.ps1 to fix port inconsistencies" -ForegroundColor Yellow
    } else {
        Write-Host "`n✓ All scripts use the standard port ($STANDARD_PORT)" -ForegroundColor Green
    }
} else {
    Write-Host "No server scripts with port configuration found." -ForegroundColor Yellow
}

Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "RECOMMENDED APPROACH:" -ForegroundColor Green
Write-Host "Use the unified server to serve both main website and intranet:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Run the unified server:" -ForegroundColor White
Write-Host "   - Option 1: Run CHECK-AND-START-UNIFIED-SERVER.bat" -ForegroundColor White
Write-Host "   - Option 2: Run .\start-unified-server.ps1" -ForegroundColor White
Write-Host ""
Write-Host "2. Access your content:" -ForegroundColor White  
Write-Host "   - Main website: http://localhost:$STANDARD_PORT/" -ForegroundColor White  
Write-Host "   - Intranet portal: http://localhost:$STANDARD_PORT/intranet/" -ForegroundColor White
Write-Host ""
Write-Host "This ensures consistent navigation between main site and intranet" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Yellow
