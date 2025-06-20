# AWS Deployment Script for iBridgeSolutions Website with Account ID
# Account ID: 6408-2588-7118

# Configuration
$accountId = "640825887118" # Formatted without hyphens for AWS usage
$websiteFolder = "c:\Users\Lwandile Gasela\Downloads\iBridge-main\iBridge-main\iBridge-main"
$s3BucketName = "ibridgesolutions-website-$accountId"
$region = "us-east-1" # Use us-east-1 for SSL certificates to work with CloudFront
$domainName = "ibridgesolutions.co.za"
$wwwDomainName = "www.ibridgesolutions.co.za"

function Show-Header {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "      AWS Deployment Script for iBridgeSolutions.co.za    " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "Account ID: 6408-2588-7118" -ForegroundColor Yellow
    Write-Host
}

function Check-AwsCli {
    Write-Host "Checking AWS CLI installation..." -ForegroundColor Yellow

    try {
        $awsVersion = aws --version
        Write-Host "AWS CLI is installed: $awsVersion" -ForegroundColor Green
        
        # Check if credentials are configured
        Write-Host "Checking AWS credentials..."
        $configStatus = aws configure list
        
        if ($configStatus -match "access_key") {
            Write-Host "AWS credentials are configured." -ForegroundColor Green
        } else {
            Write-Host "AWS credentials not configured. Let's set them up..." -ForegroundColor Yellow
            
            Write-Host "`nPlease enter your AWS credentials:" -ForegroundColor Cyan
            Write-Host "(These can be found in the AWS Console under Security Credentials)" -ForegroundColor Cyan
            
            $accessKey = Read-Host "AWS Access Key ID"
            $secretKey = Read-Host "AWS Secret Access Key" -AsSecureString
            $secretKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretKey))
            
            # Configure AWS CLI with provided credentials
            aws configure set aws_access_key_id $accessKey
            aws configure set aws_secret_access_key $secretKeyPlain
            aws configure set default.region $region
            aws configure set default.output json
            
            Write-Host "AWS credentials configured successfully." -ForegroundColor Green
        }
    } catch {
        Write-Host "AWS CLI is not installed. Installing now..." -ForegroundColor Yellow
        
        # Download and install AWS CLI
        Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "AWSCLIV2.msi"
        Start-Process msiexec.exe -Wait -ArgumentList "/i AWSCLIV2.msi /quiet"
        Remove-Item "AWSCLIV2.msi"
        
        Write-Host "AWS CLI installed. Please run this script again." -ForegroundColor Green
        exit
    }
}

