# Script to sync the updated iBridge website to AWS S3
Write-Host "Syncing updated iBridge website to AWS S3..." -ForegroundColor Cyan

$s3BucketName = "ibridgesolutions.co.za" # Update this with your actual bucket name
$sourcePath = "."  # Current directory containing the website files

# Check if the AWS CLI is installed
try {
    $awsVersion = aws --version
    Write-Host "AWS CLI is installed: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "AWS CLI is not installed. Please install it before running this script." -ForegroundColor Red
    Write-Host "You can install it by running: .\deploy-to-aws.ps1" -ForegroundColor Yellow
    exit 1
}

# Check if AWS CLI is configured
try {
    aws configure list > $null
    Write-Host "AWS CLI is configured" -ForegroundColor Green
} catch {
    Write-Host "AWS CLI is not configured. Please configure it before running this script." -ForegroundColor Red
    Write-Host "You can configure it by running: aws configure" -ForegroundColor Yellow
    exit 1
}

# Sync the website files to S3
Write-Host "Syncing files to S3 bucket: $s3BucketName..." -ForegroundColor Cyan
aws s3 sync $sourcePath s3://$s3BucketName --exclude ".git/*" --exclude "*.ps1" --exclude "*.md" --delete

if ($LASTEXITCODE -eq 0) {
    Write-Host "Website files successfully synced to S3!" -ForegroundColor Green
    
    # Check if there's a CloudFront distribution to invalidate
    Write-Host "Checking for CloudFront distribution..." -ForegroundColor Cyan
    $distributions = aws cloudfront list-distributions --output json | ConvertFrom-Json
    
    if ($distributions.DistributionList.Items.Count -gt 0) {
        $distribution = $distributions.DistributionList.Items | Where-Object { $_.Origins.Items[0].DomainName -like "*$s3BucketName*" }
        
        if ($distribution) {
            $distributionId = $distribution.Id
            Write-Host "Found CloudFront distribution: $distributionId" -ForegroundColor Green
            Write-Host "Creating CloudFront invalidation to update cached content..." -ForegroundColor Cyan
            
            aws cloudfront create-invalidation --distribution-id $distributionId --paths "/*"
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "CloudFront invalidation created successfully!" -ForegroundColor Green
                Write-Host "Your updated website should be visible in a few minutes." -ForegroundColor Green
            } else {
                Write-Host "Failed to create CloudFront invalidation. Your changes might take up to 24 hours to propagate." -ForegroundColor Yellow
            }
        } else {
            Write-Host "No CloudFront distribution found for bucket: $s3BucketName" -ForegroundColor Yellow
            Write-Host "If you're using CloudFront, you may need to create an invalidation manually." -ForegroundColor Yellow
        }
    } else {
        Write-Host "No CloudFront distributions found." -ForegroundColor Yellow
        Write-Host "Your website is updated on S3 and should be live immediately if using direct S3 website hosting." -ForegroundColor Green
    }
    
    Write-Host "Website URL: http://$s3BucketName.s3-website.$((aws configure get region).Trim()).amazonaws.com" -ForegroundColor Cyan
    Write-Host "Domain: https://$s3BucketName" -ForegroundColor Cyan
} else {
    Write-Host "Failed to sync website files to S3. Check your AWS credentials and permissions." -ForegroundColor Red
}
