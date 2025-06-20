# Simple DNS Check for ibridgesolutions.co.za

Write-Host "=== Simple DNS Check for ibridgesolutions.co.za ===" -ForegroundColor Cyan
Write-Host

# Check A Records
Write-Host "Checking A Records for ibridgesolutions.co.za..." -ForegroundColor Yellow
try {
    $aRecords = Resolve-DnsName -Name "ibridgesolutions.co.za" -Type A -ErrorAction Stop
    
    Write-Host "Found A Records:" -ForegroundColor Green
    $aRecords | ForEach-Object {
        Write-Host "  - $($_.IPAddress)"
    }
    
    # Check if any of the GitHub Pages IPs are present
    $githubIPs = @(
        "185.199.108.153",
        "185.199.109.153",
        "185.199.110.153",
        "185.199.111.153"
    )
    
    $foundGitHubIP = $false
    foreach ($record in $aRecords) {
        if ($githubIPs -contains $record.IPAddress) {
            $foundGitHubIP = $true
            break
        }
    }
    
    if ($foundGitHubIP) {
        Write-Host "✓ At least one GitHub Pages IP found. A records look good!" -ForegroundColor Green
    } else {
        Write-Host "✗ No GitHub Pages IPs found. A records may not be configured correctly." -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Could not resolve A records for ibridgesolutions.co.za" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Check CNAME Record
Write-Host "`nChecking CNAME Record for www.ibridgesolutions.co.za..." -ForegroundColor Yellow
try {
    $cnameRecord = Resolve-DnsName -Name "www.ibridgesolutions.co.za" -Type CNAME -ErrorAction Stop
    
    Write-Host "Found CNAME Record:" -ForegroundColor Green
    Write-Host "  - $($cnameRecord.NameHost)"
    
    if ($cnameRecord.NameHost -like "*blxckukno.github.io*") {
        Write-Host "✓ CNAME is correctly pointing to blxckukno.github.io" -ForegroundColor Green
    } else {
        Write-Host "✗ CNAME is not pointing to blxckukno.github.io" -ForegroundColor Red
        Write-Host "  It's currently pointing to: $($cnameRecord.NameHost)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Could not resolve CNAME record for www.ibridgesolutions.co.za" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
}

Write-Host "`nReminder: DNS changes can take 24-48 hours to fully propagate."
