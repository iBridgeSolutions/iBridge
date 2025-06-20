# Get-Certificate-ARN.ps1
# Script to list certificates and find ARN

$awsCmd = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
$region = "us-east-1"
$domainName = "ibridgesolutions.co.za"

Write-Host "Listing certificates for $domainName..." -ForegroundColor Yellow

try {
    $certificates = & $awsCmd acm list-certificates --region $region | ConvertFrom-Json
    
    if ($certificates.CertificateSummaryList) {
        foreach ($cert in $certificates.CertificateSummaryList) {
            if ($cert.DomainName -eq $domainName) {
                Write-Host "`nFound certificate for $domainName!" -ForegroundColor Green
                Write-Host "Certificate ARN: $($cert.CertificateArn)" -ForegroundColor Cyan
                Write-Host "`nYou can use this ARN for the CloudFront setup script." -ForegroundColor Yellow
                exit
            }
        }
        
        Write-Host "No certificate found for $domainName" -ForegroundColor Red
        
        # List all certificates as a fallback
        Write-Host "`nAvailable certificates:" -ForegroundColor Yellow
        foreach ($cert in $certificates.CertificateSummaryList) {
            Write-Host "Domain: $($cert.DomainName)" -ForegroundColor White
            Write-Host "ARN: $($cert.CertificateArn)" -ForegroundColor Cyan
            Write-Host ""
        }
    }
    else {
        Write-Host "No certificates found in your account." -ForegroundColor Red
        Write-Host "You need to run the setup-aws.ps1 script first to create a certificate." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error checking certificates: $_" -ForegroundColor Red
}
