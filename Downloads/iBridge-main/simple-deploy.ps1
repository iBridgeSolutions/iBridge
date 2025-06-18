# Simplified Deployment Script for iBridge Website
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " iBridge Website Simplified Deployment Tool" -ForegroundColor Cyan  
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host

# Configuration parameters
$s3BucketName = "ibridgesolutions-website-6408258887118" # Primary bucket name

# Function to focus only on essential modified files
function Deploy-EssentialFiles {
    Write-Host "Preparing to deploy only essential Contact Center page changes..." -ForegroundColor Yellow
    
    # List of critical files that were modified
    $criticalFiles = @(
        "index.html",
        "about.html", 
        "services.html",
        "contact.html",
        "contact-center.html",
        "it-support.html",
        "ai-automation.html"
    )
    
    # Check which files exist and collect them for deployment
    $filesToDeploy = @()
    foreach ($file in $criticalFiles) {
        if (Test-Path $file) {
            $filesToDeploy += $file
            Write-Host "- Found $file" -ForegroundColor Green
        } else {
            Write-Host "- Missing $file (will be skipped)" -ForegroundColor Yellow
        }
    }
    
    return $filesToDeploy
}

# Function to handle S3 deployment of specific files
function Deploy-FilesToS3 {
    param(
        [string]$BucketName,
        [array]$Files
    )
    
    Write-Host "`nUploading only essential files to S3 bucket: $BucketName..." -ForegroundColor Yellow
    
    # Check if AWS CLI is accessible
    try {
        aws --version | Out-Null
    } catch {
        Write-Host "Error: AWS CLI is not accessible. Please ensure AWS CLI is installed and configured." -ForegroundColor Red
        return $false
    }
    
    # Upload each file individually to minimize changes
    foreach ($file in $Files) {
        Write-Host "Uploading $file..." -ForegroundColor White
        try {
            # Upload with appropriate content type
            $contentType = if ($file -like "*.html") { "text/html" } elseif ($file -like "*.css") { "text/css" } else { "application/octet-stream" }
            aws s3 cp $file s3://$BucketName/$file --content-type $contentType --acl public-read
            Write-Host "√ Uploaded $file successfully" -ForegroundColor Green
        } catch {
            Write-Host "× Failed to upload $file: $_" -ForegroundColor Red
        }
    }
    
    Write-Host "File uploads completed!" -ForegroundColor Green
    return $true
}

# Main execution
Write-Host "Finding essential modified files..." -ForegroundColor Cyan
$filesToDeploy = Deploy-EssentialFiles

if ($filesToDeploy.Count -eq 0) {
    Write-Host "No essential files found to deploy!" -ForegroundColor Red
    exit
}

# Confirm bucket name
$confirmBucket = Read-Host "Deploy to S3 bucket '$s3BucketName'? Enter to confirm or type a different bucket name"
if (-not [string]::IsNullOrWhiteSpace($confirmBucket)) {
    $s3BucketName = $confirmBucket
}

# Confirmation before deployment
Write-Host "`nReady to deploy ${$filesToDeploy.Count} essential files to AWS S3 bucket: $s3BucketName" -ForegroundColor Cyan
$filesToDeploy | ForEach-Object { Write-Host "- $_" -ForegroundColor White }

$confirmation = Read-Host "`nProceed with simplified deployment? (y/n)"
if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
    # Deploy essential files to S3
    $success = Deploy-FilesToS3 -BucketName $s3BucketName -Files $filesToDeploy
    
    if ($success) {
        Write-Host "`nWould you like to invalidate CloudFront cache? This will update your CDN but might take a few minutes. (y/n)" -ForegroundColor Yellow
        $invalidateCache = Read-Host
        
        if ($invalidateCache -eq 'y' -or $invalidateCache -eq 'Y') {
            # Simple CloudFront invalidation
            $distributionId = Read-Host "Enter your CloudFront distribution ID"
            if (-not [string]::IsNullOrWhiteSpace($distributionId)) {
                Write-Host "Invalidating CloudFront cache..." -ForegroundColor Yellow
                try {
                    aws cloudfront create-invalidation --distribution-id $distributionId --paths "/*" 
                    Write-Host "CloudFront invalidation initiated successfully!" -ForegroundColor Green
                } catch {
                    Write-Host "Failed to invalidate CloudFront cache: $_" -ForegroundColor Red
                }
            }
        }
        
        Write-Host "`n=================================================" -ForegroundColor Cyan
        Write-Host " SIMPLIFIED DEPLOYMENT COMPLETED SUCCESSFULLY!" -ForegroundColor Cyan
        Write-Host "=================================================" -ForegroundColor Cyan
        Write-Host "Website updates should be visible at https://ibridgesolutions.co.za" -ForegroundColor Green
        Write-Host "(It may take a few minutes for CloudFront to update all edge locations)" -ForegroundColor Yellow
    }
} else {
    Write-Host "`nDeployment cancelled." -ForegroundColor Yellow
}
