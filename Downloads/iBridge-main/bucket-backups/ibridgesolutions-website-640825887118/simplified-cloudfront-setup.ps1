# Simplified CloudFront Setup Script
# This script creates a CloudFront distribution for ibridgesolutions.co.za

# Configuration
$accountId = "640825887118"
$s3BucketName = "ibridgesolutions-website-$accountId"
$region = "us-east-1"
$domainName = "ibridgesolutions.co.za"
$wwwDomainName = "www.ibridgesolutions.co.za"
$awsExePath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"

# Header
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  SIMPLIFIED CLOUDFRONT SETUP FOR IBRIDGESOLUTIONS.CO.ZA" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host

# Get Certificate ARN from file
$certificateArn = Get-Content -Path "certificate-arn.txt" -Raw
$certificateArn = $certificateArn.Trim()
Write-Host "Using Certificate ARN: $certificateArn" -ForegroundColor Yellow

# Create the distribution config JSON file
Write-Host "Creating CloudFront distribution configuration..." -ForegroundColor Yellow

$configJson = @"
{
    "CallerReference": "ibridgesolutions-$(Get-Date -Format 'yyyyMMddHHmmss')",
    "Aliases": {
        "Quantity": 2,
        "Items": ["$domainName", "$wwwDomainName"]
    },
    "DefaultRootObject": "index.html",
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-$s3BucketName",
                "DomainName": "$s3BucketName.s3.amazonaws.com",
                "OriginPath": "",
                "CustomHeaders": { "Quantity": 0 },
                "S3OriginConfig": { "OriginAccessIdentity": "" }
            }
        ]
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-$s3BucketName",
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": { "Forward": "none" },
            "Headers": { "Quantity": 0 },
            "QueryStringCacheKeys": { "Quantity": 0 }
        },
        "TrustedSigners": { "Enabled": false, "Quantity": 0 },
        "ViewerProtocolPolicy": "redirect-to-https",
        "MinTTL": 0,
        "AllowedMethods": {
            "Quantity": 2,
            "Items": ["GET", "HEAD"],
            "CachedMethods": {
                "Quantity": 2,
                "Items": ["GET", "HEAD"]
            }
        },
        "SmoothStreaming": false,
        "DefaultTTL": 86400,
        "MaxTTL": 31536000,
        "Compress": true,
        "LambdaFunctionAssociations": { "Quantity": 0 },
        "FieldLevelEncryptionId": ""
    },
    "CacheBehaviors": { "Quantity": 0 },
    "CustomErrorResponses": {
        "Quantity": 1,
        "Items": [
            {
                "ErrorCode": 404,
                "ResponsePagePath": "/index.html",
                "ResponseCode": "200",
                "ErrorCachingMinTTL": 300
            }
        ]
    },
    "Comment": "CloudFront for ibridgesolutions.co.za",
    "Logging": {
        "Enabled": false,
        "IncludeCookies": false,
        "Bucket": "",
        "Prefix": ""
    },
    "PriceClass": "PriceClass_All",
    "Enabled": true,
    "ViewerCertificate": {
        "ACMCertificateArn": "$certificateArn",
        "SSLSupportMethod": "sni-only",
        "MinimumProtocolVersion": "TLSv1.2_2021",
        "Certificate": "$certificateArn",
        "CertificateSource": "acm"
    },
    "Restrictions": {
        "GeoRestriction": {
            "RestrictionType": "none",
            "Quantity": 0
        }
    },
    "WebACLId": "",
    "HttpVersion": "http2",
    "IsIPV6Enabled": true
}
"@

# Save the configuration to a file
$configJson | Out-File -FilePath "cloudfront-config.json" -Encoding ascii
Write-Host "Configuration saved to cloudfront-config.json" -ForegroundColor Green

# Create CloudFront distribution using Start-Process
Write-Host "Creating CloudFront distribution (this may take a few minutes)..." -ForegroundColor Yellow
try {
    $result = Start-Process -FilePath $awsExePath -ArgumentList "cloudfront create-distribution --distribution-config file://cloudfront-config.json --region $region" -NoNewWindow -Wait -RedirectStandardOutput "cloudfront-output.txt" -PassThru
    
    if (Test-Path "cloudfront-output.txt") {
        $cfOutput = Get-Content -Path "cloudfront-output.txt" -Raw
        
        # Extract Distribution ID and Domain Name
        $distId = if ($cfOutput -match '"Id":\s*"([^"]+)"') { $matches[1] } else { "Unknown" }
        $distDomain = if ($cfOutput -match '"DomainName":\s*"([^"]+)"') { $matches[1] } else { "Unknown" }
        
        Write-Host "CloudFront Distribution Created!" -ForegroundColor Green
        Write-Host "Distribution ID: $distId" -ForegroundColor Cyan
        Write-Host "Distribution Domain: $distDomain" -ForegroundColor Cyan
        
        # Save information to a file
        @"
CloudFront Distribution Information
==================================
Distribution ID: $distId
Distribution Domain: $distDomain
SSL Certificate ARN: $certificateArn
S3 Bucket: $s3BucketName
"@ | Out-File -FilePath "cloudfront-info.txt" -Encoding ascii
        
        Write-Host "CloudFront information saved to cloudfront-info.txt" -ForegroundColor Green
    } else {
        Write-Host "CloudFront distribution creation output not found." -ForegroundColor Red
    }
} catch {
    Write-Host "Error creating CloudFront distribution: $_" -ForegroundColor Red
}

# Display DNS configuration instructions
Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "  DNS CONFIGURATION INSTRUCTIONS" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

if (Test-Path "cloudfront-output.txt") {
    $cfOutput = Get-Content -Path "cloudfront-output.txt" -Raw
    $distDomain = if ($cfOutput -match '"DomainName":\s*"([^"]+)"') { $matches[1] } else { "your-cloudfront-domain.cloudfront.net" }
    
    Write-Host "Add these DNS records in GoDaddy:" -ForegroundColor Yellow
    Write-Host
    Write-Host "For www subdomain:" -ForegroundColor Cyan
    Write-Host "Type: CNAME" -ForegroundColor White
    Write-Host "Host: www" -ForegroundColor White
    Write-Host "Points to: $distDomain" -ForegroundColor White
    Write-Host "TTL: 1 Hour" -ForegroundColor White
    Write-Host
    Write-Host "For root domain (if GoDaddy allows):" -ForegroundColor Cyan
    Write-Host "Type: CNAME" -ForegroundColor White
    Write-Host "Host: @" -ForegroundColor White
    Write-Host "Points to: $distDomain" -ForegroundColor White
    Write-Host "TTL: 1 Hour" -ForegroundColor White
    Write-Host
    Write-Host "Note: If GoDaddy doesn't allow CNAME for the root domain, consider using Route 53." -ForegroundColor Yellow
} else {
    Write-Host "CloudFront distribution not created. Please check for errors." -ForegroundColor Red
}
