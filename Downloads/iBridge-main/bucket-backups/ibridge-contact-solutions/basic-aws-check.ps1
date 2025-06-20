# Most Basic AWS Verification Script
# This script checks essential AWS components for ibridgesolutions.co.za

# Configuration
$accountId = "640825887118"
$s3BucketName = "ibridgesolutions-website-$accountId"
$region = "us-east-1"
$domainName = "ibridgesolutions.co.za"
$wwwDomainName = "www.ibridgesolutions.co.za"

# Header
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "      AWS DEPLOYMENT STATUS FOR IBRIDGESOLUTIONS   " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Account ID: 6408-2588-7118" -ForegroundColor Yellow
Write-Host "Domain: $domainName" -ForegroundColor Yellow
Write-Host

# Check AWS CLI
Write-Host "Checking AWS CLI..." -ForegroundColor Yellow
try {
    $awsVersion = aws --version
    Write-Host "✓ AWS CLI is installed" -ForegroundColor Green
}
catch {
    Write-Host "✗ AWS CLI is not installed" -ForegroundColor Red
    exit
}

# Check S3 Bucket
Write-Host "`nChecking S3 bucket..." -ForegroundColor Yellow
try {
    $result = aws s3api head-bucket --bucket $s3BucketName 2>&1
    Write-Host "✓ S3 bucket exists" -ForegroundColor Green
}
catch {
    Write-Host "✗ S3 bucket does not exist" -ForegroundColor Red
    Write-Host "  Run the deployment script to create the bucket" -ForegroundColor Yellow
}

# Check CloudFront
Write-Host "`nChecking CloudFront distribution..." -ForegroundColor Yellow
try {
    $result = aws cloudfront list-distributions
    if ($result -match $domainName) {
        Write-Host "✓ CloudFront distribution found" -ForegroundColor Green
    }
    else {
        Write-Host "✗ No CloudFront distribution found for $domainName" -ForegroundColor Red
        Write-Host "  Run the deployment script to create the distribution" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "✗ Error checking CloudFront" -ForegroundColor Red
}

# Check SSL Certificate
Write-Host "`nChecking SSL certificate..." -ForegroundColor Yellow
try {
    $result = aws acm list-certificates --region $region
    if ($result -match $domainName) {
        Write-Host "✓ SSL certificate found" -ForegroundColor Green
    }
    else {
        Write-Host "✗ No SSL certificate found for $domainName" -ForegroundColor Red
        Write-Host "  Run the deployment script to request a certificate" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "✗ Error checking SSL certificates" -ForegroundColor Red
}

# Check DNS
Write-Host "`nChecking DNS resolution..." -ForegroundColor Yellow
try {
    $result = Resolve-DnsName -Name $domainName -ErrorAction SilentlyContinue
    if ($result) {
        Write-Host "✓ Domain $domainName resolves successfully" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Domain $domainName does not resolve" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ Error checking domain DNS" -ForegroundColor Red
}

try {
    $result = Resolve-DnsName -Name $wwwDomainName -ErrorAction SilentlyContinue
    if ($result) {
        Write-Host "✓ Domain $wwwDomainName resolves successfully" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Domain $wwwDomainName does not resolve" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ Error checking www domain DNS" -ForegroundColor Red
}

# Next Steps
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "                   NEXT STEPS                     " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host
Write-Host "1. To run the full deployment script:" -ForegroundColor Yellow
Write-Host "   PowerShell -ExecutionPolicy Bypass -File .\deploy-with-account-id.ps1" -ForegroundColor White
Write-Host
Write-Host "2. To update your website files:" -ForegroundColor Yellow
Write-Host "   PowerShell -ExecutionPolicy Bypass -File .\simple-aws-deploy.ps1" -ForegroundColor White
Write-Host
Write-Host "3. To check certificate validation:" -ForegroundColor Yellow
Write-Host "   PowerShell -ExecutionPolicy Bypass -File .\check-certificate-validation.ps1" -ForegroundColor White
Write-Host
Write-Host "For full documentation, see the AWS-DEPLOYMENT-GUIDE.md file" -ForegroundColor Cyan
