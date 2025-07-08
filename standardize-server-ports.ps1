# Port Standardization Script for iBridge Website & Intranet
# This script scans all server scripts and ensures they use the standard port (8090)

# Configuration
$STANDARD_PORT = 8090
$PROJECT_ROOT = $PSScriptRoot

# Color configuration
$colors = @{
    'Title' = 'Magenta'
    'Info' = 'Cyan' 
    'Success' = 'Green'
    'Warning' = 'Yellow'
    'Error' = 'Red'
}

# Display banner
Write-Host "=======================================================" -ForegroundColor $colors.Title
Write-Host "       iBridge Server Port Standardization Tool        " -ForegroundColor $colors.Title
Write-Host "=======================================================" -ForegroundColor $colors.Title
Write-Host "This script will ensure all server scripts use port $STANDARD_PORT" -ForegroundColor $colors.Info
Write-Host "=======================================================" -ForegroundColor $colors.Title

# Find all PowerShell and Batch files that might contain server configuration
Write-Host "Scanning for server scripts..." -ForegroundColor $colors.Info
$serverScripts = Get-ChildItem -Path $PROJECT_ROOT -Filter "*.ps1" -Recurse | Where-Object { 
    $content = Get-Content -Path $_.FullName -Raw
    $content -match "http-server" -or $content -match "start-process.*http" 
}

$batchFiles = Get-ChildItem -Path $PROJECT_ROOT -Filter "*.bat" -Recurse | Where-Object { 
    $content = Get-Content -Path $_.FullName -Raw
    $content -match "server" -or $content -match "start.*" -or $content -match "http-server" 
}

$serverScripts += $batchFiles

# Analyze port usage
Write-Host "`nAnalyzing port usage in server scripts..." -ForegroundColor $colors.Info
Write-Host "-------------------------------------------------------" -ForegroundColor $colors.Title

$portUsage = @{}
$inconsistentPorts = $false

foreach ($script in $serverScripts) {
    $content = Get-Content -Path $script.FullName -Raw
    $portMatches = [regex]::Matches($content, "-p\s+(\d+)")
    
    if ($portMatches.Count -gt 0) {
        $port = $portMatches[0].Groups[1].Value
        
        if (-not $portUsage.ContainsKey($port)) {
            $portUsage[$port] = @()
        }
        
        $relativePath = $script.FullName.Replace($PROJECT_ROOT, "").TrimStart("\")
        $portUsage[$port] += $relativePath
        
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
            Write-Host "Port $port (Standard): Used in $scriptsCount $scriptsText" -ForegroundColor $colors.Success
        } else {
            Write-Host "Port $port (Non-standard): Used in $scriptsCount $scriptsText" -ForegroundColor $colors.Warning
        }
        
        foreach ($script in $portUsage[$port]) {
            if ($port -eq $STANDARD_PORT) {
                Write-Host "  ✓ $script" -ForegroundColor $colors.Success
            } else {
                Write-Host "  ✗ $script" -ForegroundColor $colors.Warning
            }
        }
    }
} else {
    Write-Host "No server scripts with port configuration found." -ForegroundColor $colors.Info
}

# Offer to fix non-standard ports
if ($inconsistentPorts) {
    Write-Host "`nWould you like to standardize all scripts to use port $STANDARD_PORT? (Y/N)" -ForegroundColor $colors.Info
    $response = Read-Host
    
    if ($response -eq "Y" -or $response -eq "y") {
        Write-Host "`nUpdating scripts to use port $STANDARD_PORT..." -ForegroundColor $colors.Info
        
        foreach ($port in $portUsage.Keys) {
            if ($port -ne $STANDARD_PORT) {
                foreach ($script in $portUsage[$port]) {
                    $fullPath = Join-Path -Path $PROJECT_ROOT -ChildPath $script
                    $content = Get-Content -Path $fullPath -Raw
                    
                    # Replace port in PowerShell scripts
                    if ($script -match "\.ps1$") {
                        $updatedContent = $content -replace "-p\s+$port", "-p $STANDARD_PORT"
                        $updatedContent = $updatedContent -replace "PORT\s*=\s*$port", "PORT = $STANDARD_PORT"
                    }
                    # Replace port in Batch files
                    else {
                        $updatedContent = $content -replace "port\s+$port", "port $STANDARD_PORT"
                        $updatedContent = $updatedContent -replace "$port/", "$STANDARD_PORT/"
                    }
                    
                    Set-Content -Path $fullPath -Value $updatedContent
                    Write-Host "  ✓ Updated $script to use port $STANDARD_PORT" -ForegroundColor $colors.Success
                }
            }
        }
        
        Write-Host "`nAll scripts have been updated to use port $STANDARD_PORT" -ForegroundColor $colors.Success
    } else {
        Write-Host "`nNo changes were made. Scripts continue to use different ports." -ForegroundColor $colors.Info
    }
} else {
    Write-Host "`nAll scripts already use the standard port ($STANDARD_PORT)" -ForegroundColor $colors.Success
}

Write-Host "`nIt is recommended to use the unified server approach:" -ForegroundColor $colors.Info
Write-Host "1. Run CHECK-AND-START-UNIFIED-SERVER.bat" -ForegroundColor $colors.Info
Write-Host "2. Access the main website at: http://localhost:$STANDARD_PORT/" -ForegroundColor $colors.Info
Write-Host "3. Access the intranet at: http://localhost:$STANDARD_PORT/intranet/" -ForegroundColor $colors.Info
Write-Host "=======================================================" -ForegroundColor $colors.Title
