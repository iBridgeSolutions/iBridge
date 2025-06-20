# AWS Deployment Script for iBridgeSolutions Website

# Configuration
$websiteFolder = "c:\Users\Lwandile Gasela\Downloads\iBridge-main\iBridge-main\iBridge-main"
$s3BucketName = "ibridgesolutions.co.za"
$region = "eu-west-1" # Change this to your preferred region
$distributionId = "" # You'll add your CloudFront distribution ID later

function Check-AwsCliInstalled {
    try {
        $awsVersion = aws --version
        Write-Host "AWS CLI is already installed: $awsVersion" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "AWS CLI is not installed. Would you like to install it now? (y/n)" -ForegroundColor Yellow
        $response = Read-Host
        
        if ($response.ToLower() -eq "y") {
            Write-Host "Installing AWS CLI..." -ForegroundColor Cyan
            Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "AWSCLIV2.msi"
            Start-Process msiexec.exe -Wait -ArgumentList "/i AWSCLIV2.msi /quiet"
            Remove-Item "AWSCLIV2.msi"
            Write-Host "AWS CLI installed successfully. Please restart this script." -ForegroundColor Green
            return $false
        }
        else {
            Write-Host "AWS CLI is required for this script to work. Please install it manually." -ForegroundColor Red
            return $false
        }
    }
}

function Configure-AwsCli {
    Write-Host "Let's configure your AWS credentials." -ForegroundColor Yellow
    Write-Host "You'll need your AWS Access Key ID and Secret Access Key from your AWS account." -ForegroundColor Yellow
    Write-Host "If you don't have these, create them in the AWS Console under IAM > Users > Security credentials." -ForegroundColor Yellow
    
    $accessKey = Read-Host "Enter your AWS Access Key ID"
    $secretKey = Read-Host "Enter your AWS Secret Access Key" -AsSecureString
    $secretKeyText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretKey))
    
    # Set AWS credentials using the AWS CLI
    $env:AWS_ACCESS_KEY_ID = $accessKey
    $env:AWS_SECRET_ACCESS_KEY = $secretKeyText
    $env:AWS_DEFAULT_REGION = $region
    
    # Configure AWS CLI
    Write-Host "Configuring AWS CLI..." -ForegroundColor Cyan
    aws configure set aws_access_key_id $accessKey
    aws configure set aws_secret_access_key $secretKeyText
    aws configure set default.region $region
    aws configure set default.output json
    
    Write-Host "AWS CLI configured successfully." -ForegroundColor Green
}

function Prepare-Website {
    Write-Host "Preparing website files..." -ForegroundColor Cyan
    
    # Check for .nojekyll file
    $nojekyllPath = Join-Path -Path $websiteFolder -ChildPath ".nojekyll"
    if (-not (Test-Path $nojekyllPath)) {
        Write-Host "Creating .nojekyll file to prevent Jekyll processing..." -ForegroundColor Yellow
        New-Item -Path $nojekyllPath -ItemType File -Force | Out-Null
    }
    
    # Check for error.html file
    $errorPath = Join-Path -Path $websiteFolder -ChildPath "error.html"
    if (-not (Test-Path $errorPath)) {
        Write-Host "Creating basic error.html file..." -ForegroundColor Yellow
        @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error - iBridge Solutions</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            text-align: center;
        }
        .container {
            background-color: #f9f9f9;
            border-radius: 8px;
            padding: 40px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-top: 40px;
        }
        h1 {
            color: #0066cc;
        }
        .btn {
            display: inline-block;
            background-color: #0066cc;
            color: white;
            padding: 10px 20px;
            text-decoration: none;
            border-radius: 5px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Page Not Found</h1>
        <p>We're sorry, but the page you're looking for cannot be found.</p>
        <p>Please check the URL or navigate back to our homepage.</p>
        <a href="/" class="btn">Return to Homepage</a>
    </div>
</body>
</html>
"@ | Out-File -FilePath $errorPath -Encoding utf8
    }
    
    # Verify index.html is present
    $indexPath = Join-Path -Path $websiteFolder -ChildPath "index.html"
    if (-not (Test-Path $indexPath)) {
        Write-Host "ERROR: index.html file not found in $websiteFolder" -ForegroundColor Red
        return $false
    }
    
    Write-Host "Website files prepared successfully." -ForegroundColor Green
    return $true
}

