# Combined Setup Script for GitHub Pages, GoDaddy DNS, and AWS Integration
# This script guides you through the process of setting up your website with all three services
# Author: GitHub Copilot
# Date: June 18, 2025

# Header
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  GITHUB PAGES + GODADDY + AWS INTEGRATION SETUP" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host

# Domain configuration
$domain = "ibridgesolutions.co.za"
$wwwDomain = "www.$domain"
$githubUsername = "iBridgeSolutions"
$githubRepo = "iBridge"
$githubPagesUrl = "$githubUsername.github.io"

# GitHub Pages IP addresses
$githubPagesIPs = @(
    "185.199.108.153",
    "185.199.109.153",
    "185.199.110.153",
    "185.199.111.153"
)

#====================================
# STEP 1: GitHub Pages Setup
#====================================

Write-Host "STEP 1: GitHub Pages Setup" -ForegroundColor Green
Write-Host "---------------------------" -ForegroundColor Green
Write-Host

# Check if CNAME file exists
$cnameFile = "CNAME"
if (Test-Path $cnameFile) {
    $currentCname = Get-Content $cnameFile -Raw
    Write-Host "✓ CNAME file exists with content: $currentCname" -ForegroundColor Green
    
    if ($currentCname.Trim() -ne $domain) {
        Write-Host "! CNAME content doesn't match domain. Updating..." -ForegroundColor Yellow
        Set-Content -Path $cnameFile -Value $domain -NoNewline
        Write-Host "✓ Updated CNAME file to: $domain" -ForegroundColor Green
    }
} else {
    Write-Host "Creating CNAME file for GitHub Pages..." -ForegroundColor Yellow
    Set-Content -Path $cnameFile -Value $domain -NoNewline
    Write-Host "✓ Created CNAME file with content: $domain" -ForegroundColor Green
}

# Commit and push CNAME file if git is available
try {
    $gitVersion = git --version
    Write-Host "Git is installed: $gitVersion" -ForegroundColor Green
    
    $gitStatus = git status --porcelain
    if ($gitStatus -match "CNAME") {
        Write-Host "Committing and pushing CNAME changes to GitHub..." -ForegroundColor Yellow
        git add CNAME
        git commit -m "Add or update CNAME file for GitHub Pages custom domain"
        git push
        Write-Host "✓ CNAME file pushed to GitHub repository" -ForegroundColor Green
    } else {
        Write-Host "No changes to CNAME file detected" -ForegroundColor Green
    }
} catch {
    Write-Host "× Couldn't use git commands. Please manually commit and push the CNAME file." -ForegroundColor Red
}

Write-Host "`nGitHub Pages Actions:" -ForegroundColor Yellow
Write-Host "1. Go to your GitHub repository: https://github.com/$githubUsername/$githubRepo"
Write-Host "2. Navigate to 'Settings' > 'Pages'"
Write-Host "3. Ensure 'Source' is set to 'gh-pages' branch (or your deployment branch)"
Write-Host "4. In the 'Custom domain' field, ensure '$domain' is entered correctly"
Write-Host "5. Check 'Enforce HTTPS' once your DNS is properly configured"
Write-Host "6. Wait for GitHub to verify your custom domain (may take up to 24 hours)"
Write-Host

#====================================
# STEP 2: GoDaddy DNS Configuration
#====================================

Write-Host "STEP 2: GoDaddy DNS Configuration" -ForegroundColor Green
Write-Host "--------------------------------" -ForegroundColor Green
Write-Host

Write-Host "Log into your GoDaddy account and navigate to the DNS management for $domain" -ForegroundColor Yellow
Write-Host

Write-Host "For the root domain ($domain), add these A records:" -ForegroundColor White
foreach ($ip in $githubPagesIPs) {
    Write-Host "  - Type: A, Name: @, Value: $ip, TTL: 600 (or 1 Hour)" -ForegroundColor White
}

Write-Host "`nFor the www subdomain ($wwwDomain), add this CNAME record:" -ForegroundColor White
Write-Host "  - Type: CNAME, Name: www, Value: $githubPagesUrl, TTL: 600 (or 1 Hour)" -ForegroundColor White

Write-Host "`nDNS Check Commands:" -ForegroundColor Yellow
Write-Host "After configuring DNS, you can verify using these commands:" -ForegroundColor White
Write-Host "  nslookup $domain"
Write-Host "  nslookup $wwwDomain"

Write-Host "`nNote: DNS changes can take 24-48 hours to fully propagate globally" -ForegroundColor Yellow
Write-Host

#====================================
# STEP 3: AWS Integration (Optional)
#====================================

Write-Host "STEP 3: AWS Integration Options" -ForegroundColor Green
Write-Host "-----------------------------" -ForegroundColor Green
Write-Host

Write-Host "Option A: CloudFront CDN + S3 Backup" -ForegroundColor Yellow
Write-Host "You can use AWS CloudFront as a CDN in front of GitHub Pages:" -ForegroundColor White
Write-Host "1. Create an S3 bucket to store website files as a backup"
Write-Host "2. Set up a CloudFront distribution with:"
Write-Host "   - Origin domain: $domain"
Write-Host "   - Viewer protocol policy: Redirect HTTP to HTTPS"
Write-Host "   - Alternate domain names (CNAMEs): $domain, $wwwDomain"
Write-Host "3. Request an SSL certificate via AWS Certificate Manager (ACM)"
Write-Host "4. Update your S3 bucket policy to allow CloudFront access"

Write-Host "`nOption B: Only Use GitHub Pages" -ForegroundColor Yellow
Write-Host "If you prefer a simpler setup, you can use GitHub Pages directly with your domain." -ForegroundColor White
Write-Host "This is already covered in Steps 1 and 2."

Write-Host "`nYou have an existing 'aws-ssl-helper.ps1' script that can help set up AWS SSL," -ForegroundColor White
Write-Host "and 'github-aws-deploy.ps1' to help deploy to both GitHub and AWS." -ForegroundColor White
Write-Host

#====================================
# Verification Steps
#====================================

Write-Host "Final Verification Steps" -ForegroundColor Green
Write-Host "-----------------------" -ForegroundColor Green
Write-Host

Write-Host "1. Wait for DNS propagation (can take 24-48 hours)"
Write-Host "2. Visit https://$domain and verify it's working"
Write-Host "3. Visit https://$wwwDomain and verify it redirects properly"
Write-Host "4. Check the SSL certificate is valid"
Write-Host "5. Test the site on multiple devices and browsers"

Write-Host "`nUse the 'check-dns-propagation.ps1' script to monitor DNS propagation." -ForegroundColor Yellow

Write-Host "`n====================================================" -ForegroundColor Cyan
Write-Host "Setup guide completed! Follow the steps above to complete your configuration." -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
