# iBridgeSolutions AWS Deployment Script
# This script will deploy your website to AWS CloudFront with proper DNS configuration

# Configuration
$domainName = "ibridgesolutions.co.za"
$region = "eu-west-1" # Ireland region
$websiteFolder = "."
$s3BucketName = $domainName

# Header
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "     IBRIDGESOLUTIONS AWS DEPLOYMENT" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host

# Step 1: Check AWS CLI Installation
function Check-AwsCliInstalled {
    try {
        $awsVersion = aws --version
        Write-Host "✅ AWS CLI is already installed: $awsVersion" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ AWS CLI is not installed." -ForegroundColor Red
        Write-Host "Installing AWS CLI using bundled installer..." -ForegroundColor Yellow
        
        if (Test-Path ".\AWSCLIV2.msi") {
            Write-Host "Found AWSCLIV2.msi in the current folder." -ForegroundColor Cyan
            Start-Process msiexec.exe -Wait -ArgumentList "/i AWSCLIV2.msi /quiet"
            Write-Host "✅ AWS CLI installed successfully." -ForegroundColor Green
            
            # Reload PATH to include AWS CLI
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            return $true
        } else {
            Write-Host "Would you like to download and install AWS CLI now? (Y/N)" -ForegroundColor Yellow
            $response = Read-Host
            
            if ($response.ToLower() -eq "y") {
                Write-Host "Downloading AWS CLI installer..." -ForegroundColor Cyan
                Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "AWSCLIV2.msi"
                Start-Process msiexec.exe -Wait -ArgumentList "/i AWSCLIV2.msi /quiet"
                Remove-Item "AWSCLIV2.msi"
                Write-Host "✅ AWS CLI installed successfully." -ForegroundColor Green
                
                # Reload PATH to include AWS CLI
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                return $true
            }
            else {
                Write-Host "❌ AWS CLI is required for this script to work. Please install it manually." -ForegroundColor Red
                return $false
            }
        }
    }
}

# Step 2: Configure AWS CLI
function Configure-AwsCli {
    Write-Host "`nSTEP 2: CONFIGURE AWS CREDENTIALS" -ForegroundColor Green
    Write-Host "------------------------------" -ForegroundColor Green
    Write-Host "You'll need your AWS Access Key ID and Secret Access Key from your AWS account." -ForegroundColor Yellow
    Write-Host "If you don't have these, create them in the AWS Console under IAM > Users > Security credentials." -ForegroundColor Yellow
    
    # Check if AWS is already configured
    try {
        $awsIdentity = aws sts get-caller-identity 2>$null
        if ($awsIdentity) {
            Write-Host "✅ AWS CLI is already configured with valid credentials." -ForegroundColor Green
            return $true
        }
    }
    catch {
        # Credentials not configured or invalid
    }
    
    Write-Host "Let's configure your AWS credentials." -ForegroundColor Yellow
    $accessKey = Read-Host "Enter your AWS Access Key ID"
    $secretKey = Read-Host "Enter your AWS Secret Access Key" -AsSecureString
    $secretKeyText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretKey))
    
    # Configure AWS CLI
    Write-Host "Configuring AWS CLI..." -ForegroundColor Cyan
    aws configure set aws_access_key_id $accessKey
    aws configure set aws_secret_access_key $secretKeyText
    aws configure set region $region
    aws configure set output json
    
    # Verify configuration
    try {
        $awsIdentity = aws sts get-caller-identity
        Write-Host "✅ AWS credentials configured successfully." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Failed to configure AWS credentials. Please check your Access Key and Secret Key." -ForegroundColor Red
        return $false
    }
}

