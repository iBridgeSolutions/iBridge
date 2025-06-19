# Quick Fix Script for Website Accessibility
# This script will help make your website accessible at ibridgesolutions.co.za

$domainName = "ibridgesolutions.co.za"
$githubUser = "iBridgeSolutions" # Update this if different

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "   WEBSITE ACCESSIBILITY FIX   " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# Make sure CNAME is correct
$cnameContent = Get-Content -Path ".\CNAME" -ErrorAction SilentlyContinue
if ($cnameContent -ne $domainName) {
    Write-Host "Fixing CNAME file..." -ForegroundColor Yellow
    $domainName | Out-File -FilePath ".\CNAME" -NoNewline -Encoding utf8
    Write-Host "✅ CNAME file updated with: $domainName" -ForegroundColor Green
} else {
    Write-Host "✅ CNAME file is correct" -ForegroundColor Green
}

# Test the DNS configuration
Write-Host "`nChecking DNS configuration..."
$dnsRecords = Resolve-DnsName -Name $domainName -Type A -ErrorAction SilentlyContinue
$isGitHubPages = $false

if ($dnsRecords) {
    $githubPagesIPs = @(
        "185.199.108.153",
        "185.199.109.153", 
        "185.199.110.153", 
        "185.199.111.153"
    )
    
    foreach ($record in $dnsRecords) {
        if ($githubPagesIPs -contains $record.IPAddress) {
            $isGitHubPages = $true
            break
        }
    }
    
    if (-not $isGitHubPages) {
        Write-Host "❌ Your domain is NOT pointing to GitHub Pages" -ForegroundColor Red
        Write-Host "Current IP addresses:"
        $dnsRecords | ForEach-Object { Write-Host "  - $($_.IPAddress)" }
        
        Write-Host "`nYou need to update your DNS settings at GoDaddy to point to GitHub Pages:" -ForegroundColor Yellow
        Write-Host "1. Login to your GoDaddy account"
        Write-Host "2. Go to My Products > DNS > Manage DNS for $domainName"
        Write-Host "3. Delete all existing A records for the root domain"
        Write-Host "4. Add the following A records:"
        foreach ($ip in $githubPagesIPs) {
            Write-Host "   - Type: A, Host: @, Points to: $ip, TTL: 600 or 1 hour"
        }
        Write-Host "5. Add/update CNAME record:"
        Write-Host "   - Type: CNAME, Host: www, Points to: $githubUser.github.io, TTL: 600 or 1 hour"
    } else {
        Write-Host "✅ Your domain is correctly pointing to GitHub Pages" -ForegroundColor Green
    }
} else {
    Write-Host "❌ Could not retrieve DNS records for $domainName" -ForegroundColor Red
}

# Ensure website files are properly committed
Write-Host "`nChecking for uncommitted website files..."
$status = git status --porcelain
if ($status) {
    Write-Host "You have uncommitted files. Would you like to commit and push them now? (Y/N)"
    $commitNow = Read-Host
    
    if ($commitNow -eq "Y" -or $commitNow -eq "y") {
        git add .
        git commit -m "Fix website accessibility"
        git push
        Write-Host "✅ Changes committed and pushed" -ForegroundColor Green
    }
} else {
    Write-Host "✅ No uncommitted changes found" -ForegroundColor Green
}

Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host "   IMPORTANT NEXT STEPS:   " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "1. Make sure your GitHub repository is set to public"
Write-Host "2. Go to repository Settings > Pages"
Write-Host "3. Set Source to your main branch (or gh-pages branch)"
Write-Host "4. Enter Custom domain: $domainName"
Write-Host "5. Check 'Enforce HTTPS'"
Write-Host "6. Click 'Save'"
Write-Host "`nAfter completing these steps and updating DNS (if needed),"
Write-Host "your website should be accessible at https://$domainName"
Write-Host "Note: It may take up to 24 hours for DNS changes to propagate fully."
