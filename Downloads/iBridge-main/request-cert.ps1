# Simple SSL Certificate Request Script
$accountId = "640825887118"
$region = "us-east-1"
$domainName = "ibridgesolutions.co.za"
$wwwDomainName = "www.ibridgesolutions.co.za"
$awsCmd = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"

Write-Host "Requesting SSL certificate for $domainName..." -ForegroundColor Yellow

try {
    # Request the certificate
    $result = & $awsCmd acm request-certificate --domain-name $domainName --validation-method DNS --subject-alternative-names $wwwDomainName --region $region
    
    if ($?) {
        Write-Host "Certificate requested successfully!" -ForegroundColor Green
        $certArn = ($result | ConvertFrom-Json).CertificateArn
        Write-Host "Certificate ARN: $certArn" -ForegroundColor Cyan
        
        # Save the ARN to a file
        $certArn | Out-File -FilePath "certificate-arn.txt"
        
        # Wait a moment for AWS to generate the validation records
        Write-Host "Waiting for validation records to be generated..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        
        # Get the validation records
        $certDetails = & $awsCmd acm describe-certificate --certificate-arn $certArn --region $region | ConvertFrom-Json
        
        # Display the validation records
        Write-Host "`nAdd these DNS records to GoDaddy:" -ForegroundColor Yellow
        foreach ($validation in $certDetails.Certificate.DomainValidationOptions) {
            if ($validation.ResourceRecord) {
                Write-Host "`nDomain: $($validation.DomainName)" -ForegroundColor White
                Write-Host "Type: $($validation.ResourceRecord.Type)" -ForegroundColor Green
                
                # Extract just the hostname part for GoDaddy
                $recordName = $validation.ResourceRecord.Name
                $hostname = $recordName -replace "\.$domainName\.$", ""
                
                Write-Host "Host: $hostname" -ForegroundColor Green
                Write-Host "Value: $($validation.ResourceRecord.Value)" -ForegroundColor Green
                Write-Host "TTL: 1 Hour" -ForegroundColor Green
            }
        }
        
        Write-Host "`nAfter adding these records to GoDaddy:" -ForegroundColor Yellow
        Write-Host "1. Wait 30 minutes for AWS to validate your certificate" -ForegroundColor White
        Write-Host "2. Run .\check-certificate-validation.ps1 to check validation status" -ForegroundColor White
        Write-Host "3. Once validated, run .\setup-cloudfront.ps1 to create CloudFront distribution" -ForegroundColor White
    } else {
        Write-Host "Error requesting certificate" -ForegroundColor Red
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
