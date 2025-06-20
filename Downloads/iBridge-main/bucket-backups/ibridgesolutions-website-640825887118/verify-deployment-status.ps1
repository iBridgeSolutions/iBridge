# AWS Deployment Verification Script
# This script checks the status of S3, CloudFront, and DNS for ibridgesolutions.co.za

$awsExePath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"

function Write-Header {
    param (
        [string]$title
    )
    
    Write-Host "`n=================================================" -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host "=================================================" -ForegroundColor Cyan
}

Write-Header "AWS DEPLOYMENT VERIFICATION"

# Check if CloudFront info file exists
Write-Host "`nChecking CloudFront setup..." -ForegroundColor Yellow
if (Test-Path "cloudfront-info.txt") {
    Write-Host "CloudFront information file found." -ForegroundColor Green
    Get-Content -Path "cloudfront-info.txt" | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Cyan
    }
    
    # Extract the CloudFront domain
    $cloudfrontInfo = Get-Content -Path "cloudfront-info.txt" -Raw
    $cloudfrontDomain = if ($cloudfrontInfo -match 'Distribution Domain:\s*(.+)') { $matches[1].Trim() } else { "unknown" }
    
    # Display DNS configuration instructions
    Write-Host "`nDNS Configuration Status:" -ForegroundColor Yellow
    Write-Host "To complete the deployment, update your GoDaddy DNS records:" -ForegroundColor White
    
    Write-Host "  For www subdomain: CNAME record pointing to $cloudfrontDomain" -ForegroundColor White
    Write-Host "  For root domain: CNAME record pointing to $cloudfrontDomain (if supported)" -ForegroundColor White
    
    Write-Host "`nImportant DNS Notes:" -ForegroundColor Yellow
    Write-Host "  1. GoDaddy may not support CNAME for root domains" -ForegroundColor White
    Write-Host "  2. DNS changes can take 24-48 hours to fully propagate" -ForegroundColor White
    Write-Host "  3. Consider using Route 53 for better control over your DNS" -ForegroundColor White
    
    # Test URLs
    Write-Host "`nAfter DNS propagation, test these URLs:" -ForegroundColor Yellow
    Write-Host "  CloudFront URL: https://$cloudfrontDomain" -ForegroundColor White
    Write-Host "  Domain: https://ibridgesolutions.co.za" -ForegroundColor White
    Write-Host "  WWW Domain: https://www.ibridgesolutions.co.za" -ForegroundColor White
    Write-Host "  Test path that previously failed: https://ibridgesolutions.co.za/lander" -ForegroundColor White
} else {
    Write-Host "CloudFront information file not found. Have you run simplified-cloudfront-setup.ps1?" -ForegroundColor Red
}

# Check SSL certificate status
Write-Host "`nChecking SSL certificate status..." -ForegroundColor Yellow
if (Test-Path "certificate-arn.txt") {
    $certificateArn = Get-Content -Path "certificate-arn.txt" -Raw
    $certificateArn = $certificateArn.Trim()
    Write-Host "Certificate ARN: $certificateArn" -ForegroundColor Cyan
    
    Write-Host "`nTo manually check certificate status, run:" -ForegroundColor White
    Write-Host "& '$awsExePath' acm describe-certificate --certificate-arn '$certificateArn' --region us-east-1" -ForegroundColor White
} else {
    Write-Host "Certificate ARN file not found." -ForegroundColor Red
}

# Provide redirect testing instructions
Write-Host "`nRedirect Test Instructions:" -ForegroundColor Yellow
Write-Host "Once DNS is configured, verify the /lander redirect is working:" -ForegroundColor White
Write-Host "  1. Open a web browser and go to https://ibridgesolutions.co.za/lander" -ForegroundColor White
Write-Host "  2. The page should load correctly without redirecting to GitHub Pages" -ForegroundColor White
Write-Host "  3. You can also check https://www.ibridgesolutions.co.za/lander" -ForegroundColor White

Write-Header "NEXT STEPS"
Write-Host "1. Finish configuring DNS in GoDaddy" -ForegroundColor Green
Write-Host "2. Wait for DNS propagation (24-48 hours)" -ForegroundColor Green
Write-Host "3. Test the website with the URLs above" -ForegroundColor Green
Write-Host "4. Verify the /lander redirect is working correctly" -ForegroundColor Green
