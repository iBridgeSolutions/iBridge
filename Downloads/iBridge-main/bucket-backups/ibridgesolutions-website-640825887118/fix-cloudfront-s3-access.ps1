# Fix CloudFront and S3 Access Issue
# This script creates an Origin Access Identity for CloudFront and updates the bucket policy

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

# Step 1: Create Origin Access Identity (OAI)
Write-Host "`nStep 1: Creating CloudFront Origin Access Identity..." -ForegroundColor Yellow
try {
    $oaiComment = "OAI for ibridgesolutions.co.za"
    $oaiConfig = @"
{
    "CallerReference": "ibridgesolutions-oai-$(Get-Date -Format 'yyyyMMddHHmmss')",
    "Comment": "$oaiComment"
}
"@
    
    $oaiConfig | Out-File -FilePath "oai-config.json" -Encoding ascii
    $oai = & $awsCmd cloudfront create-cloud-front-origin-access-identity --cloud-front-origin-access-identity-config file://oai-config.json --region $region | ConvertFrom-Json
    
    $oaiId = $oai.CloudFrontOriginAccessIdentity.Id
    $oaiS3CanonicalUserId = $oai.CloudFrontOriginAccessIdentity.S3CanonicalUserId
    
    Write-Host "Origin Access Identity created: $oaiId" -ForegroundColor Green
} catch {
    Write-Host "Error creating Origin Access Identity: $_" -ForegroundColor Red
    exit
}

# Step 2: Update S3 Bucket Policy
Write-Host "`nStep 2: Updating S3 Bucket Policy..." -ForegroundColor Yellow
try {
    $bucketPolicy = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCloudFrontServicePrincipal",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$s3BucketName/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "arn:aws:cloudfront::$accountId:distribution/$distributionId"
                }
            }
        }
    ]
}
"@
    
    $bucketPolicy | Out-File -FilePath "updated-bucket-policy.json" -Encoding ascii
    & $awsCmd s3api put-bucket-policy --bucket $s3BucketName --policy file://updated-bucket-policy.json --region $region
    
    Write-Host "S3 bucket policy updated successfully." -ForegroundColor Green
} catch {
    Write-Host "Error updating bucket policy: $_" -ForegroundColor Red
}

# Step 3: Get Current CloudFront Configuration
Write-Host "`nStep 3: Getting current CloudFront configuration..." -ForegroundColor Yellow
try {
    & $awsCmd cloudfront get-distribution-config --id $distributionId --region $region | ConvertFrom-Json > cloudfront-current-config.json
    $currentConfig = Get-Content -Raw -Path cloudfront-current-config.json | ConvertFrom-Json
    $etag = $currentConfig.ETag
    
    Write-Host "Current CloudFront configuration retrieved. ETag: $etag" -ForegroundColor Green
} catch {
    Write-Host "Error retrieving CloudFront configuration: $_" -ForegroundColor Red
    exit
}

# Step 4: Update CloudFront Distribution to use OAI
Write-Host "`nStep 4: Updating CloudFront distribution to use Origin Access Identity..." -ForegroundColor Yellow
try {
    # Create updated configuration
    $updatedConfig = $currentConfig.DistributionConfig
    
    # Update origins to use OAI
    foreach ($origin in $updatedConfig.Origins.Items) {
        if ($origin.Id -eq "S3-$s3BucketName") {
            $origin.S3OriginConfig.OriginAccessIdentity = "origin-access-identity/cloudfront/$oaiId"
        }
    }
    
    # Save updated configuration
    $updatedConfigJson = $updatedConfig | ConvertTo-Json -Depth 10
    $updatedConfigJson | Out-File -FilePath "cloudfront-updated-config.json" -Encoding ascii
    
    # Update CloudFront distribution
    & $awsCmd cloudfront update-distribution --id $distributionId --if-match $etag --distribution-config file://cloudfront-updated-config.json --region $region
    
    Write-Host "CloudFront distribution updated to use Origin Access Identity." -ForegroundColor Green
} catch {
    Write-Host "Error updating CloudFront distribution: $_" -ForegroundColor Red
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "       DEPLOYMENT FIX COMPLETE       " -ForegroundColor Cyan  
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "The fix has been applied. It may take 5-15 minutes for CloudFront to update." -ForegroundColor Yellow
Write-Host "To verify the fix, run the check-dns-propagation.ps1 script." -ForegroundColor Green
Write-Host "Note: The website will not be accessible until CloudFront updates are complete." -ForegroundColor Yellow
