# Simple AWS Deployment Verification Script
# This script checks your AWS deployment status for ibridgesolutions.co.za

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
    Write-Host "✓ AWS CLI is installed: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ AWS CLI is not installed. Please install AWS CLI first." -ForegroundColor Red
    exit
}

# Check AWS Credentials
Write-Host "`nChecking AWS credentials..." -ForegroundColor Yellow
try {
    $configStatus = aws configure list
    if ($configStatus -match "access_key") {
        Write-Host "✓ AWS credentials are configured" -ForegroundColor Green
    } else {
        Write-Host "✗ AWS credentials are not configured. Run 'aws configure' first." -ForegroundColor Red
        exit
    }
} catch {
    Write-Host "✗ Error checking AWS credentials" -ForegroundColor Red
    exit
}

# Check S3 Bucket
Write-Host "`nChecking S3 bucket ($s3BucketName)..." -ForegroundColor Yellow
try {
    $bucketResult = aws s3api head-bucket --bucket $s3BucketName 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ S3 bucket exists" -ForegroundColor Green
        
        # Check for website configuration
        try {
            $websiteResult = aws s3api get-bucket-website --bucket $s3BucketName 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ S3 bucket is configured for website hosting" -ForegroundColor Green
            } else {
                Write-Host "✗ S3 bucket is not configured for website hosting" -ForegroundColor Red
            }
        } catch {
            Write-Host "✗ Error checking website configuration" -ForegroundColor Red
        }
        
        # Check for files
        try {
            $objects = aws s3 ls s3://$s3BucketName --recursive
            if ($objects) {
                $objectCount = ($objects | Measure-Object -Line).Lines
                Write-Host "✓ S3 bucket contains $objectCount files" -ForegroundColor Green
            } else {
                Write-Host "✗ S3 bucket is empty" -ForegroundColor Red
            }
        } catch {
            Write-Host "✗ Error checking bucket contents" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ S3 bucket does not exist" -ForegroundColor Red
        Write-Host "  Run the deployment script to create the S3 bucket" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Error checking S3 bucket" -ForegroundColor Red
}

# Check CloudFront Distribution
Write-Host "`nChecking CloudFront distribution..." -ForegroundColor Yellow
$foundDistribution = $false
$distributionId = ""
$distributionDomain = ""

