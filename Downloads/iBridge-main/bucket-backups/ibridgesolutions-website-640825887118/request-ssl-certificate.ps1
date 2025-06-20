# Request SSL Certificate Script for iBridge Solutions
# This script requests an SSL certificate from AWS Certificate Manager

# Configuration
$accountId = "640825887118"
$region = "us-east-1"
$domainName = "ibridgesolutions.co.za"
$wwwDomainName = "www.ibridgesolutions.co.za"
$awsCmd = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"

# Header
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "      SSL CERTIFICATE REQUEST FOR IBRIDGESOLUTIONS" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Account ID: 6408-2588-7118" -ForegroundColor Yellow
Write-Host "Domain: $domainName" -ForegroundColor Yellow
Write-Host

# Check AWS CLI access
try {
    Write-Host "Checking AWS access..." -ForegroundColor Yellow
    $identity = & $awsCmd sts get-caller-identity 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: AWS CLI not configured properly." -ForegroundColor Red
        Write-Host "Please run 'aws configure' first to set up your credentials." -ForegroundColor Yellow
        exit
    }
    Write-Host "✓ AWS access confirmed" -ForegroundColor Green
} catch {
    Write-Host "Error checking AWS access: $_" -ForegroundColor Red
    exit
}

# Request SSL certificate
Write-Host "`nRequesting SSL certificate for $domainName and $wwwDomainName..." -ForegroundColor Yellow
try {
    $certificateOutput = & $awsCmd acm request-certificate --domain-name $domainName --validation-method DNS --subject-alternative-names $wwwDomainName --region $region
    
    if ($LASTEXITCODE -eq 0) {
        $certificateArn = ($certificateOutput | ConvertFrom-Json).CertificateArn
        Write-Host "✓ Certificate requested successfully!" -ForegroundColor Green
        Write-Host "Certificate ARN: $certificateArn" -ForegroundColor Green
        
        # Save certificate ARN to file for easy reference
        $certificateArn | Out-File -FilePath "certificate-arn.txt" -Encoding ascii
        Write-Host "Certificate ARN has been saved to certificate-arn.txt" -ForegroundColor Cyan
        
        # Wait a moment before checking validation details
        Write-Host "`nRetrieving validation details..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        
        # Get certificate validation information
        $certDetails = & $awsCmd acm describe-certificate --certificate-arn $certificateArn --region $region | ConvertFrom-Json
        
        # Display DNS validation records that need to be added
        Write-Host "`nYou need to add these DNS records to your GoDaddy domain:" -ForegroundColor Yellow
        
        if ($certDetails.Certificate.DomainValidationOptions) {
            foreach ($validation in $certDetails.Certificate.DomainValidationOptions) {
                if ($validation.ResourceRecord) {
                    $recordName = $validation.ResourceRecord.Name
                    $recordValue = $validation.ResourceRecord.Value
                    $recordType = $validation.ResourceRecord.Type
                    
                    # Simplify the CNAME record name for easier input at GoDaddy
                    $simplifiedName = $recordName -replace "\.$domainName\.$", ""
                    
                    Write-Host "`nFor domain: $($validation.DomainName)" -ForegroundColor White
                    Write-Host "Record type: $recordType" -ForegroundColor Green
                    Write-Host "Simplified host: $simplifiedName" -ForegroundColor Green
                    Write-Host "Points to: $recordValue" -ForegroundColor Green
                    Write-Host "TTL: 1 Hour" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "No validation records found yet. Please wait a moment and run the check-certificate-validation.ps1 script." -ForegroundColor Yellow
        }
        
        Write-Host "`n==================================================" -ForegroundColor Cyan
        Write-Host "                  NEXT STEPS                      " -ForegroundColor Cyan
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host "1. Add the DNS records shown above to your GoDaddy domain" -ForegroundColor Yellow
        Write-Host "2. Wait approximately 30 minutes for validation" -ForegroundColor Yellow
        Write-Host "3. Check validation status with:" -ForegroundColor Yellow
        Write-Host "   powershell -ExecutionPolicy Bypass -File .\check-certificate-validation.ps1" -ForegroundColor White
        Write-Host "4. After validation completes, run:" -ForegroundColor Yellow
        Write-Host "   powershell -ExecutionPolicy Bypass -File .\setup-cloudfront.ps1" -ForegroundColor White
    } else {
        Write-Host "✗ Failed to request SSL certificate" -ForegroundColor Red
        Write-Host $certificateOutput -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Error requesting certificate: $_" -ForegroundColor Red
}