# Step 3: Create S3 Bucket
function Create-S3Bucket {
    Write-Host "`nSTEP 3: CREATE S3 BUCKET" -ForegroundColor Green
    Write-Host "---------------------" -ForegroundColor Green
    
    # Check if bucket already exists
    $bucketExists = $false
    try {
        $bucketCheck = aws s3api head-bucket --bucket $s3BucketName 2>$null
        if ($?) {
            Write-Host "✅ S3 bucket '$s3BucketName' already exists." -ForegroundColor Green
            $bucketExists = $true
        }
    }
    catch {
        # Bucket doesn't exist or you don't have permission
    }
    
    if (-not $bucketExists) {
        Write-Host "Creating S3 bucket '$s3BucketName'..." -ForegroundColor Cyan
        try {
            aws s3 mb "s3://$s3BucketName" --region $region
            Write-Host "✅ S3 bucket created successfully." -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Failed to create S3 bucket. Error: $_" -ForegroundColor Red
            return $false
        }
    }
    
    # Configure bucket for website hosting
    Write-Host "Configuring bucket for website hosting..." -ForegroundColor Cyan
    aws s3 website "s3://$s3BucketName" --index-document index.html --error-document index.html
    
    # Create and apply bucket policy for public read access
    Write-Host "Setting bucket policy for public access..." -ForegroundColor Cyan
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
    
    # Disable block public access settings
    Write-Host "Disabling block public access settings..." -ForegroundColor Cyan
    aws s3api put-public-access-block --bucket $s3BucketName --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
    
    return $true
}

# Step 4: Upload Website Files
function Upload-WebsiteFiles {
    Write-Host "`nSTEP 4: UPLOAD WEBSITE FILES" -ForegroundColor Green
    Write-Host "------------------------" -ForegroundColor Green
    
    Write-Host "Uploading website files to S3..." -ForegroundColor Cyan
    try {
        # Exclude unnecessary files from upload
        aws s3 sync "$websiteFolder" "s3://$s3BucketName" --exclude "*.ps1" --exclude "*.md" --exclude ".git/*" --exclude "*.json" --exclude "*.txt" --exclude "AWSCLIV2.msi"
        Write-Host "✅ Website files uploaded successfully." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Failed to upload website files. Error: $_" -ForegroundColor Red
        return $false
    }
}

