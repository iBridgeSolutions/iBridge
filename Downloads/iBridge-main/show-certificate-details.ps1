# Certificate Details Script
# This script shows details about your SSL certificate and validation records

$region = "us-east-1"
$awsCmd = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       CERTIFICATE DETAILS FOR IBRIDGESOLUTIONS   " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Get certificate ARN from file
if (Test-Path "certificate-arn.txt") {
    $certArn = Get-Content -Path "certificate-arn.txt" -Raw
    $certArn = $certArn.Trim()
    
    Write-Host "Certificate ARN: $certArn" -ForegroundColor Yellow
      # Get certificate details
    Write-Host "`nFetching certificate details..." -ForegroundColor Yellow
    $output = & $awsCmd acm describe-certificate --certificate-arn $certArn --region $region 2>$null
    $certDetails = $output | ConvertFrom-Json
    
    if ($certDetails) {
        $cert = $certDetails.Certificate
        
        # Display basic info
        Write-Host "`nCERTIFICATE INFORMATION:" -ForegroundColor Cyan
        Write-Host "Domain: $($cert.DomainName)" -ForegroundColor White
        Write-Host "Status: $($cert.Status)" -ForegroundColor (if ($cert.Status -eq "ISSUED") { "Green" } else { "Yellow" })
        Write-Host "Type: $($cert.Type)" -ForegroundColor White
        
        # Display validation details
        Write-Host "`nVALIDATION DETAILS:" -ForegroundColor Cyan
        
        foreach ($validation in $cert.DomainValidationOptions) {
            $domain = $validation.DomainName
            $validationStatus = $validation.ValidationStatus
            
            Write-Host "`nDomain: $domain" -ForegroundColor White
            Write-Host "Validation Status: $validationStatus" -ForegroundColor (if ($validationStatus -eq "SUCCESS") { "Green" } else { "Yellow" })
            
            if ($validation.ResourceRecord) {
                $recordName = $validation.ResourceRecord.Name
                $recordValue = $validation.ResourceRecord.Value
                $recordType = $validation.ResourceRecord.Type
                
                # Extract just the hostname part for GoDaddy
                $hostname = $recordName -replace "\.ibridgesolutions\.co\.za\.$", ""
                
                Write-Host "`nDNS Record to Add in GoDaddy:" -ForegroundColor White
                Write-Host "Type: $recordType" -ForegroundColor Green
                Write-Host "Host: $hostname" -ForegroundColor Green
                Write-Host "Value: $recordValue" -ForegroundColor Green
                Write-Host "TTL: 1 Hour" -ForegroundColor Green
            }
        }
        
        # Show next steps
        Write-Host "`n==================================================" -ForegroundColor Cyan
        Write-Host "                  NEXT STEPS                      " -ForegroundColor Cyan
        Write-Host "==================================================" -ForegroundColor Cyan
        
        if ($cert.Status -eq "PENDING_VALIDATION") {
            Write-Host "1. Add the DNS records shown above to your GoDaddy domain" -ForegroundColor Yellow
            Write-Host "2. Wait approximately 30 minutes for validation" -ForegroundColor Yellow
            Write-Host "3. Run this script again to check validation status" -ForegroundColor Yellow
        }
        elseif ($cert.Status -eq "ISSUED") {
            Write-Host "Your certificate is validated and ready to use!" -ForegroundColor Green
            Write-Host "Run the CloudFront setup script to create your distribution:" -ForegroundColor Yellow
            Write-Host "powershell -ExecutionPolicy Bypass -File .\setup-cloudfront.ps1" -ForegroundColor White
        }
        else {
            Write-Host "Certificate status: $($cert.Status)" -ForegroundColor Yellow
            Write-Host "Check the AWS Management Console for more details" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Failed to retrieve certificate details" -ForegroundColor Red
    }
}
else {
    Write-Host "No certificate ARN found. Please request a certificate first:" -ForegroundColor Red
    Write-Host "powershell -ExecutionPolicy Bypass -File .\request-cert.ps1" -ForegroundColor White
}
