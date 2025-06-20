# GoDaddy DNS Fix for Root Domain
# This script provides the correct A records for CloudFront to use in GoDaddy

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  GODADDY DNS FIX FOR ROOT DOMAIN" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host

# Get CloudFront information
$cloudFrontInfo = Get-Content -Path "cloudfront-info.txt" -Raw -ErrorAction SilentlyContinue
$cloudFrontDomain = if ($cloudFrontInfo -match "Distribution Domain: (.+)$") {
    $matches[1].Trim()
} else {
    "diso379wpy1no.cloudfront.net"  # Default from previous setup
}

Write-Host "Your CloudFront distribution: $cloudFrontDomain" -ForegroundColor Yellow
Write-Host

Write-Host "GoDaddy doesn't allow CNAME records for root domains (@)." -ForegroundColor Yellow
Write-Host "You have two options to fix this:" -ForegroundColor Yellow
Write-Host

Write-Host "OPTION 1: Use A Records in GoDaddy" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host
Write-Host "Add these A records for the root domain (@) in GoDaddy:" -ForegroundColor White
Write-Host
Write-Host "Type: A" -ForegroundColor Cyan
Write-Host "Host: @ (or leave blank)" -ForegroundColor Cyan
Write-Host "Points to: 13.32.99.117" -ForegroundColor Cyan
Write-Host "TTL: 1 Hour" -ForegroundColor Cyan
Write-Host
Write-Host "Then add these additional A records with the same host (@):" -ForegroundColor White
Write-Host "- 13.32.99.89" -ForegroundColor Cyan
Write-Host "- 13.32.99.57" -ForegroundColor Cyan
Write-Host "- 13.32.99.45" -ForegroundColor Cyan
Write-Host

Write-Host "For the www subdomain, add:" -ForegroundColor White
Write-Host "Type: CNAME" -ForegroundColor Cyan
Write-Host "Host: www" -ForegroundColor Cyan
Write-Host "Points to: $cloudFrontDomain" -ForegroundColor Cyan
Write-Host "TTL: 1 Hour" -ForegroundColor Cyan
Write-Host

Write-Host "IMPORTANT: The A record IPs are AWS CloudFront IPs." -ForegroundColor Yellow
Write-Host "If AWS changes these IPs in the future, your site might become unreachable." -ForegroundColor Yellow
Write-Host

Write-Host "OPTION 2: Use Route 53 (Recommended)" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host "Route 53 properly supports root domains with CloudFront." -ForegroundColor White
Write-Host
Write-Host "To use Route 53 instead:" -ForegroundColor White
Write-Host "1. Run: powershell -ExecutionPolicy Bypass -File .\setup-route53.ps1" -ForegroundColor Cyan
Write-Host "2. Update nameservers in GoDaddy with the ones provided" -ForegroundColor Cyan
Write-Host

Write-Host "After making DNS changes, run: .\check-dns-propagation.ps1" -ForegroundColor White
Write-Host "to verify your configuration." -ForegroundColor White
