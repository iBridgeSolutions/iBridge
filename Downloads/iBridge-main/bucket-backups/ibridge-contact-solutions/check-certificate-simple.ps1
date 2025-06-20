# Simplified Certificate Validation Check Script
# This script checks the status of your SSL certificate validation

# Configuration
$region = "us-east-1"
$awsCmd = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"

# Header
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "     SSL CERTIFICATE VALIDATION CHECK SCRIPT     " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host

# Ask for Certificate ARN
Write-Host "Please provide the SSL certificate information..." -ForegroundColor Yellow
$certificateArn = Read-Host "Enter your SSL Certificate ARN (from AWS Certificate Manager)"

# Check certificate validation status
Write-Host "`nChecking certificate validation status..." -ForegroundColor Yellow
try {
    $certificateDetails = & $awsCmd acm describe-certificate --certificate-arn $certificateArn --region $region | ConvertFrom-Json
    $status = $certificateDetails.Certificate.Status
    
    Write-Host "`nCertificate Status: $status" -ForegroundColor Yellow
    
    if ($status -eq "ISSUED") {
        Write-Host "`n✓ Certificate is fully validated and ready to use!" -ForegroundColor Green
        Write-Host "You can now run the setup-cloudfront.ps1 script to create your CloudFront distribution." -ForegroundColor Green
    }
    elseif ($status -eq "PENDING_VALIDATION") {
        Write-Host "`n! Certificate is still pending validation." -ForegroundColor Yellow
        Write-Host "Make sure you've added the required DNS validation records to your domain." -ForegroundColor Yellow
        
        # Display the validation records that need to be added
        Write-Host "`nRequired DNS validation records:" -ForegroundColor Cyan
        $certificateDetails.Certificate.DomainValidationOptions | ForEach-Object {
            if ($_.ValidationStatus -ne "SUCCESS") {
                Write-Host "Domain: $($_.DomainName)" -ForegroundColor White
                Write-Host "Record Name: $($_.ResourceRecord.Name)" -ForegroundColor White
                Write-Host "Record Type: $($_.ResourceRecord.Type)" -ForegroundColor White
                Write-Host "Record Value: $($_.ResourceRecord.Value)" -ForegroundColor White
                Write-Host
            }
        }
        
        Write-Host "Validation can take up to 30 minutes after adding DNS records." -ForegroundColor Yellow
        Write-Host "Run this script again later to check the status." -ForegroundColor Yellow
    }
    else {
        Write-Host "`n✗ Certificate validation failed with status: $status" -ForegroundColor Red
        Write-Host "You may need to request a new certificate." -ForegroundColor Red
    }
} catch {
    Write-Host "Error checking certificate: $_" -ForegroundColor Red
}

Write-Host "`n==================================================" -ForegroundColor Cyan
