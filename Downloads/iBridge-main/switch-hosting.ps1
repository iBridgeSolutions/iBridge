# iBridge Hosting Migration Tool
# This script helps migrate between GitHub Pages and AWS CloudFront hosting

$domainName = "ibridgesolutions.co.za"
$githubUser = "iBridgeSolutions" # Replace with your actual GitHub username

# GitHub Pages IP addresses
$githubPagesIPs = @(
    "185.199.108.153",
    "185.199.109.153", 
    "185.199.110.153", 
    "185.199.111.153"
)

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "   iBridge HOSTING MIGRATION ASSISTANT   " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# Check current DNS configuration
Write-Host "CURRENT DNS CONFIGURATION:" -ForegroundColor Green
Write-Host "--------------------------" -ForegroundColor Green

Write-Host "Checking DNS for $domainName..."
$rootDomainRecords = Resolve-DnsName -Name $domainName -Type A -ErrorAction SilentlyContinue

if ($rootDomainRecords) {
    Write-Host "`nCurrent A records for $($domainName):" -ForegroundColor Yellow
    $isGitHubPages = $false
    $isCloudFront = $false
    
    foreach ($record in $rootDomainRecords) {
        $ip = $record.IPAddress
        Write-Host "  $ip"
        
        if ($githubPagesIPs -contains $ip) {
            $isGitHubPages = $true
        }
        
        if ($ip -like "52.85.*") {
            $isCloudFront = $true
        }
    }
    
    if ($isGitHubPages) {
        Write-Host "`nStatus: ✅ Domain is configured for GitHub Pages" -ForegroundColor Green
        $currentHosting = "github"
    } elseif ($isCloudFront) {
        Write-Host "`nStatus: ✅ Domain is configured for AWS CloudFront" -ForegroundColor Green
        $currentHosting = "aws"
    } else {
        Write-Host "`nStatus: ❓ Domain is configured for unknown hosting" -ForegroundColor Yellow
        $currentHosting = "unknown"
    }
} else {
    Write-Host "Could not resolve DNS records for $domainName" -ForegroundColor Red
    $currentHosting = "unknown"
}

# Hosting migration options
Write-Host "`nHOSTING OPTIONS:" -ForegroundColor Green
Write-Host "----------------" -ForegroundColor Green
Write-Host "1. Migrate to GitHub Pages (Free, simple, but limited features)"
Write-Host "2. Migrate to AWS CloudFront/S3 (More features, potential costs)"
Write-Host "3. Exit without changes"

$choice = Read-Host "`nEnter your choice (1-3)"

