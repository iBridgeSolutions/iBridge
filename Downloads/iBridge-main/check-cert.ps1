# Simple Certificate Validation Check Script
$region = "us-east-1"
$awsCmd = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"

# Get certificate ARN from file
if (Test-Path "certificate-arn.txt") {
    $certArn = Get-Content -Path "certificate-arn.txt" -Raw
    $certArn = $certArn.Trim()
    Write-Host "Certificate ARN: $certArn" -ForegroundColor Cyan
    
    # Get certificate details
    $certDetails = & $awsCmd acm describe-certificate --certificate-arn $certArn --region $region | ConvertFrom-Json
    
    # Check validation status
    $status = $certDetails.Certificate.Status
    Write-Host "Certificate Status: $status" -ForegroundColor (if ($status -eq "ISSUED") { "Green" } else { "Yellow" })
    
    if ($status -eq "PENDING_VALIDATION") {
        Write-Host "`nCertificate is pending validation. Add these DNS records to GoDaddy:" -ForegroundColor Yellow
        
        foreach ($validation in $certDetails.Certificate.DomainValidationOptions) {
            if ($validation.ResourceRecord) {
                $domain = $validation.DomainName
                $recordName = $validation.ResourceRecord.Name
                $recordValue = $validation.ResourceRecord.Value
                $recordType = $validation.ResourceRecord.Type
                
                # Extract the hostname part for GoDaddy
                $hostname = $recordName
                if ($domain -eq "ibridgesolutions.co.za") {
                    $hostname = $recordName -replace "\.ibridgesolutions\.co\.za\.$", ""
                } else {
                    $hostname = $recordName -replace "\.$domain\.$", ""
                }
                
                Write-Host "`nFor domain: $domain" -ForegroundColor White
                Write-Host "Type: $recordType" -ForegroundColor Green
                Write-Host "Host: $hostname" -ForegroundColor Green
                Write-Host "Value: $recordValue" -ForegroundColor Green
                Write-Host "TTL: 1 Hour" -ForegroundColor Green
            }
        }
    } elseif ($status -eq "ISSUED") {
        Write-Host "`nCertificate has been validated and issued!" -ForegroundColor Green
        Write-Host "You can now run .\setup-cloudfront.ps1 to create your CloudFront distribution" -ForegroundColor Green
    } else {
        Write-Host "`nCertificate status: $status" -ForegroundColor Yellow
        Write-Host "Check the AWS Management Console for more details" -ForegroundColor Yellow
    }
} else {
    Write-Host "No certificate ARN found. Please request a certificate first:" -ForegroundColor Red
    Write-Host "powershell -ExecutionPolicy Bypass -File .\request-cert.ps1" -ForegroundColor White
}
