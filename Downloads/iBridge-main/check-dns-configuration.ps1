# DNS Verification Tool for iBridge Website
# This script checks DNS configuration for your domain and subdomains

$domainName = "ibridgesolutions.co.za"
$githubUser = "iBridgeSolutions" # Replace with your actual GitHub username

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "   iBridge DNS CONFIGURATION CHECKER   " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# GitHub Pages IP addresses for reference
$githubPagesIPs = @(
    "185.199.108.153",
    "185.199.109.153", 
    "185.199.110.153", 
    "185.199.111.153"
)

# Function to check and display DNS records
function Test-DNSRecords {
    param(
        [string]$domain
    )
    
    Write-Host "Checking DNS configuration for $domain..." -ForegroundColor Yellow
    
    try {
        # Get A records
        $aRecords = Resolve-DnsName -Name $domain -Type A -ErrorAction Stop
        
        Write-Host "A Records:" -ForegroundColor Green
        $aRecords | ForEach-Object {
            $ip = $_.IPAddress
            $isGitHubIP = $githubPagesIPs -contains $ip
            
            if ($isGitHubIP) {
                Write-Host "  $ip ✅ (GitHub Pages)" -ForegroundColor Green
            } else {
                Write-Host "  $ip ❓ (Not a GitHub Pages IP)" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "  Could not resolve A records for $domain ❌" -ForegroundColor Red
    }
    
    try {
        # Get CNAME records for www
        if ($domain -notlike "www.*") {
            $wwwDomain = "www.$domain"
            $cnameRecords = Resolve-DnsName -Name $wwwDomain -Type CNAME -ErrorAction Stop
            
            Write-Host "`nCNAME Records for $($wwwDomain):" -ForegroundColor Green
            $cnameRecords | ForEach-Object {
                $target = $_.NameHost
                $isGitHubCNAME = $target -like "*github.io"
                
                if ($isGitHubCNAME) {
                    Write-Host "  $target ✅ (GitHub Pages)" -ForegroundColor Green
                } else {
                    Write-Host "  $target ❓ (Should point to $githubUser.github.io)" -ForegroundColor Yellow
                }
            }
        }
    }
    catch {
        Write-Host "  Could not resolve CNAME records for www.$domain ❌" -ForegroundColor Red
    }
}

# Check root domain
Write-Host "ROOT DOMAIN DNS CHECK" -ForegroundColor Cyan
Write-Host "-------------------" -ForegroundColor Cyan
Test-DNSRecords -domain $domainName

# Check CNAME configuration
Write-Host "`nGITHUB PAGES CNAME FILE CHECK" -ForegroundColor Cyan
Write-Host "--------------------------" -ForegroundColor Cyan

# Check if CNAME file exists locally with correct content
if (Test-Path ".\CNAME") {
    $cnameContent = Get-Content -Path ".\CNAME" -ErrorAction SilentlyContinue
    if ($cnameContent -eq $domainName) {
        Write-Host "Local CNAME file: ✅ ($cnameContent)" -ForegroundColor Green
    } else {
        Write-Host "Local CNAME file: ❌ (Content: $cnameContent, should be: $domainName)" -ForegroundColor Red
    }
} else {
    Write-Host "Local CNAME file: ❌ (Missing)" -ForegroundColor Red
}

Write-Host "`nGITHUB PAGES REQUIREMENTS" -ForegroundColor Cyan
Write-Host "------------------------" -ForegroundColor Cyan
Write-Host "For GitHub Pages to work with your custom domain, you need:"
Write-Host "1. CNAME file in repository root with content: $domainName"
Write-Host "2. DNS A records pointing to GitHub Pages IP addresses:"
$githubPagesIPs | ForEach-Object { Write-Host "   - $_" }
Write-Host "3. DNS CNAME record for 'www' pointing to: $githubUser.github.io"
Write-Host "4. Custom domain configured in GitHub repository settings"
Write-Host "5. Wait for DNS changes to propagate (up to 24-48 hours)"

Write-Host "`nWould you like to run a quick DNS propagation test? (Y/N)"
$testPropagation = Read-Host

if ($testPropagation -eq "Y" -or $testPropagation -eq "y") {
    Write-Host "`nTesting DNS propagation with dig..." -ForegroundColor Yellow
    
    # Try to use dig if available, otherwise use nslookup
    try {
        Write-Host "`nTesting from Google DNS (8.8.8.8):"
        nslookup $domainName 8.8.8.8
        
        Write-Host "`nTesting from Cloudflare DNS (1.1.1.1):"
        nslookup $domainName 1.1.1.1
    }
    catch {
        Write-Host "Could not run dig command. Using nslookup instead."
        nslookup $domainName
    }
    
    Write-Host "`n⚠️ Note: If you see inconsistent results, DNS is still propagating." -ForegroundColor Yellow
}

Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host "   DNS CHECK COMPLETE   " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
