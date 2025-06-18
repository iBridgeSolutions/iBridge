# GoDaddy DNS Fix Script

Write-Host "=== GoDaddy DNS Configuration Fix ===" -ForegroundColor Cyan
Write-Host "This script will provide specific steps to fix your GoDaddy DNS configuration" -ForegroundColor Cyan
Write-Host

# Expected values
$githubIPs = @(
    "185.199.108.153",
    "185.199.109.153", 
    "185.199.110.153", 
    "185.199.111.153"
)
$expectedCNAME = "ibridgesolutions.github.io"
$alternativeCNAME = "blxckukno.github.io"

# Check current DNS configuration
Write-Host "Checking current DNS configuration for ibridgesolutions.co.za..." -ForegroundColor Yellow

try {
    $aRecords = Resolve-DnsName -Name "ibridgesolutions.co.za" -Type A -ErrorAction SilentlyContinue
    
    Write-Host "Found A Records:" -ForegroundColor White
    $foundIPs = @()
    foreach ($record in $aRecords) {
        if ($record.Type -eq "A") {
            $foundIPs += $record.IPAddress
            Write-Host "  - $($record.IPAddress)"
        }
    }
    
    Write-Host "`nA Records Status:" -ForegroundColor Yellow
    $correctConfig = $false
    foreach ($ip in $githubIPs) {
        if ($foundIPs -contains $ip) {
            $correctConfig = $true
            Write-Host "  ✓ Found GitHub Pages IP: $ip" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Missing GitHub Pages IP: $ip" -ForegroundColor Red
        }
    }
    
    foreach ($ip in $foundIPs) {
        if ($githubIPs -notcontains $ip) {
            Write-Host "  ! Found non-GitHub Pages IP: $ip (should be removed)" -ForegroundColor Yellow
        }
    }
    
    # Check CNAME for www
    $cnameRecords = Resolve-DnsName -Name "www.ibridgesolutions.co.za" -Type CNAME -ErrorAction SilentlyContinue
    if ($cnameRecords) {
        $cname = ($cnameRecords | Where-Object { $_.Type -eq "CNAME" } | Select-Object -First 1).NameHost
        Write-Host "`nFound CNAME for www.ibridgesolutions.co.za:" -ForegroundColor White
        Write-Host "  - $cname"
        
        if (($cname -like "*$expectedCNAME*") -or ($cname -like "*$alternativeCNAME*")) {
            Write-Host "  ✓ CNAME is correctly configured" -ForegroundColor Green
        } else {
            Write-Host "  ✗ CNAME is not correctly configured. It should point to either:" -ForegroundColor Red
            Write-Host "    - $expectedCNAME (for iBridgeSolutions organization)" -ForegroundColor White
            Write-Host "    - $alternativeCNAME (for Blxckukno user)" -ForegroundColor White
        }
    } else {
        Write-Host "`nNo CNAME record found for www.ibridgesolutions.co.za" -ForegroundColor Red
    }
} catch {
    Write-Host "Error checking DNS: $_" -ForegroundColor Red
}

# Instructions to fix GoDaddy DNS
Write-Host "`n=== Steps to Fix GoDaddy DNS Configuration ===" -ForegroundColor Cyan

Write-Host "`n1. Log in to your GoDaddy account" -ForegroundColor White
Write-Host "`n2. Navigate to Domain Settings:" -ForegroundColor White
Write-Host "   - Go to 'My Products'" -ForegroundColor White
Write-Host "   - Find ibridgesolutions.co.za in your domains list" -ForegroundColor White
Write-Host "   - Click on 'DNS'" -ForegroundColor White

Write-Host "`n3. Update A Records:" -ForegroundColor White
Write-Host "   - Find and remove all existing A records for @ (these point to the wrong IPs)" -ForegroundColor White
Write-Host "   - Add these four A records instead:" -ForegroundColor White
foreach ($ip in $githubIPs) {
    Write-Host "     Type: A | Host: @ | Points to: $ip | TTL: 1 hour" -ForegroundColor Green
}

Write-Host "`n4. Update CNAME Record:" -ForegroundColor White
Write-Host "   - Find and remove any existing CNAME record for www" -ForegroundColor White
Write-Host "   - Add this CNAME record:" -ForegroundColor White
Write-Host "     Type: CNAME | Host: www | Points to: ibridgesolutions.github.io | TTL: 1 hour" -ForegroundColor Green

Write-Host "`n5. Save Changes:" -ForegroundColor White
Write-Host "   - Click 'Save' to apply these changes" -ForegroundColor White
Write-Host "   - Changes may take 24-48 hours to fully propagate" -ForegroundColor White

Write-Host "`n6. Additional GoDaddy Settings to Check:" -ForegroundColor White
Write-Host "   - Go to the Domain Manager for ibridgesolutions.co.za" -ForegroundColor White
Write-Host "   - Look for 'Website' or 'Website Builder' options" -ForegroundColor White
Write-Host "   - Disable any 'Website Redirect' if enabled" -ForegroundColor White
Write-Host "   - Turn off any 'Coming Soon' or 'Under Construction' pages" -ForegroundColor White
Write-Host "   - Make sure the domain is not using GoDaddy hosting (just DNS)" -ForegroundColor White

# Offer to open GoDaddy login
$openGoDaddy = Read-Host "`nWould you like to open GoDaddy login page to make these changes? (y/n)"
if ($openGoDaddy -eq "y") {
    Start-Process "https://sso.godaddy.com"
}

Write-Host "`nOnce you've made these DNS changes, wait for propagation and then check your website again." -ForegroundColor Cyan
Write-Host "You can run the simple-dns-check.ps1 script again later to verify the changes." -ForegroundColor Cyan