# Step 5: Create CloudFront Distribution
function Create-CloudFrontDistribution {
    Write-Host "`nSTEP 5: CREATE CLOUDFRONT DISTRIBUTION" -ForegroundColor Green
    Write-Host "---------------------------------" -ForegroundColor Green
    
    # Check if CloudFront distribution info file exists
    if (Test-Path ".\cloudfront-info.txt") {
        $cloudFrontInfo = Get-Content -Path ".\cloudfront-info.txt" -Raw
        
        if ($cloudFrontInfo -match "Distribution ID: (.+)") {
            $distributionId = $matches[1].Trim()
            if ($cloudFrontInfo -match "Distribution Domain: (.+)") {
                $distributionDomain = $matches[1].Trim()
                Write-Host "✅ CloudFront distribution already exists:" -ForegroundColor Green
                Write-Host "  - Distribution ID: $distributionId" -ForegroundColor White
                Write-Host "  - Distribution Domain: $distributionDomain" -ForegroundColor White
                return @{
                    DistributionId = $distributionId
                    DistributionDomain = $distributionDomain
                }
            }
        }
    }
    
    # Check for SSL certificate in ACM
    Write-Host "Checking for SSL certificate in AWS Certificate Manager..." -ForegroundColor Cyan
    $certificateArn = $null
    $certificates = aws acm list-certificates --region us-east-1 | ConvertFrom-Json
    
    foreach ($cert in $certificates.CertificateSummaryList) {
        if ($cert.DomainName -eq $domainName -or $cert.DomainName -eq "*.$domainName") {
            $certificateArn = $cert.CertificateArn
            Write-Host "✅ Found existing SSL certificate for $($cert.DomainName)" -ForegroundColor Green
            break
        }
    }
    
    # If no certificate found, create one
    if (-not $certificateArn) {
        Write-Host "No SSL certificate found. Creating a new certificate..." -ForegroundColor Yellow
        
        # Create certificate (must be in us-east-1 for CloudFront)
        $certRequest = aws acm request-certificate --domain-name $domainName --validation-method DNS --subject-alternative-names "www.$domainName" --region us-east-1| ConvertFrom-Json
        $certificateArn = $certRequest.CertificateArn
        
        Write-Host "✅ Certificate requested. ARN: $certificateArn" -ForegroundColor Green
        Write-Host "You'll need to validate the certificate by adding DNS records." -ForegroundColor Yellow
        
        # Get validation records
        Start-Sleep -Seconds 2
        $certDetails = aws acm describe-certificate --certificate-arn $certificateArn --region us-east-1 | ConvertFrom-Json
        
        Write-Host "`nCERTIFICATE VALIDATION:" -ForegroundColor Yellow
        Write-Host "To validate your certificate, add these CNAME records to your DNS:" -ForegroundColor Yellow
        
        foreach ($validation in $certDetails.Certificate.DomainValidationOptions) {
            if ($validation.ValidationMethod -eq "DNS") {
                $recordName = $validation.ResourceRecord.Name
                $recordValue = $validation.ResourceRecord.Value
                
                # Remove domain from record name to get just the prefix
                $recordName = $recordName.Replace(".$domainName", "")
                
                Write-Host "  CNAME Record: $recordName" -ForegroundColor White
                Write-Host "  Value: $recordValue" -ForegroundColor White
                Write-Host
            }
        }
        
        Write-Host "Have you added these DNS records? (Y/N)" -ForegroundColor Yellow
        $dnsConfirmed = Read-Host
        
        if ($dnsConfirmed.ToLower() -ne "y") {
            Write-Host "Please add the DNS records and run this script again later." -ForegroundColor Yellow
            $certificateArn | Out-File -FilePath ".\certificate-arn.txt" -Encoding utf8
            Write-Host "Certificate ARN saved to certificate-arn.txt for future use." -ForegroundColor Cyan
            return $null
        }
        
        # Wait for certificate validation
        Write-Host "Waiting for certificate validation..." -ForegroundColor Cyan
        $isValidated = $false
        $attempts = 0
        
        while (-not $isValidated -and $attempts -lt 10) {
            $certDetails = aws acm describe-certificate --certificate-arn $certificateArn --region us-east-1 | ConvertFrom-Json
            if ($certDetails.Certificate.Status -eq "ISSUED") {
                $isValidated = $true
                Write-Host "✅ Certificate validated successfully!" -ForegroundColor Green
            }
            else {
                Write-Host "Certificate status: $($certDetails.Certificate.Status). Waiting..." -ForegroundColor Yellow
                Start-Sleep -Seconds 30
                $attempts++
            }
        }
        
        if (-not $isValidated) {
            Write-Host "Certificate validation is taking longer than expected." -ForegroundColor Yellow
            Write-Host "You can continue with the CloudFront setup, but it won't use HTTPS until the certificate is validated." -ForegroundColor Yellow
        }
    }
    
    # Create CloudFront distribution
    Write-Host "Creating CloudFront distribution..." -ForegroundColor Cyan
    
    # Create distribution configuration file
    $originId = "S3-Website-$s3BucketName"
    $s3OriginEndpoint = "$s3BucketName.s3-website-$region.amazonaws.com"
    
    $cloudFrontConfig = @"
{
  "CallerReference": "$(Get-Date -Format "yyyyMMddHHmmss")",
  "Aliases": {
    "Quantity": 2,
    "Items": ["$domainName", "www.$domainName"]
  },
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "$originId",
        "DomainName": "$s3OriginEndpoint",
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
        "ConnectionTimeout": 10
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "$originId",
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
    "LambdaFunctionAssociations": {
      "Quantity": 0
    }
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
  "Comment": "Distribution for $domainName",
  "Logging": {
    "Enabled": false,
    "IncludeCookies": false,
    "Bucket": "",
    "Prefix": ""
  },
  "PriceClass": "PriceClass_100",
  "Enabled": true,
  "ViewerCertificate": {
    "ACMCertificateArn": "$certificateArn",
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021"
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
    
    $cloudFrontConfig | Out-File -FilePath "cloudfront-config.json" -Encoding utf8
    
    # Create the CloudFront distribution
    $distribution = aws cloudfront create-distribution --distribution-config file://cloudfront-config.json | ConvertFrom-Json
    
    # Save distribution details
    $distributionId = $distribution.Distribution.Id
    $distributionDomain = $distribution.Distribution.DomainName
    
    $cloudFrontInfo = @"
Distribution ID: $distributionId
Distribution Domain: $distributionDomain
"@
    
    $cloudFrontInfo | Out-File -FilePath "cloudfront-info.txt" -Encoding utf8
    
    Write-Host "✅ CloudFront distribution created successfully:" -ForegroundColor Green
    Write-Host "  - Distribution ID: $distributionId" -ForegroundColor White
    Write-Host "  - Distribution Domain: $distributionDomain" -ForegroundColor White
    
    return @{
        DistributionId = $distributionId
        DistributionDomain = $distributionDomain
    }
}

# Step 6: Configure DNS with GoDaddy
function Configure-GoDaddyDns {
    param (
        [string]$distributionDomain
    )
    
    Write-Host "`nSTEP 6: CONFIGURE GODADDY DNS" -ForegroundColor Green
    Write-Host "------------------------" -ForegroundColor Green
    
    Write-Host "To configure GoDaddy DNS for your CloudFront distribution:" -ForegroundColor Yellow
    Write-Host "1. Log in to your GoDaddy account" -ForegroundColor White
    Write-Host "2. Go to My Products > DNS > Manage DNS for $domainName" -ForegroundColor White
    Write-Host "3. Update the following DNS records:" -ForegroundColor White
    Write-Host
    Write-Host "For the root domain (@):" -ForegroundColor Cyan
    Write-Host "  - Type: CNAME" -ForegroundColor White
    Write-Host "  - Name: @" -ForegroundColor White
    Write-Host "  - Value: $distributionDomain" -ForegroundColor White
    Write-Host "  - TTL: 600 (10 minutes) or 1 Hour" -ForegroundColor White
    Write-Host
    Write-Host "For www subdomain:" -ForegroundColor Cyan
    Write-Host "  - Type: CNAME" -ForegroundColor White
    Write-Host "  - Name: www" -ForegroundColor White
    Write-Host "  - Value: $distributionDomain" -ForegroundColor White
    Write-Host "  - TTL: 600 (10 minutes) or 1 Hour" -ForegroundColor White
    Write-Host
    Write-Host "⚠️ NOTE: Some DNS providers don't allow CNAME at the root domain. If GoDaddy" -ForegroundColor Yellow
    Write-Host "doesn't allow this, you may need to use their domain forwarding feature instead." -ForegroundColor Yellow
    
    Write-Host "`nHave you updated the DNS records? (Y/N)" -ForegroundColor Yellow
    $dnsConfirmed = Read-Host
    
    if ($dnsConfirmed.ToLower() -eq "y") {
        Write-Host "✅ DNS configuration confirmed." -ForegroundColor Green
    }
    else {
        Write-Host "Please update your DNS records to point to your CloudFront distribution." -ForegroundColor Yellow
        Write-Host "Your website won't be accessible at $domainName until DNS is configured." -ForegroundColor Yellow
    }
}

# Main execution flow
Write-Host "STEP 1: CHECK AWS CLI INSTALLATION" -ForegroundColor Green
Write-Host "---------------------------" -ForegroundColor Green
if (-not (Check-AwsCliInstalled)) {
    exit
}

if (-not (Configure-AwsCli)) {
    exit
}

if (-not (Create-S3Bucket)) {
    exit
}

if (-not (Upload-WebsiteFiles)) {
    exit
}

$cloudFrontDetails = Create-CloudFrontDistribution
if (-not $cloudFrontDetails) {
    Write-Host "CloudFront distribution setup incomplete. Run the script again after validating the SSL certificate." -ForegroundColor Yellow
    exit
}

Configure-GoDaddyDns -distributionDomain $cloudFrontDetails.DistributionDomain

# Final summary
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "     DEPLOYMENT SUMMARY" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "✅ S3 bucket created: s3://$s3BucketName" -ForegroundColor Green
Write-Host "✅ Website files uploaded to S3" -ForegroundColor Green
Write-Host "✅ CloudFront distribution created: $($cloudFrontDetails.DistributionDomain)" -ForegroundColor Green
Write-Host
Write-Host "Your website will be accessible at:" -ForegroundColor Yellow
Write-Host "- https://$domainName" -ForegroundColor White
Write-Host "- https://www.$domainName" -ForegroundColor White
Write-Host "- https://$($cloudFrontDetails.DistributionDomain) (CloudFront domain)" -ForegroundColor White
Write-Host
Write-Host "⚠️ Important Notes:" -ForegroundColor Yellow
Write-Host "1. DNS changes can take 24-48 hours to fully propagate" -ForegroundColor White
Write-Host "2. CloudFront distribution can take 10-15 minutes to deploy" -ForegroundColor White
Write-Host "3. If your SSL certificate is not yet validated, HTTPS will not work until validation completes" -ForegroundColor White
Write-Host
Write-Host "To check deployment status later, run: check-aws-deployment.ps1" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
