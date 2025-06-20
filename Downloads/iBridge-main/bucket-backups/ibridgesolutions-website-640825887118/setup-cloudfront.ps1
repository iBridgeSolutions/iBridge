# CloudFront Setup Script for iBridge Solutions
# This script creates a CloudFront distribution after SSL certificate validation

# Configuration
$accountId = "640825887118"
$s3BucketName = "ibridgesolutions-website-$accountId"
$region = "us-east-1"
$domainName = "ibridgesolutions.co.za"
$wwwDomainName = "www.ibridgesolutions.co.za"
$awsCmd = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"

# Header
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  CLOUDFRONT SETUP SCRIPT FOR IBRIDGESOLUTIONS   " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Account ID: 6408-2588-7118" -ForegroundColor Yellow
Write-Host "Domain: $domainName" -ForegroundColor Yellow
Write-Host

# Ask for Certificate ARN
Write-Host "Please provide the SSL certificate information..." -ForegroundColor Yellow
$certificateArn = Read-Host "Enter your SSL Certificate ARN (from AWS Certificate Manager)"

# Check if the certificate is validated
Write-Host "`nChecking certificate validation status..." -ForegroundColor Yellow
try {
    $certificateDetails = & $awsCmd acm describe-certificate --certificate-arn $certificateArn --region $region | ConvertFrom-Json
    $status = $certificateDetails.Certificate.Status
    
    if ($status -ne "ISSUED") {
        Write-Host "Certificate is not yet validated (Status: $status)." -ForegroundColor Red
        Write-Host "Please validate your certificate first and then run this script again." -ForegroundColor Red
        exit
    }
    
    Write-Host "Certificate is validated. Proceeding with CloudFront setup." -ForegroundColor Green
} catch {
    Write-Host "Error checking certificate: $_" -ForegroundColor Red
    exit
}

# Create CloudFront distribution with custom domain
Write-Host "`nCreating CloudFront distribution..." -ForegroundColor Yellow
try {
    # Create CloudFront distribution configuration file
    $distributionConfig = @"
{
    "CallerReference": "ibridgesolutions-$((Get-Date).ToString("yyyyMMddHHmmss"))",
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
                "CustomHeaders": {
                    "Quantity": 0
                },
                "S3OriginConfig": {
                    "OriginAccessIdentity": ""
                }
            }
        ]
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-$s3BucketName",
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            },
            "Headers": {
                "Quantity": 0
            },
            "QueryStringCacheKeys": {
                "Quantity": 0
            }
        },
        "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
        },
        "ViewerProtocolPolicy": "redirect-to-https",
        "MinTTL": 0,
        "AllowedMethods": {
            "Quantity": 2,
            "Items": [
                "GET",
                "HEAD"
            ],
            "CachedMethods": {
                "Quantity": 2,
                "Items": [
                    "GET",
                    "HEAD"
                ]
            }
        },
        "SmoothStreaming": false,
        "DefaultTTL": 86400,
        "MaxTTL": 31536000,
        "Compress": true,
        "LambdaFunctionAssociations": {
            "Quantity": 0
        },
        "FieldLevelEncryptionId": ""
    },
    "CacheBehaviors": {
        "Quantity": 0
    },
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
    "Comment": "CloudFront distribution for ibridgesolutions.co.za",
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

    $distributionConfig | Out-File -FilePath "distribution-config.json" -Encoding ascii
    $distribution = & $awsCmd cloudfront create-distribution --distribution-config file://distribution-config.json --region $region | ConvertFrom-Json
    
    Write-Host "CloudFront distribution created successfully." -ForegroundColor Green
    Write-Host "Distribution ID: $($distribution.Distribution.Id)" -ForegroundColor Green
    Write-Host "Distribution Domain Name: $($distribution.Distribution.DomainName)" -ForegroundColor Green
    
    # Record the CloudFront distribution info
    $distributionInfo = @"
CloudFront Distribution Information
==================================
Distribution ID: $($distribution.Distribution.Id)
Distribution Domain: $($distribution.Distribution.DomainName)
SSL Certificate ARN: $certificateArn
S3 Bucket: $s3BucketName
"@
    $distributionInfo | Out-File -FilePath "cloudfront-info.txt" -Encoding ascii
    Write-Host "CloudFront information saved to cloudfront-info.txt" -ForegroundColor Green
    
} catch {
    Write-Host "Error creating CloudFront distribution: $_" -ForegroundColor Red
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "      DNS CONFIGURATION FOR IBRIDGESOLUTIONS     " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Add these DNS records to your GoDaddy account:" -ForegroundColor Yellow
Write-Host
Write-Host "For the root domain (ibridgesolutions.co.za):" -ForegroundColor Cyan
Write-Host "Type: CNAME" -ForegroundColor White
Write-Host "Name: @" -ForegroundColor White
Write-Host "Value: $($distribution.Distribution.DomainName)" -ForegroundColor White
Write-Host "TTL: 1 Hour" -ForegroundColor White
Write-Host
Write-Host "For www subdomain (www.ibridgesolutions.co.za):" -ForegroundColor Cyan
Write-Host "Type: CNAME" -ForegroundColor White
Write-Host "Name: www" -ForegroundColor White
Write-Host "Value: $($distribution.Distribution.DomainName)" -ForegroundColor White
Write-Host "TTL: 1 Hour" -ForegroundColor White
Write-Host
Write-Host "Note: GoDaddy may not support CNAME for root domains. If this is the case," -ForegroundColor Yellow
Write-Host "consider using Route 53 by running the migrate-to-route53.ps1 script." -ForegroundColor Yellow
Write-Host
Write-Host "After DNS configuration, run check-aws-deployment.ps1 to verify everything." -ForegroundColor Green
