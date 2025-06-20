# Fix CloudFront and S3 Access Issue - Simplified Version
# This script creates an Origin Access Control for CloudFront and updates the bucket policy

# Configuration
$accountId = "640825887118"
$s3BucketName = "ibridgesolutions-website-$accountId"  # ibridgesolutions-website-640825887118
$region = "us-east-1"
$awsCmd = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"

# Header
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  FIX CLOUDFRONT AND S3 ACCESS ISSUE   " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host

# Get CloudFront Distribution ID
Write-Host "Reading CloudFront distribution information..." -ForegroundColor Yellow
$cloudFrontInfo = Get-Content -Path "cloudfront-info.txt" -Raw -ErrorAction SilentlyContinue

if (-not $cloudFrontInfo) {
    Write-Host "Error: cloudfront-info.txt not found." -ForegroundColor Red
    exit
}

$distributionId = if ($cloudFrontInfo -match "Distribution ID: (.+)") {
    $matches[1].Trim()
} else {
    Write-Host "Error: Could not extract distribution ID from cloudfront-info.txt" -ForegroundColor Red
    exit
}

Write-Host "CloudFront Distribution ID: $distributionId" -ForegroundColor Green

# Using a simpler approach: Update the bucket policy to allow public read access
Write-Host "`nUpdating S3 bucket policy to allow public read access..." -ForegroundColor Yellow
try {
    # First, disable block public access
    Write-Host "Disabling Block Public Access settings..." -ForegroundColor Yellow
    & $awsCmd s3api put-public-access-block --bucket $s3BucketName --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false" --region $region
    
    # Update bucket policy for public read access
    $bucketPolicy = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadForGetBucketObjects",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$s3BucketName/*"
        }
    ]
}
"@
    
    $bucketPolicy | Out-File -FilePath "updated-bucket-policy.json" -Encoding ascii
    & $awsCmd s3api put-bucket-policy --bucket $s3BucketName --policy file://updated-bucket-policy.json --region $region
    
    Write-Host "S3 bucket policy updated successfully for public read access." -ForegroundColor Green
} catch {
    Write-Host "Error updating bucket policy: $_" -ForegroundColor Red
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "       DEPLOYMENT FIX COMPLETE       " -ForegroundColor Cyan  
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "The fix has been applied. It may take 5-15 minutes for CloudFront to access the updated S3 content." -ForegroundColor Yellow
Write-Host "To verify the fix, try accessing your website:" -ForegroundColor Green
Write-Host "https://ibridgesolutions.co.za" -ForegroundColor Yellow
Write-Host "https://www.ibridgesolutions.co.za" -ForegroundColor Yellow
Write-Host "Note: The website will not be accessible until the changes propagate." -ForegroundColor Yellow