function Create-S3Bucket {
    Write-Host "Checking if S3 bucket exists..." -ForegroundColor Cyan
    
    try {
        $bucketExists = aws s3api head-bucket --bucket $s3BucketName 2>&1
        Write-Host "S3 bucket '$s3BucketName' already exists." -ForegroundColor Green
    }
    catch {
        Write-Host "Creating S3 bucket '$s3BucketName'..." -ForegroundColor Yellow
        try {
            if ($region -eq "us-east-1") {
                aws s3api create-bucket --bucket $s3BucketName --region $region
            }
            else {
                aws s3api create-bucket --bucket $s3BucketName --region $region --create-bucket-configuration LocationConstraint=$region
            }
            
            Write-Host "Waiting for bucket to be created..." -ForegroundColor Cyan
            Start-Sleep -Seconds 5
            
            # Configure bucket for website hosting
            Write-Host "Configuring bucket for static website hosting..." -ForegroundColor Cyan
            aws s3 website s3://$s3BucketName/ --index-document index.html --error-document error.html
            
            # Set bucket policy for public access
            Write-Host "Setting bucket policy for public access..." -ForegroundColor Cyan
            $policy = @"
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
            $policyPath = "bucket-policy.json"
            $policy | Out-File -FilePath $policyPath -Encoding utf8
            aws s3api put-bucket-policy --bucket $s3BucketName --policy file://$policyPath
            Remove-Item -Path $policyPath
            
            Write-Host "S3 bucket created and configured successfully." -ForegroundColor Green
        }
        catch {
            Write-Host "Error creating S3 bucket: $_" -ForegroundColor Red
            return $false
        }
    }
    
    return $true
}

function Upload-Website {
    Write-Host "Uploading website files to S3 bucket..." -ForegroundColor Cyan
    
    try {
        aws s3 sync $websiteFolder s3://$s3BucketName/ --delete
        Write-Host "Website files uploaded successfully." -ForegroundColor Green
        
        # Get the S3 website URL
        $websiteUrl = "http://$s3BucketName.s3-website-$region.amazonaws.com"
        Write-Host "Your website is now available at: $websiteUrl" -ForegroundColor Cyan
        Write-Host "Note: This is just the S3 website URL. You'll use CloudFront URL for production." -ForegroundColor Yellow
        
        return $true
    }
    catch {
        Write-Host "Error uploading website files: $_" -ForegroundColor Red
        return $false
    }
}

function Invalidate-CloudFront {
    if ([string]::IsNullOrWhiteSpace($distributionId)) {
        Write-Host "CloudFront distribution ID not provided. Skipping cache invalidation." -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "Invalidating CloudFront cache..." -ForegroundColor Cyan
    
    try {
        aws cloudfront create-invalidation --distribution-id $distributionId --paths "/*"
        Write-Host "CloudFront cache invalidated successfully." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Error invalidating CloudFront cache: $_" -ForegroundColor Red
        return $false
    }
}

# Main script execution
Clear-Host
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "       AWS Deployment Script for iBridgeSolutions Website      " -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host

# Check prerequisites
if (-not (Check-AwsCliInstalled)) {
    exit
}

# Configure AWS CLI if needed
$configureAws = Read-Host "Do you want to configure AWS credentials? (y/n)"
if ($configureAws.ToLower() -eq "y") {
    Configure-AwsCli
}

# Execute deployment steps
$success = $true
$success = $success -and (Prepare-Website)
$success = $success -and (Create-S3Bucket)
$success = $success -and (Upload-Website)
$success = $success -and (Invalidate-CloudFront)

if ($success) {
    Write-Host "`nDeployment completed successfully!" -ForegroundColor Green
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Set up CloudFront for CDN and SSL (if not already done)" -ForegroundColor Cyan
    Write-Host "2. Update the script with your CloudFront distribution ID" -ForegroundColor Cyan
    Write-Host "3. Configure Route 53 for your custom domain" -ForegroundColor Cyan
    Write-Host "4. Update GoDaddy nameservers to point to Route 53" -ForegroundColor Cyan
    Write-Host "`nRefer to the aws-free-hosting-plan.md file for detailed instructions." -ForegroundColor Cyan
}
else {
    Write-Host "`nDeployment encountered errors. Please check the logs above." -ForegroundColor Red
}

Write-Host "`nPress any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