switch ($choice) {
    "1" {
        # GitHub Pages migration
        if ($currentHosting -eq "github") {
            Write-Host "`nAlready configured for GitHub Pages. No DNS changes needed." -ForegroundColor Green
        } else {
            Write-Host "`nMigrating to GitHub Pages hosting..." -ForegroundColor Cyan
            
            # Instructions for GitHub Pages
            Write-Host "`nTo configure GitHub Pages hosting, update your DNS records at GoDaddy:" -ForegroundColor Yellow
            Write-Host "1. Login to your GoDaddy account"
            Write-Host "2. Go to My Products > DNS > Manage DNS for $domainName"
            Write-Host "3. Remove existing A records for the root domain (@)"
            Write-Host "4. Add the following A records for your root domain:"
            
            foreach ($ip in $githubPagesIPs) {
                Write-Host "   - A record: @ -> $ip (TTL: 600 or 1 hour)"
            }
            
            Write-Host "5. Add/update CNAME record for www subdomain:"
            Write-Host "   - CNAME record: www -> $githubUser.github.io (TTL: 600 or 1 hour)"
            
            # Update CNAME file if needed
            Write-Host "`nChecking CNAME file..."
            if (Test-Path ".\CNAME") {
                $cnameContent = Get-Content -Path ".\CNAME" -ErrorAction SilentlyContinue
                if ($cnameContent -ne $domainName) {
                    Write-Host "Updating CNAME file with: $domainName"
                    $domainName | Out-File -FilePath ".\CNAME" -NoNewline -Encoding utf8
                } else {
                    Write-Host "CNAME file already has correct content: $domainName"
                }
            } else {
                Write-Host "Creating CNAME file with: $domainName"
                $domainName | Out-File -FilePath ".\CNAME" -NoNewline -Encoding utf8
            }
            
            # GitHub repository settings
            Write-Host "`nDon't forget to configure GitHub Pages in repository settings:" -ForegroundColor Yellow
            Write-Host "1. Go to https://github.com/$githubUser/iBridge-main/settings/pages"
            Write-Host "2. Under 'Source', select your deployment branch (gh-pages or main)"
            Write-Host "3. Under 'Custom domain', enter: $domainName"
            Write-Host "4. Check 'Enforce HTTPS' (once certificate is provisioned)"
            Write-Host "5. Click 'Save'"
        }
    }
    "2" {
        # AWS CloudFront migration
        if ($currentHosting -eq "aws") {
            Write-Host "`nAlready configured for AWS CloudFront. No DNS changes needed." -ForegroundColor Green
        } else {
            Write-Host "`nMigrating to AWS CloudFront/S3 hosting..." -ForegroundColor Cyan
            
            # Check if we have AWS deployment scripts
            $awsDeployScript = $null
            $awsScripts = @(
                "deploy-to-aws.ps1",
                "complete-aws-deployment.ps1",
                "aws-deployment-menu.ps1",
                "github-aws-deploy.ps1"
            )
            
            foreach ($script in $awsScripts) {
                if (Test-Path ".\$script") {
                    $awsDeployScript = $script
                    break
                }
            }
            
            if ($awsDeployScript) {
                Write-Host "`nFound AWS deployment script: $awsDeployScript" -ForegroundColor Green
                Write-Host "Running AWS deployment script..."
                
                & ".\$awsDeployScript"
            } else {
                Write-Host "`nNo AWS deployment scripts found. Manual setup required:" -ForegroundColor Yellow
                Write-Host "1. Create an S3 bucket named $domainName"
                Write-Host "2. Upload your website files to the S3 bucket"
                Write-Host "3. Request an SSL certificate in AWS Certificate Manager"
                Write-Host "4. Create a CloudFront distribution pointing to your S3 bucket"
                Write-Host "5. Update your DNS records to point to the CloudFront distribution"
                
                Write-Host "`nWould you like to create a basic AWS deployment guide? (Y/N)"
                $createGuide = Read-Host
                
                if ($createGuide -eq "Y" -or $createGuide -eq "y") {
                    $awsGuideContent = @"
# AWS Deployment Guide for iBridge Website

## Prerequisites
1. AWS CLI installed and configured
2. AWS account with necessary permissions
3. Website files ready to upload

## Step-by-Step Deployment

### 1. Create S3 Bucket
```powershell
aws s3 mb s3://$domainName --region us-east-1
```

### 2. Configure S3 Bucket for Website Hosting
```powershell
aws s3 website s3://$domainName --index-document index.html --error-document error.html
```

### 3. Set Bucket Policy for Public Access
Create a file named `bucket-policy.json` with the following content:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$domainName/*"
    }
  ]
}
```

Apply the policy:
```powershell
aws s3api put-bucket-policy --bucket $domainName --policy file://bucket-policy.json
```

### 4. Upload Website Files
```powershell
aws s3 sync . s3://$domainName --exclude "*.ps1" --exclude "*.md" --exclude ".git/*"
```

### 5. Request SSL Certificate
```powershell
aws acm request-certificate --domain-name $domainName --validation-method DNS --subject-alternative-names www.$domainName --region us-east-1
```

Follow the validation instructions provided by AWS.

### 6. Create CloudFront Distribution
```powershell
aws cloudfront create-distribution --origin-domain-name $domainName.s3-website-us-east-1.amazonaws.com --default-root-object index.html
```

### 7. Update DNS Records
Update your DNS records at GoDaddy to point to the CloudFront distribution URL.

### 8. Verify Deployment
Wait for DNS changes to propagate, then visit your website to verify it's working correctly.
"@
                    
                    $awsGuideContent | Out-File -FilePath ".\AWS-DEPLOYMENT-GUIDE.md" -Encoding utf8
                    Write-Host "`nCreated AWS-DEPLOYMENT-GUIDE.md with detailed instructions" -ForegroundColor Green
                }
            }
        }
    }
    "3" {
        Write-Host "`nExiting without changes." -ForegroundColor Yellow
    }
    default {
        Write-Host "`nInvalid choice. Exiting." -ForegroundColor Red
    }
}

Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host "   HOSTING MIGRATION ASSISTANT COMPLETE   " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

Write-Host "`nRemember:"
Write-Host "1. DNS changes can take 24-48 hours to fully propagate"
Write-Host "2. SSL certificate provisioning may take time"
Write-Host "3. Use 'check-dns-configuration.ps1' to verify your DNS settings"
Write-Host "`nThank you for using the iBridge Hosting Migration Assistant!"
