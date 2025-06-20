# Fixed AWS Certificate Validation Checker Script
# This script helps verify if your AWS Certificate validation is complete

# Configuration - use your AWS account ID
$accountId = "640825887118" # Formatted without hyphens
$region = "us-east-1"
$domainName = "ibridgesolutions.co.za"
$awsCmd = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "    AWS CERTIFICATE VALIDATION FOR IBRIDGESOLUTIONS" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Account ID: 6408-2588-7118" -ForegroundColor Yellow
Write-Host "Domain: $domainName" -ForegroundColor Yellow
Write-Host

# Get all certificates
Write-Host "Looking for SSL certificate for $domainName..." -ForegroundColor Yellow
$certificates = & $awsCmd acm list-certificates --region $region | ConvertFrom-Json
$certificateArn = $null

# Find the certificate for our domain
if ($certificates.CertificateSummaryList) {
    foreach ($cert in $certificates.CertificateSummaryList) {
        if ($cert.DomainName -eq $domainName) {
            $certificateArn = $cert.CertificateArn
            Write-Host "Found certificate for $domainName!" -ForegroundColor Green
            Write-Host "ARN: $certificateArn"
            break
        }
    }
}

if (-not $certificateArn) {
    Write-Host "No certificate found for $domainName. Please run the setup-aws.ps1 script first." -ForegroundColor Red
    exit
}

# Check certificate status
Write-Host "`nChecking certificate validation status..." -ForegroundColor Yellow
$certDetails = & $awsCmd acm describe-certificate --certificate-arn $certificateArn --region $region | ConvertFrom-Json

$validationStatus = $certDetails.Certificate.Status
Write-Host "Certificate Status: $validationStatus" -ForegroundColor (if ($validationStatus -eq "ISSUED") { "Green" } else { "Yellow" })

if ($validationStatus -eq "PENDING_VALIDATION") {
    Write-Host "`nYour certificate needs DNS validation. Add these records to your domain:" -ForegroundColor Yellow
    
    foreach ($dnsRecord in $certDetails.Certificate.DomainValidationOptions) {
        $domain = $dnsRecord.DomainName
        $recordName = $dnsRecord.ResourceRecord.Name
        $recordValue = $dnsRecord.ResourceRecord.Value
        $recordType = $dnsRecord.ResourceRecord.Type
        
        Write-Host "`nFor domain: $domain" -ForegroundColor Cyan
        Write-Host "Add this DNS record at GoDaddy:" -ForegroundColor White
        Write-Host "Type: $recordType" -ForegroundColor Green
        Write-Host "Name: $recordName" -ForegroundColor Green
        Write-Host "Value: $recordValue" -ForegroundColor Green
        Write-Host "TTL: 300 (or 1 hour)" -ForegroundColor Green
        
        # Simplify the CNAME record name for easier input at GoDaddy
        $simplifiedName = $recordName -replace "\.ibridgesolutions\.co\.za\.$", ""
        if ($simplifiedName -eq $recordName) {
            $simplifiedName = $recordName -replace "$domainName\.$", ""
        }
        
        Write-Host "`nSimplified record for GoDaddy:" -ForegroundColor Cyan
        Write-Host "Type: $recordType" -ForegroundColor Green
        Write-Host "Host: $simplifiedName" -ForegroundColor Green
        Write-Host "Points to: $recordValue" -ForegroundColor Green
        Write-Host "TTL: 1 hour" -ForegroundColor Green
    }
    
    Write-Host "`nAfter adding these records, validation can take up to 30 minutes." -ForegroundColor Yellow
    Write-Host "Run this script again later to check if validation is complete." -ForegroundColor Yellow
    
} elseif ($validationStatus -eq "ISSUED") {
    Write-Host "`nCertificate has been successfully validated and issued!" -ForegroundColor Green
    Write-Host "You can now run setup-cloudfront.ps1 to create your CloudFront distribution." -ForegroundColor Green
    Write-Host "Certificate ARN: $certificateArn" -ForegroundColor Yellow
    
    # Check if there's a CloudFront distribution using this certificate
    Write-Host "`nChecking for CloudFront distributions using this certificate..." -ForegroundColor Yellow
    $distributions = & $awsCmd cloudfront list-distributions | ConvertFrom-Json
    $usingDistribution = $false
    
    if ($distributions.DistributionList.Items) {
        foreach ($dist in $distributions.DistributionList.Items) {
            if ($dist.ViewerCertificate.ACMCertificateArn -eq $certificateArn) {
                $usingDistribution = $true
                Write-Host "Found CloudFront distribution using this certificate:" -ForegroundColor Green
                Write-Host "ID: $($dist.Id)" -ForegroundColor Cyan
                Write-Host "Domain: $($dist.DomainName)" -ForegroundColor Cyan
                Write-Host "Status: $($dist.Status)" -ForegroundColor Cyan
                Write-Host "Custom Domains: $($dist.Aliases.Items -join ', ')" -ForegroundColor Cyan
            }
        }
    }
    
    if (-not $usingDistribution) {
        Write-Host "No CloudFront distribution is currently using this certificate." -ForegroundColor Yellow
        Write-Host "Run the setup-cloudfront.ps1 script to create your CloudFront distribution." -ForegroundColor Yellow
    }
    
} else {
    Write-Host "`nCertificate is in status: $validationStatus" -ForegroundColor Yellow
    Write-Host "Please check the AWS ACM console for more details." -ForegroundColor Yellow
}

Write-Host "`nTo view details in AWS Console:" -ForegroundColor White
Write-Host "https://console.aws.amazon.com/acm/home?region=us-east-1#/certificates/details/$($certificateArn.Split('/')[1])" -ForegroundColor Cyan
