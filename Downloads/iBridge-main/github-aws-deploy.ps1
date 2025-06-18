# Combined GitHub and AWS Deployment Script for iBridge Website
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " iBridge Website GitHub & AWS Deployment Tool" -ForegroundColor Cyan  
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host

# Configuration parameters
$s3BucketName = "ibridgesolutions-website-6408258887118" # Primary bucket name from the AWS S3 ls command
$region = "us-east-1" # AWS region
$cloudFrontDistributionId = "" # Will be retrieved or prompted if needed

#==========================================
# GITHUB DEPLOYMENT SECTION
#==========================================

# Function to check if git is installed
function Check-GitInstalled {
    try {
        $gitVersion = git --version
        Write-Host "Git is installed: $gitVersion" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Git is not installed or not in PATH!" -ForegroundColor Red
        return $false
    }
}

# Function to commit and push changes to GitHub
function Commit-AndPushToGitHub {
    param(
        [string]$CommitMessage
    )
    
    Write-Host "`n[1/3] GITHUB DEPLOYMENT" -ForegroundColor Cyan
    Write-Host "--------------------" -ForegroundColor Cyan
    
    # Add all modified HTML files
    Write-Host "Adding modified HTML files..." -ForegroundColor Yellow
    git add about.html ai-automation.html contact-center.html contact.html it-support.html index.html services.html
    
    # Add CSS and JS directories
    git add css/* js/*
    
    # Add new utility script files
    git add preview-website.ps1 validate-contact-center.ps1
    
    # Commit changes
    Write-Host "Committing changes..." -ForegroundColor Yellow
    git commit -m "$CommitMessage"
    
    # Push to remote repository
    Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
    git push origin gh-pages
    
    # Check status after push
    Write-Host "GitHub deployment status:" -ForegroundColor Yellow
    git status
    
    Write-Host "GitHub deployment completed!" -ForegroundColor Green
}

#==========================================
# AWS DEPLOYMENT SECTION
#==========================================

# Function to check if AWS CLI is installed
function Check-AwsCliInstalled {
    try {
        $awsVersion = aws --version
        Write-Host "AWS CLI is installed: $awsVersion" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "AWS CLI is not installed or not in PATH!" -ForegroundColor Red
        return $false
    }
}

# Function to check AWS configuration
function Check-AwsConfiguration {
    try {
        $awsIdentity = aws sts get-caller-identity
        Write-Host "AWS credentials are configured:" -ForegroundColor Green
        Write-Host $awsIdentity -ForegroundColor Green
        return $true
    } catch {
        Write-Host "AWS credentials are not configured properly!" -ForegroundColor Red
        Write-Host "Run 'aws configure' to set up your AWS credentials." -ForegroundColor Yellow
        return $false
    }
}

# Function to retrieve CloudFront distribution ID if not provided
function Get-CloudFrontDistributionId {
    try {
        Write-Host "Retrieving CloudFront distributions..." -ForegroundColor Yellow
        $distributions = aws cloudfront list-distributions --query "DistributionList.Items[].{Id:Id, DomainName:DomainName, Origins:Origins.Items[].DomainName}" --output json | ConvertFrom-Json
        
        if ($null -eq $distributions -or $distributions.Count -eq 0) {
            Write-Host "No CloudFront distributions found. Please enter distribution ID manually:" -ForegroundColor Yellow
            $distributionId = Read-Host "CloudFront Distribution ID"
            return $distributionId
        }
        
        Write-Host "Found CloudFront distributions:" -ForegroundColor Green
        for ($i=0; $i -lt $distributions.Count; $i++) {
            Write-Host "[$i] ID: $($distributions[$i].Id), Domain: $($distributions[$i].DomainName)" -ForegroundColor White
        }
        
        $selection = Read-Host "Enter the number of the distribution to use [0-$($distributions.Count - 1)]"
        if ([int]::TryParse($selection, [ref]$null) -and [int]$selection -ge 0 -and [int]$selection -lt $distributions.Count) {
            return $distributions[[int]$selection].Id
        } else {
            $manualId = Read-Host "Invalid selection. Please enter Distribution ID manually"
            return $manualId
        }
    } catch {
        Write-Host "Error retrieving CloudFront distributions. Please enter distribution ID manually:" -ForegroundColor Red
        $distributionId = Read-Host "CloudFront Distribution ID"
        return $distributionId
    }
}

# Function to deploy to S3
function Deploy-ToS3 {
    param(
        [string]$BucketName
    )
    
    Write-Host "`n[2/3] AWS S3 DEPLOYMENT" -ForegroundColor Cyan
    Write-Host "--------------------" -ForegroundColor Cyan
    Write-Host "Deploying files to S3 bucket: $BucketName..." -ForegroundColor Yellow
    
    # First verify the bucket exists
    try {
        Write-Host "Verifying S3 bucket access..." -ForegroundColor Yellow
        aws s3 ls s3://$BucketName/ > $null
    }
    catch {
        Write-Host "Error accessing S3 bucket: $BucketName. Please check permissions and bucket name." -ForegroundColor Red
        return $false
    }
    
    # Sync HTML files
    Write-Host "Uploading HTML files..." -ForegroundColor White
    aws s3 sync . s3://$BucketName/ --exclude "*" --include "*.html" --content-type "text/html" --acl public-read
    
    # Sync CSS files
    Write-Host "Uploading CSS files..." -ForegroundColor White
    aws s3 sync ./css/ s3://$BucketName/css/ --exclude "*" --include "*.css" --content-type "text/css" --acl public-read
    
    # Sync JS files
    Write-Host "Uploading JavaScript files..." -ForegroundColor White
    aws s3 sync ./js/ s3://$BucketName/js/ --exclude "*" --include "*.js" --content-type "application/javascript" --acl public-read
    
    # Sync image files (if they exist in the images directory)
    if (Test-Path "./images/") {
        Write-Host "Uploading image files..." -ForegroundColor White
        aws s3 sync ./images/ s3://$BucketName/images/ --exclude "*" --include "*.jpg" --include "*.jpeg" --include "*.png" --include "*.gif" --include "*.svg" --acl public-read
    }
    
    Write-Host "S3 deployment completed!" -ForegroundColor Green
    return $true
}

# Function to invalidate CloudFront cache
function Invalidate-CloudFrontCache {
    param(
        [string]$DistributionId
    )
    
    Write-Host "`n[3/3] CLOUDFRONT INVALIDATION" -ForegroundColor Cyan
    Write-Host "--------------------" -ForegroundColor Cyan
    
    if ([string]::IsNullOrEmpty($DistributionId)) {
        Write-Host "CloudFront Distribution ID not provided, skipping cache invalidation." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Invalidating CloudFront cache for distribution: $DistributionId..." -ForegroundColor Yellow
    
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    aws cloudfront create-invalidation --distribution-id $DistributionId --paths "/*" --reference "update-$timestamp"
    
    Write-Host "CloudFront invalidation initiated!" -ForegroundColor Green
    Write-Host "The website will be updated on CDN edge locations within a few minutes." -ForegroundColor White
}

#==========================================
# MAIN EXECUTION
#==========================================

# Check prerequisites
$gitInstalled = Check-GitInstalled
$awsInstalled = Check-AwsCliInstalled
$awsConfigured = $awsInstalled -and (Check-AwsConfiguration)

# Collect information for deployment
if ($gitInstalled) {
    # Get commit message from user
    $defaultMessage = "Update Contact Center page to standalone page and update all site navigation/footer links"
    $commitMessage = Read-Host "Enter GitHub commit message (default: '$defaultMessage')"
    
    if ([string]::IsNullOrWhiteSpace($commitMessage)) {
        $commitMessage = $defaultMessage
    }
}

if ($awsConfigured) {
    # Confirm bucket name
    $confirmBucket = Read-Host "Deploy to S3 bucket '$s3BucketName'? Enter to confirm or type a different bucket name"
    if (-not [string]::IsNullOrWhiteSpace($confirmBucket)) {
        $s3BucketName = $confirmBucket
    }
    
    # Get CloudFront distribution ID if not already set
    if ([string]::IsNullOrEmpty($cloudFrontDistributionId)) {
        $cloudFrontDistributionId = Get-CloudFrontDistributionId
    }
}

# Final confirmation before deployment
Write-Host "`nREADY TO DEPLOY" -ForegroundColor White
Write-Host "--------------------" -ForegroundColor White
if ($gitInstalled) {
    Write-Host "GitHub: Changes will be committed with message '$commitMessage'" -ForegroundColor Yellow
}
if ($awsConfigured) {
    Write-Host "AWS S3: Files will be deployed to bucket '$s3BucketName'" -ForegroundColor Yellow
    Write-Host "CloudFront: Cache for distribution '$cloudFrontDistributionId' will be invalidated" -ForegroundColor Yellow
}

$confirmation = Read-Host "`nProceed with deployment? (y/n)"
if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
    # 1. Deploy to GitHub if git is installed
    if ($gitInstalled) {
        Commit-AndPushToGitHub -CommitMessage $commitMessage
    } else {
        Write-Host "`n[1/3] GITHUB DEPLOYMENT: SKIPPED - Git not installed" -ForegroundColor Yellow
    }
    
    # 2. Deploy to AWS S3 if AWS CLI is configured
    if ($awsConfigured) {
        $s3Success = Deploy-ToS3 -BucketName $s3BucketName
        
        # 3. Invalidate CloudFront cache if S3 deployment was successful
        if ($s3Success) {
            Invalidate-CloudFrontCache -DistributionId $cloudFrontDistributionId
        } else {
            Write-Host "`n[3/3] CLOUDFRONT INVALIDATION: SKIPPED - S3 deployment failed" -ForegroundColor Yellow
        }
    } else {
        Write-Host "`n[2/3] AWS S3 DEPLOYMENT: SKIPPED - AWS CLI not configured" -ForegroundColor Yellow
        Write-Host "`n[3/3] CLOUDFRONT INVALIDATION: SKIPPED - AWS CLI not configured" -ForegroundColor Yellow
    }
    
    # Final completion message
    Write-Host "`n=======================================" -ForegroundColor Cyan
    Write-Host "DEPLOYMENT PROCESS COMPLETE!" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host "Website should be accessible at https://ibridgesolutions.co.za" -ForegroundColor Green
} else {
    Write-Host "`nDeployment cancelled by user." -ForegroundColor Yellow
}
