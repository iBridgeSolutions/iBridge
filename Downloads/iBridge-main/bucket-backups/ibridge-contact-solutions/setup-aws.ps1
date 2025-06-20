# AWS Setup Script for iBridge Solutions
# This script sets up the basic AWS infrastructure for the website

# Configuration
$accountId = "640825887118"
$websiteFolder = "c:\Users\Lwandile Gasela\Downloads\iBridge-main\iBridge-main\iBridge-main"
$s3BucketName = "ibridgesolutions-website-$accountId"
$region = "us-east-1" # Use us-east-1 for SSL certificates to work with CloudFront
$domainName = "ibridgesolutions.co.za"
$wwwDomainName = "www.ibridgesolutions.co.za"
$awsCmd = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"

# Header
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "      AWS SETUP SCRIPT FOR IBRIDGESOLUTIONS      " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Account ID: 6408-2588-7118" -ForegroundColor Yellow
Write-Host "Domain: $domainName" -ForegroundColor Yellow
Write-Host

# Configure AWS CLI
Write-Host "Setting up AWS credentials..." -ForegroundColor Yellow
Write-Host "`nPlease enter your AWS credentials:" -ForegroundColor Cyan
Write-Host "(These can be found in the AWS Console under Security Credentials)" -ForegroundColor Cyan
            
$accessKey = Read-Host "AWS Access Key ID"
$secretKey = Read-Host "AWS Secret Access Key" -AsSecureString
$secretKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretKey))
            
# Configure AWS CLI with provided credentials
& $awsCmd configure set aws_access_key_id $accessKey
& $awsCmd configure set aws_secret_access_key $secretKeyPlain
& $awsCmd configure set default.region $region
& $awsCmd configure set default.output json
            
Write-Host "AWS credentials configured successfully." -ForegroundColor Green

# Create S3 bucket
Write-Host "`nCreating S3 bucket for website hosting..." -ForegroundColor Yellow
try {
    & $awsCmd s3api create-bucket --bucket $s3BucketName --region $region
    Write-Host "S3 bucket created successfully." -ForegroundColor Green
    
    # Enable website hosting on the S3 bucket
    & $awsCmd s3 website $s3BucketName --index-document index.html --error-document index.html
    Write-Host "Website hosting enabled on S3 bucket." -ForegroundColor Green
    
    # Set bucket policy to allow public read access
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
    $bucketPolicy | Out-File -FilePath "bucket-policy.json" -Encoding ascii
    & $awsCmd s3api put-bucket-policy --bucket $s3BucketName --policy file://bucket-policy.json
    Write-Host "Bucket policy set to allow public read access." -ForegroundColor Green
} catch {
    Write-Host "Error creating S3 bucket: $_" -ForegroundColor Red
}

# Request SSL certificate
Write-Host "`nRequesting SSL certificate..." -ForegroundColor Yellow
try {
    $certificateArn = & $awsCmd acm request-certificate --domain-name $domainName --validation-method DNS --subject-alternative-names $wwwDomainName --region $region
    Write-Host "SSL certificate requested successfully." -ForegroundColor Green
    Write-Host "Certificate ARN: $certificateArn" -ForegroundColor Green
    
    # Get certificate validation information
    $certificateDetails = & $awsCmd acm describe-certificate --certificate-arn $certificateArn --region $region
    Write-Host "Certificate validation information retrieved." -ForegroundColor Green
    
    # Display DNS validation records that need to be added to GoDaddy
    Write-Host "`nIMPORTANT: Add these DNS validation records to your GoDaddy domain:" -ForegroundColor Red
    Write-Host "For detailed instructions, visit your GoDaddy DNS management page." -ForegroundColor Yellow
    
    # Extract and show validation records
    $certificateDetails | ConvertFrom-Json | Select-Object -ExpandProperty Certificate | Select-Object -ExpandProperty DomainValidationOptions | ForEach-Object {
        Write-Host "Record Name: $($_.ResourceRecord.Name)" -ForegroundColor Cyan
        Write-Host "Record Type: $($_.ResourceRecord.Type)" -ForegroundColor Cyan
        Write-Host "Record Value: $($_.ResourceRecord.Value)" -ForegroundColor Cyan
        Write-Host
    }
} catch {
    Write-Host "Error requesting SSL certificate: $_" -ForegroundColor Red
}

# Upload website files to S3
Write-Host "`nUploading website files to S3..." -ForegroundColor Yellow
try {
    & $awsCmd s3 sync $websiteFolder s3://$s3BucketName --delete
    Write-Host "Website files uploaded successfully." -ForegroundColor Green
} catch {
    Write-Host "Error uploading website files: $_" -ForegroundColor Red
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "      NEXT STEPS FOR IBRIDGESOLUTIONS WEBSITE    " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "1. Add the DNS validation records to GoDaddy to validate your SSL certificate" -ForegroundColor Yellow
Write-Host "2. Wait for certificate validation (can take up to 30 minutes)" -ForegroundColor Yellow
Write-Host "3. Run the check-certificate-validation.ps1 script to verify certificate status" -ForegroundColor Yellow
Write-Host "4. After certificate validation, run the setup-cloudfront.ps1 script" -ForegroundColor Yellow
