# Simple GoDaddy DNS A Records Setup Script
# This script helps set up the A records in GoDaddy for CloudFront

# Header
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  GODADDY A RECORDS SETUP FOR ROOT DOMAIN" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host

# Get CloudFront domain from file
$cloudFrontInfo = Get-Content -Path "cloudfront-info.txt" -Raw -ErrorAction SilentlyContinue
$cloudFrontDomain = if ($cloudFrontInfo -match "Distribution Domain: (.+)$") {
    $matches[1].Trim()
} else {
    "diso379wpy1no.cloudfront.net"  # Default value from previous setup
}

Write-Host "Follow these steps in GoDaddy's DNS management interface:" -ForegroundColor Yellow
Write-Host

Write-Host "STEP 1: Add A Records for Root Domain" -ForegroundColor Green
Write-Host "-----------------------------------" -ForegroundColor Green
Write-Host
Write-Host "Add these four A records for the root domain (@):" -ForegroundColor White
Write-Host

$aRecords = @(
    "13.32.99.117",
    "13.32.99.89",
    "13.32.99.57",
    "13.32.99.45"
)

foreach ($ip in $aRecords) {
    Write-Host "Record #$(([array]::IndexOf($aRecords, $ip))+1):" -ForegroundColor Cyan
    Write-Host "  Type: A" -ForegroundColor White
    Write-Host "  Host: @ (or leave blank for root domain)" -ForegroundColor White
    Write-Host "  Points To: $ip" -ForegroundColor White
    Write-Host "  TTL: 1 Hour" -ForegroundColor White
    Write-Host
}

Write-Host "STEP 2: Add CNAME Record for WWW Subdomain" -ForegroundColor Green
Write-Host "------------------------------------------" -ForegroundColor Green
Write-Host
Write-Host "Add this CNAME record for www:" -ForegroundColor White
Write-Host "  Type: CNAME" -ForegroundColor Cyan
Write-Host "  Host: www" -ForegroundColor Cyan
Write-Host "  Points To: $cloudFrontDomain" -ForegroundColor Cyan
Write-Host "  TTL: 1 Hour" -ForegroundColor Cyan
Write-Host

Write-Host "STEP 3: Remove any existing TXT or Forwarding Records" -ForegroundColor Green
Write-Host "------------------------------------------------" -ForegroundColor Green
Write-Host "Check if there are any existing TXT records or forwarding settings" -ForegroundColor White
Write-Host "that might be redirecting your domain. Remove any GitHub Pages related records." -ForegroundColor White
Write-Host

Write-Host "STEP 4: Wait for DNS Propagation" -ForegroundColor Green
Write-Host "--------------------------------" -ForegroundColor Green
Write-Host "DNS changes can take 24-48 hours to fully propagate." -ForegroundColor White
Write-Host "After making changes, run: .\check-dns-propagation.ps1" -ForegroundColor White
Write-Host "to verify your configuration." -ForegroundColor White
Write-Host

# Save instructions to a file for reference
$instructions = @"
GoDaddy DNS Configuration for Root Domain
=======================================

STEP 1: Add A Records for Root Domain
-----------------------------------
Add these four A records for the root domain (@):

Record #1:
  Type: A
  Host: @ (or leave blank for root domain)
  Points To: 13.32.99.117
  TTL: 1 Hour

Record #2:
  Type: A
  Host: @ (or leave blank for root domain)
  Points To: 13.32.99.89
  TTL: 1 Hour

Record #3:
  Type: A
  Host: @ (or leave blank for root domain)
  Points To: 13.32.99.57
  TTL: 1 Hour

Record #4:
  Type: A
  Host: @ (or leave blank for root domain)
  Points To: 13.32.99.45
  TTL: 1 Hour

STEP 2: Add CNAME Record for WWW Subdomain
------------------------------------------
Add this CNAME record for www:
  Type: CNAME
  Host: www
  Points To: $cloudFrontDomain
  TTL: 1 Hour

After making these changes, wait 24-48 hours for DNS propagation.
"@

$instructions | Out-File -FilePath "godaddy-a-records-instructions.txt" -Encoding ascii
Write-Host "Instructions saved to godaddy-a-records-instructions.txt" -ForegroundColor Green
