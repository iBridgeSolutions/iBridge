# Deploy iBridge Website to AWS S3 (iBridge Contact Solutions Bucket)
# This script uploads all website content to the S3 bucket and makes it public for static hosting.
# Usage: Run in the root of your website folder.

param(
    [string]$BucketName = "iBridge Contact Solutions",
    [string]$WebsiteDomain = "ibridgesolutions.co.za"
)

Write-Host "=== Deploying iBridge Website to AWS S3 ===" -ForegroundColor Cyan
Write-Host "Bucket: $BucketName" -ForegroundColor Yellow
Write-Host "Domain: $WebsiteDomain" -ForegroundColor Yellow

# Sync all files (HTML, CSS, JS, images, etc.) to the S3 bucket
aws s3 sync . "s3://$BucketName" --delete --exclude ".git/*" --acl public-read

Write-Host "\nAll website files have been uploaded to S3 bucket: $BucketName" -ForegroundColor Green
Write-Host "\nTo view your website, ensure your S3 bucket is configured for static website hosting and CloudFront is set up for $WebsiteDomain."
Write-Host "\nYou can now access your site at: https://$WebsiteDomain (after DNS/CloudFront propagation)"

# List all files uploaded
Write-Host "\n--- Website Content in S3 Bucket ---" -ForegroundColor Cyan
aws s3 ls "s3://$BucketName" --recursive

Write-Host "\n--- Deployment Complete ---" -ForegroundColor Green