function Create-S3Bucket {
    Write-Host "`nCreating S3 bucket for website hosting..." -ForegroundColor Yellow
    
    # Check if bucket already exists
    $bucketExists = aws s3api head-bucket --bucket $s3BucketName 2>&1
    
    if ($bucketExists -match "404") {
        # Create bucket
        Write-Host "Creating new S3 bucket: $s3BucketName"
        aws s3api create-bucket --bucket $s3BucketName --region $region
        
        # Enable bucket for static website hosting
        Write-Host "Configuring bucket for static website hosting..."
        aws s3 website s3://$s3BucketName/ --index-document index.html --error-document index.html
        
        # Set bucket policy for public access
        $bucketPolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$s3BucketName/*"
    }
  ]
}
"@
        $bucketPolicy | Out-File -FilePath "bucket-policy.json" -Encoding utf8
        aws s3api put-bucket-policy --bucket $s3BucketName --policy file://bucket-policy.json
        Remove-Item "bucket-policy.json"
        
        Write-Host "S3 bucket created and configured successfully." -ForegroundColor Green
    } else {
        Write-Host "S3 bucket $s3BucketName already exists." -ForegroundColor Green
    }
    
    # Get the S3 website endpoint
    $s3WebsiteUrl = "http://$s3BucketName.s3-website-$region.amazonaws.com"
    Write-Host "S3 Website URL: $s3WebsiteUrl" -ForegroundColor Cyan
    return $s3WebsiteUrl
}

function Request-SslCertificate {
    Write-Host "`nRequesting SSL certificate for domain..." -ForegroundColor Yellow
    
    # Check if certificate already exists
    $certificates = aws acm list-certificates --region $region | ConvertFrom-Json
    $certificateArn = $null
    
    foreach ($cert in $certificates.CertificateSummaryList) {
        if ($cert.DomainName -eq $domainName) {
            $certificateArn = $cert.CertificateArn
            Write-Host "Certificate for $domainName already exists." -ForegroundColor Green
            break
        }
    }
    
    if (-not $certificateArn) {
        # Request new certificate
        Write-Host "Requesting new SSL certificate for $domainName and *.$domainName..."
        $certificateArn = aws acm request-certificate --domain-name $domainName --validation-method DNS --subject-alternative-names "*.$domainName" --region $region | ConvertFrom-Json | Select-Object -ExpandProperty CertificateArn
        
        Write-Host "Certificate requested: $certificateArn" -ForegroundColor Green
        Write-Host "Important: You must validate this certificate by adding DNS records." -ForegroundColor Yellow
        Write-Host "Get validation records with: aws acm describe-certificate --certificate-arn $certificateArn --region $region" -ForegroundColor Yellow
    }
    
    return $certificateArn
}

function Create-CloudFrontDistribution {
    param (
        [string]$s3WebsiteUrl,
        [string]$certificateArn
    )
    
    Write-Host "`nCreating CloudFront distribution..." -ForegroundColor Yellow
    
    # Check if distribution already exists for the domain
    $distributions = aws cloudfront list-distributions | ConvertFrom-Json
    $distributionId = $null
    $distributionDomainName = $null
    
    if ($distributions.DistributionList.Items) {
        foreach ($dist in $distributions.DistributionList.Items) {
            foreach ($alias in $dist.Aliases.Items) {
                if ($alias -eq $domainName) {
                    $distributionId = $dist.Id
                    $distributionDomainName = $dist.DomainName
                    Write-Host "CloudFront distribution for $domainName already exists." -ForegroundColor Green
                    break
                }
            }
            if ($distributionId) { break }
        }
    }
    
    if (-not $distributionId) {
        # Create distribution config file
        $distributionConfig = @"
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
                "Id": "S3-Website-$s3BucketName",
                "DomainName": "$s3BucketName.s3-website-$region.amazonaws.com",
                "CustomOriginConfig": {
                    "HTTPPort": 80,
                    "HTTPSPort": 443,
                    "OriginProtocolPolicy": "http-only",
                    "OriginSslProtocols": {
                        "Quantity": 1,
                        "Items": ["TLSv1.2"]
                    },
                    "OriginReadTimeout": 30,
                    "OriginKeepaliveTimeout": 5
                },
                "ConnectionAttempts": 3,
                "ConnectionTimeout": 10,
                "OriginPath": ""
            }
        ]
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-Website-$s3BucketName",
        "ViewerProtocolPolicy": "redirect-to-https",
        "AllowedMethods": {
            "Quantity": 2,
            "Items": ["HEAD", "GET"],
            "CachedMethods": {
                "Quantity": 2,
                "Items": ["HEAD", "GET"]
            }
        },
        "Compress": true,
        "DefaultTTL": 86400,
        "MaxTTL": 31536000,
        "MinTTL": 0,
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
        }
    },
    "ViewerCertificate": {
        "ACMCertificateArn": "$certificateArn",
        "SSLSupportMethod": "sni-only",
        "MinimumProtocolVersion": "TLSv1.2_2021"
    },
    "Enabled": true,
    "PriceClass": "PriceClass_100"
}
"@
        $distributionConfig | Out-File -FilePath "distribution-config.json" -Encoding utf8
        
        # Create CloudFront distribution
        Write-Host "Creating new CloudFront distribution..."
        $distribution = aws cloudfront create-distribution --distribution-config file://distribution-config.json | ConvertFrom-Json
        Remove-Item "distribution-config.json"
        
        $distributionId = $distribution.Distribution.Id
        $distributionDomainName = $distribution.Distribution.DomainName
        
        Write-Host "CloudFront distribution created:" -ForegroundColor Green
    }
    
    Write-Host "Distribution ID: $distributionId" -ForegroundColor Cyan
    Write-Host "Distribution Domain: $distributionDomainName" -ForegroundColor Cyan
    
    return @{
        Id = $distributionId
        DomainName = $distributionDomainName
    }
}

function Upload-WebsiteFiles {
    Write-Host "`nUploading website files to S3..." -ForegroundColor Yellow
    
    # Sync website files to S3
    aws s3 sync $websiteFolder s3://$s3BucketName --delete
    
    Write-Host "Website files uploaded successfully." -ForegroundColor Green
}

function Invalidate-CloudFrontCache {
    param (
        [string]$distributionId
    )
    
    Write-Host "`nInvalidating CloudFront cache..." -ForegroundColor Yellow
    
    # Create invalidation for all files
    aws cloudfront create-invalidation --distribution-id $distributionId --paths "/*"
    
    Write-Host "Cache invalidation request submitted." -ForegroundColor Green
}

function Show-DnsInstructions {
    param (
        [string]$distributionDomainName
    )
    
    Write-Host "`n==========================================================" -ForegroundColor Cyan
    Write-Host "                 DNS CONFIGURATION INSTRUCTIONS             " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    Write-Host "`nTo complete the setup, update your domain's DNS records at GoDaddy:" -ForegroundColor Yellow
    
    Write-Host "`n1. Log in to your GoDaddy account"
    Write-Host "2. Navigate to Domain Manager and select ibridgesolutions.co.za"
    Write-Host "3. Select 'Manage DNS'"
    Write-Host "4. Delete any existing A records and CNAME records for @ and www"
    Write-Host "5. Add the following CNAME records:"
    
    Write-Host "`n   Type: CNAME | Host: @" -ForegroundColor Green
    Write-Host "   Points to: $distributionDomainName" -ForegroundColor Green
    Write-Host "   TTL: 1 hour" -ForegroundColor Green
    
    Write-Host "`n   Type: CNAME | Host: www" -ForegroundColor Green
    Write-Host "   Points to: $distributionDomainName" -ForegroundColor Green
    Write-Host "   TTL: 1 hour" -ForegroundColor Green
    
    Write-Host "`nNote: Some domain providers don't allow CNAME for apex domains (@)." -ForegroundColor Yellow
    Write-Host "If GoDaddy doesn't allow this, you have two options:" -ForegroundColor Yellow
    Write-Host "1. Use GoDaddy's domain forwarding to redirect the apex domain to www" -ForegroundColor Yellow
    Write-Host "2. Alternatively, move your DNS management to Route 53 (has small cost)" -ForegroundColor Yellow
    
    Write-Host "`nIt may take 24-48 hours for DNS changes to fully propagate." -ForegroundColor Yellow
    
    Write-Host "`nAfter DNS propagation, your website will be live at:" -ForegroundColor Cyan
    Write-Host "https://$domainName" -ForegroundColor Cyan
    Write-Host "https://$wwwDomainName" -ForegroundColor Cyan
}

function Show-Route53Instructions {
    param (
        [string]$distributionDomainName
    )
    
    Write-Host "`n==========================================================" -ForegroundColor Cyan
    Write-Host "           ROUTE 53 DNS CONFIGURATION INSTRUCTIONS          " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    Write-Host "`nIf you prefer using AWS Route 53 for DNS management (recommended but has small cost):" -ForegroundColor Yellow
    
    Write-Host "`n1. Create a hosted zone in Route 53:"
    Write-Host "   aws route53 create-hosted-zone --name $domainName --caller-reference $(Get-Date -Format 'yyyyMMddHHmmss')"
    
    Write-Host "`n2. Note the nameservers from the response"
    
    Write-Host "`n3. Update your domain's nameservers at GoDaddy to use Route 53 nameservers"
    
    Write-Host "`n4. Create DNS records in Route 53 to point to CloudFront:"
    Write-Host "`n   For apex domain (ibridgesolutions.co.za):"
    Write-Host "   Create an A record alias pointing to your CloudFront distribution"
    
    Write-Host "`n   For www subdomain (www.ibridgesolutions.co.za):"
    Write-Host "   Create a CNAME record pointing to $distributionDomainName"
    
    Write-Host "`nNote: Route 53 allows alias A records for apex domains pointing to CloudFront," -ForegroundColor Cyan
    Write-Host "which solves the limitation of not being able to use CNAME for apex domains." -ForegroundColor Cyan
}

function Show-Footer {
    Write-Host "`n==========================================================" -ForegroundColor Cyan
    Write-Host "                    DEPLOYMENT COMPLETE                    " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    Write-Host "`nTo make future updates to your website:" -ForegroundColor Yellow
    Write-Host "1. Edit your website files locally"
    Write-Host "2. Run this script again to upload changes"
    
    Write-Host "`nTo monitor AWS costs:" -ForegroundColor Yellow
    Write-Host "Visit https://console.aws.amazon.com/billing/home"
    Write-Host "Remember, most resources we've used are within the AWS free tier"
    
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "- If your website doesn't appear, check your DNS configuration"
    Write-Host "- To debug SSL certificate issues, run: aws acm describe-certificate --certificate-arn YOUR_CERT_ARN --region us-east-1"
    Write-Host "- For CloudFront issues, check the distribution status in the AWS Console"
    
    Write-Host "`nThank you for using the AWS Deployment Script!" -ForegroundColor Green
}

# Main execution
Show-Header
Check-AwsCli

# Create and configure resources
$s3WebsiteUrl = Create-S3Bucket
$certificateArn = Request-SslCertificate
$distribution = Create-CloudFrontDistribution -s3WebsiteUrl $s3WebsiteUrl -certificateArn $certificateArn

# Upload files and invalidate cache
Upload-WebsiteFiles
Invalidate-CloudFrontCache -distributionId $distribution.Id

# Show DNS configuration instructions
Show-DnsInstructions -distributionDomainName $distribution.DomainName
Show-Route53Instructions -distributionDomainName $distribution.DomainName
Show-Footer