try {
    $distributions = aws cloudfront list-distributions
    if ($distributions -match $domainName) {
        Write-Host "✓ CloudFront distribution found for $domainName" -ForegroundColor Green
        $foundDistribution = $true
        
        # Try to extract distribution ID and domain
        if ($distributions -match "Id: ([A-Z0-9]+)") {
            $distributionId = $Matches[1]
            Write-Host "  Distribution ID: $distributionId" -ForegroundColor Cyan
        }
        
        if ($distributions -match "DomainName: ([a-z0-9.]+\.cloudfront\.net)") {
            $distributionDomain = $Matches[1]
            Write-Host "  Distribution Domain: $distributionDomain" -ForegroundColor Cyan
        }
    } else {
        Write-Host "✗ No CloudFront distribution found for $domainName" -ForegroundColor Red
        Write-Host "  Run the deployment script to create the CloudFront distribution" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Error checking CloudFront" -ForegroundColor Red
}

# Check SSL Certificate
Write-Host "`nChecking SSL certificate..." -ForegroundColor Yellow
try {
    $certificates = aws acm list-certificates --region $region
    if ($certificates -match $domainName) {
        Write-Host "✓ SSL certificate found for $domainName" -ForegroundColor Green
    } else {
        Write-Host "✗ No SSL certificate found for $domainName" -ForegroundColor Red
        Write-Host "  Run the deployment script to request an SSL certificate" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Error checking SSL certificates" -ForegroundColor Red
}

# Check DNS Settings
Write-Host "`nChecking DNS settings..." -ForegroundColor Yellow
if ($foundDistribution -and $distributionDomain) {
    # Check apex domain
    try {
        $apexDns = Resolve-DnsName -Name $domainName -ErrorAction SilentlyContinue
        if ($apexDns) {
            Write-Host "✓ Domain $domainName resolves successfully" -ForegroundColor Green
            
            # Try to check if it points to CloudFront
            $dnsOutput = $apexDns | Out-String
            if ($dnsOutput -match $distributionDomain -or $dnsOutput -match "cloudfront") {
                Write-Host "✓ Domain appears to point to CloudFront" -ForegroundColor Green
            } else {
                Write-Host "! Domain may not be pointing to CloudFront" -ForegroundColor Yellow
            }
        } else {
            Write-Host "✗ Domain $domainName does not resolve" -ForegroundColor Red
            Write-Host "  Update your DNS settings to point to CloudFront" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ Error checking apex domain DNS" -ForegroundColor Red
    }
    
    # Check www subdomain
    try {
        $wwwDns = Resolve-DnsName -Name $wwwDomainName -ErrorAction SilentlyContinue
        if ($wwwDns) {
            Write-Host "✓ Domain $wwwDomainName resolves successfully" -ForegroundColor Green
            
            # Try to check if it points to CloudFront
            $dnsOutput = $wwwDns | Out-String
            if ($dnsOutput -match $distributionDomain -or $dnsOutput -match "cloudfront") {
                Write-Host "✓ WWW domain appears to point to CloudFront" -ForegroundColor Green
            } else {
                Write-Host "! WWW domain may not be pointing to CloudFront" -ForegroundColor Yellow
            }
        } else {
            Write-Host "✗ Domain $wwwDomainName does not resolve" -ForegroundColor Red
            Write-Host "  Update your DNS settings to point to CloudFront" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ Error checking www domain DNS" -ForegroundColor Red
    }
} else {
    Write-Host "  Skipping DNS check (CloudFront distribution not found)" -ForegroundColor Yellow
}

# Check Website Accessibility
Write-Host "`nChecking website accessibility..." -ForegroundColor Yellow

# Test apex domain
try {
    $webRequest = [System.Net.WebRequest]::Create("https://$domainName")
    $webRequest.Method = "HEAD"
    $webRequest.AllowAutoRedirect = $false
    $webRequest.Timeout = 5000
    
    try {
        $response = $webRequest.GetResponse()
        $statusCode = [int]$response.StatusCode
        Write-Host "✓ Website is accessible at https://$domainName" -ForegroundColor Green
        Write-Host "  Status: $($response.StatusCode) ($statusCode)" -ForegroundColor Green
        $response.Close()
    } catch [System.Net.WebException] {
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            Write-Host "! Website returns status code: $($_.Exception.Response.StatusCode) ($statusCode)" -ForegroundColor Yellow
            
            if ($_.Exception.Response.Headers["Location"] -match "/lander") {
                Write-Host "✗ Website is still redirecting to /lander" -ForegroundColor Red
                Write-Host "  Check GoDaddy for redirect settings" -ForegroundColor Yellow
            }
        } else {
            Write-Host "✗ Website is not accessible: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "✗ Error testing website" -ForegroundColor Red
}

# Test www domain
try {
    $webRequest = [System.Net.WebRequest]::Create("https://$wwwDomainName")
    $webRequest.Method = "HEAD"
    $webRequest.AllowAutoRedirect = $false
    $webRequest.Timeout = 5000
    
    try {
        $response = $webRequest.GetResponse()
        $statusCode = [int]$response.StatusCode
        Write-Host "✓ Website is accessible at https://$wwwDomainName" -ForegroundColor Green
        Write-Host "  Status: $($response.StatusCode) ($statusCode)" -ForegroundColor Green
        $response.Close()
    } catch [System.Net.WebException] {
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            Write-Host "! WWW domain returns status code: $($_.Exception.Response.StatusCode) ($statusCode)" -ForegroundColor Yellow
            
            if ($_.Exception.Response.Headers["Location"] -match "/lander") {
                Write-Host "✗ WWW domain is still redirecting to /lander" -ForegroundColor Red
                Write-Host "  Check GoDaddy for redirect settings" -ForegroundColor Yellow
            }
        } else {
            Write-Host "✗ WWW domain is not accessible: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "✗ Error testing WWW domain" -ForegroundColor Red
}

# Summary
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "                   SUMMARY                       " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if ($foundDistribution) {
    Write-Host "Your AWS deployment appears to be set up." -ForegroundColor Green
    Write-Host
    Write-Host "To update your website in the future, use:" -ForegroundColor Yellow
    Write-Host "PowerShell -ExecutionPolicy Bypass -File .\simple-aws-deploy.ps1" -ForegroundColor White
} else {
    Write-Host "Your AWS deployment is not complete." -ForegroundColor Yellow
    Write-Host
    Write-Host "Please run the main deployment script:" -ForegroundColor Yellow
    Write-Host "PowerShell -ExecutionPolicy Bypass -File .\deploy-with-account-id.ps1" -ForegroundColor White
}

Write-Host
Write-Host "For detailed setup information, refer to:" -ForegroundColor Yellow
Write-Host "AWS-DEPLOYMENT-GUIDE.md" -ForegroundColor White
