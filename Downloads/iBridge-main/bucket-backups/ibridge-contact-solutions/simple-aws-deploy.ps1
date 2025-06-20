# Simple AWS S3 Deployment Script for iBridge Solutions
# This script uploads files to S3 and invalidates CloudFront cache

# Configuration
$websiteFolder = "c:\Users\Lwandile Gasela\Downloads\iBridge-main\iBridge-main\iBridge-main" 
$s3BucketName = "ibridgesolutions-website-640825887118"

# Explanation
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "    SIMPLE AWS DEPLOYMENT FOR IBRIDGESOLUTIONS    " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host
Write-Host "This script will:" -ForegroundColor Yellow
Write-Host "1. Upload your website files to the S3 bucket" -ForegroundColor Yellow
Write-Host "2. Invalidate the CloudFront cache" -ForegroundColor Yellow
Write-Host

# Prompt for CloudFront distribution ID
$distributionId = Read-Host "Enter your CloudFront distribution ID"

# Upload files to S3
Write-Host "`nUploading files to S3..." -ForegroundColor Cyan
aws s3 sync $websiteFolder s3://$s3BucketName --delete

# Check if upload was successful
if ($?) {
    Write-Host "✓ Files uploaded successfully!" -ForegroundColor Green
} else {
    Write-Host "✗ Error uploading files. Check AWS CLI configuration." -ForegroundColor Red
    exit
}

# Invalidate CloudFront cache
Write-Host "`nInvalidating CloudFront cache..." -ForegroundColor Cyan
aws cloudfront create-invalidation --distribution-id $distributionId --paths "/*"

# Check if invalidation was successful
if ($?) {
    Write-Host "✓ Cache invalidation request submitted successfully!" -ForegroundColor Green
    Write-Host "  (It may take a few minutes for changes to propagate)" -ForegroundColor Yellow
} else {
    Write-Host "✗ Error invalidating cache. Check distribution ID." -ForegroundColor Red
}

Write-Host "`nYour website should be updated at:" -ForegroundColor Green
Write-Host "https://ibridgesolutions.co.za" -ForegroundColor Cyan
