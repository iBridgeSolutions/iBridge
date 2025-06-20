# SSL Certificate Helper Script for AWS Deployment

function Check-AwsCliInstalled {
    try {
        $awsVersion = aws --version
        Write-Host "AWS CLI is already installed: $awsVersion" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "AWS CLI is not installed. Please install it using the deploy-to-aws.ps1 script first." -ForegroundColor Red
        return $false
    }
}

function Request-Certificate {
    param(
        [string]$Domain = "ibridgesolutions.co.za"
    )
    
    Write-Host "`nRequesting SSL certificate for $Domain and www.$Domain..." -ForegroundColor Yellow
    
    # Execute AWS CLI command to request certificate
    try {
        # Force using us-east-1 region because CloudFront requires certificates from this region
        $result = aws acm request-certificate --domain-name $Domain --validation-method DNS --region us-east-1 --subject-alternative-names "www.$Domain" --output json
        
        $certificateArn = ($result | ConvertFrom-Json).CertificateArn
        
        if ($certificateArn) {
            Write-Host "  ✓ Certificate requested successfully!" -ForegroundColor Green
            Write-Host "  Certificate ARN: $certificateArn" -ForegroundColor Cyan
            
            # Save the ARN to a file for later use
            $certificateArn | Out-File -FilePath "certificate-arn.txt" -Encoding utf8
            Write-Host "  Certificate ARN saved to certificate-arn.txt" -ForegroundColor Green
            
            return $certificateArn
        }
        else {
            Write-Host "  ✗ Failed to request certificate (no ARN returned)" -ForegroundColor Red
            return $null
        }
    }
    catch {
        Write-Host "  ✗ Error requesting certificate: $_" -ForegroundColor Red
        return $null
    }
}

function Get-ValidationDetails {
    param(
        [string]$CertificateArn
    )
    
    Write-Host "`nGetting validation details for the certificate..." -ForegroundColor Yellow
    
    try {
        # Force using us-east-1 region because CloudFront requires certificates from this region
        $result = aws acm describe-certificate --certificate-arn $CertificateArn --region us-east-1 --output json
        $certificateDetails = $result | ConvertFrom-Json
        
        $validationOptions = $certificateDetails.Certificate.DomainValidationOptions
        
        if ($validationOptions) {
            Write-Host "  ✓ Certificate validation details retrieved!" -ForegroundColor Green
            
            Write-Host "`nDNS validation records to create:" -ForegroundColor Cyan
            foreach ($validation in $validationOptions) {
                if ($validation.ValidationMethod -eq "DNS") {
                    $domain = $validation.DomainName
                    $recordName = $validation.ResourceRecord.Name
                    $recordValue = $validation.ResourceRecord.Value
                    $recordType = $validation.ResourceRecord.Type
                    
                    Write-Host "`n  Domain: $domain" -ForegroundColor White
                    Write-Host "  DNS Record Name: $recordName" -ForegroundColor White
                    Write-Host "  DNS Record Type: $recordType" -ForegroundColor White
                    Write-Host "  DNS Record Value: $recordValue" -ForegroundColor White
                    
                    # Save the validation records to a file
                    $validationInfo = @{
                        Domain = $domain
                        RecordName = $recordName
                        RecordType = $recordType
                        RecordValue = $recordValue
                    }
                    
                    $validationInfo | ConvertTo-Json | Out-File -FilePath "validation-$domain.json" -Encoding utf8
                }
            }
            
            Write-Host "`nValidation records saved to JSON files." -ForegroundColor Green
            return $validationOptions
        }
        else {
            Write-Host "  ✗ No validation options found" -ForegroundColor Red
            return $null
        }
    }
    catch {
        Write-Host "  ✗ Error getting validation details: $_" -ForegroundColor Red
        return $null
    }
}

function Create-Route53ValidationRecords {
    param(
        [string]$CertificateArn,
        [string]$HostedZoneId
    )
    
    Write-Host "`nCreating Route 53 validation records..." -ForegroundColor Yellow
    
    if ([string]::IsNullOrWhiteSpace($HostedZoneId)) {
        Write-Host "  ✗ No Route 53 Hosted Zone ID provided" -ForegroundColor Red
        return $false
    }
    
    try {
        # Force using us-east-1 region for the certificate
        $result = aws acm describe-certificate --certificate-arn $CertificateArn --region us-east-1 --output json
        $certificateDetails = $result | ConvertFrom-Json
        $validationOptions = $certificateDetails.Certificate.DomainValidationOptions
        
        if (-not $validationOptions) {
            Write-Host "  ✗ No validation options found in certificate details" -ForegroundColor Red
            return $false
        }
        
        # Create validation records in Route 53
        foreach ($validation in $validationOptions) {
            if ($validation.ValidationMethod -eq "DNS") {
                $domain = $validation.DomainName
                $recordName = $validation.ResourceRecord.Name
                $recordValue = $validation.ResourceRecord.Value
                $recordType = $validation.ResourceRecord.Type
                
                # Create the JSON change batch file
                $changeJson = @"
{
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "$recordName",
                "Type": "$recordType",
                "TTL": 300,
                "ResourceRecords": [
                    {
                        "Value": "$recordValue"
                    }
                ]
            }
        }
    ]
}
"@
                
                $changeBatchFile = "change-batch-$($domain.Replace(".", "-")).json"
                $changeJson | Out-File -FilePath $changeBatchFile -Encoding utf8
                
                Write-Host "  Adding validation record for $domain..." -ForegroundColor Cyan
                
                $changeResult = aws route53 change-resource-record-sets --hosted-zone-id $HostedZoneId --change-batch file://$changeBatchFile
                
                if ($changeResult) {
                    Write-Host "  ✓ Validation record added for $domain" -ForegroundColor Green
                }
                else {
                    Write-Host "  ✗ Failed to add validation record for $domain" -ForegroundColor Red
                }
                
                # Clean up
                Remove-Item -Path $changeBatchFile -ErrorAction SilentlyContinue
            }
        }
        
        return $true
    }
    catch {
        Write-Host "  ✗ Error creating validation records: $_" -ForegroundColor Red
        return $false
    }
}

function Check-CertificateStatus {
    param(
        [string]$CertificateArn
    )
    
    Write-Host "`nChecking certificate validation status..." -ForegroundColor Yellow
    
    try {
        # Force using us-east-1 region for the certificate
        $result = aws acm describe-certificate --certificate-arn $CertificateArn --region us-east-1 --output json
        $certificateDetails = $result | ConvertFrom-Json
        
        $status = $certificateDetails.Certificate.Status
        
        Write-Host "  Certificate status: $status" -ForegroundColor Cyan
        
        if ($status -eq "ISSUED") {
            Write-Host "  ✓ Certificate has been validated and issued successfully!" -ForegroundColor Green
            return $true
        }
        elseif ($status -eq "PENDING_VALIDATION") {
            $validationOptions = $certificateDetails.Certificate.DomainValidationOptions
            
            Write-Host "  Certificate is pending validation." -ForegroundColor Yellow
            Write-Host "  This can take up to 30 minutes to complete once DNS records are properly set up." -ForegroundColor Yellow
            
            foreach ($validation in $validationOptions) {
                $domain = $validation.DomainName
                $validationStatus = $validation.ValidationStatus
                
                Write-Host "  - $domain: $validationStatus" -ForegroundColor Yellow
            }
            
            return $false
        }
        else {
            Write-Host "  ✗ Certificate is in status: $status" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "  ✗ Error checking certificate status: $_" -ForegroundColor Red
        return $false
    }
}

function Show-Instructions {
    param(
        [string]$CertificateArn
    )
    
    Write-Host "`n===========================================================" -ForegroundColor Cyan
    Write-Host "                SSL Certificate Instructions               " -ForegroundColor Cyan
    Write-Host "===========================================================" -ForegroundColor Cyan
    
    Write-Host "`nImportant information about your SSL certificate:" -ForegroundColor Yellow
    
    Write-Host "`n1. Certificate ARN: $CertificateArn" -ForegroundColor White
    Write-Host "   This identifier is used to reference your certificate in AWS." -ForegroundColor White
    
    Write-Host "`n2. Certificate Region: us-east-1" -ForegroundColor White
    Write-Host "   AWS requires certificates used with CloudFront to be in the us-east-1 region." -ForegroundColor White
    
    Write-Host "`n3. Next Steps:" -ForegroundColor White
    Write-Host "   a. Wait for the certificate to be validated (check with this script)" -ForegroundColor White
    Write-Host "   b. Configure CloudFront to use this certificate" -ForegroundColor White
    Write-Host "   c. Update your Route 53 records to point to CloudFront" -ForegroundColor White
    Write-Host "   d. Update GoDaddy to use Route 53 nameservers" -ForegroundColor White
    
    Write-Host "`n4. Common Issues:" -ForegroundColor White
    Write-Host "   - Validation can take up to 30 minutes after DNS records are created" -ForegroundColor White
    Write-Host "   - CloudFront distributions take 15-30 minutes to deploy" -ForegroundColor White
    Write-Host "   - DNS changes can take 24-48 hours to fully propagate" -ForegroundColor White
    
    Write-Host "`nFor detailed steps, refer to aws-free-hosting-plan.md" -ForegroundColor Cyan
}

function Find-ExistingCertificates {
    param(
        [string]$Domain = "ibridgesolutions.co.za"
    )
    
    Write-Host "`nChecking for existing certificates for $Domain..." -ForegroundColor Yellow
    
    try {
        $result = aws acm list-certificates --region us-east-1 --output json
        $certificates = ($result | ConvertFrom-Json).CertificateSummaryList
        
        $matchingCerts = $certificates | Where-Object { $_.DomainName -eq $Domain -or $_.DomainName -like "*$Domain" }
        
        if ($matchingCerts.Count -gt 0) {
            Write-Host "  Found existing certificate(s):" -ForegroundColor Green
            
            foreach ($cert in $matchingCerts) {
                Write-Host "  - Domain: $($cert.DomainName)" -ForegroundColor White
                Write-Host "    Status: $($cert.Status)" -ForegroundColor White
                Write-Host "    ARN: $($cert.CertificateArn)" -ForegroundColor Cyan
                Write-Host
            }
            
            return $matchingCerts[0].CertificateArn
        }
        else {
            Write-Host "  No existing certificates found for $Domain" -ForegroundColor Yellow
            return $null
        }
    }
    catch {
        Write-Host "  ✗ Error checking for existing certificates: $_" -ForegroundColor Red
        return $null
    }
}

function Get-Route53HostedZones {
    Write-Host "`nFetching Route 53 hosted zones..." -ForegroundColor Yellow
    
    try {
        $result = aws route53 list-hosted-zones --output json
        $hostedZones = ($result | ConvertFrom-Json).HostedZones
        
        if ($hostedZones.Count -gt 0) {
            Write-Host "  Found hosted zones:" -ForegroundColor Green
            
            foreach ($zone in $hostedZones) {
                $zoneName = $zone.Name -replace "\.$", ""
                $zoneId = $zone.Id -replace "/hostedzone/", ""
                
                Write-Host "  - Zone: $zoneName" -ForegroundColor White
                Write-Host "    ID: $zoneId" -ForegroundColor Cyan
                Write-Host
            }
            
            return $hostedZones
        }
        else {
            Write-Host "  No hosted zones found." -ForegroundColor Yellow
            Write-Host "  You need to create a hosted zone in Route 53 first." -ForegroundColor Yellow
            return $null
        }
    }
    catch {
        Write-Host "  ✗ Error fetching hosted zones: $_" -ForegroundColor Red
        return $null
    }
}

# Main script
Clear-Host
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "     SSL Certificate Helper for AWS Deployment             " -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan

# Check prerequisites
if (-not (Check-AwsCliInstalled)) {
    Write-Host "`nPlease install and configure AWS CLI first." -ForegroundColor Red
    exit
}

# Get domain name
$domain = "ibridgesolutions.co.za"
$customDomain = Read-Host "Enter your domain (default: $domain)"
if (-not [string]::IsNullOrWhiteSpace($customDomain)) {
    $domain = $customDomain
}

# Check for existing certificates
$existingCertArn = Find-ExistingCertificates -Domain $domain

# Get or request certificate
$certificateArn = $null
if ($existingCertArn) {
    $useExisting = Read-Host "Use existing certificate? (y/n)"
    if ($useExisting.ToLower() -eq "y") {
        $certificateArn = $existingCertArn
    }
}

if (-not $certificateArn) {
    $certificateArn = Request-Certificate -Domain $domain
}

if (-not $certificateArn) {
    Write-Host "`nFailed to get a certificate ARN. Exiting." -ForegroundColor Red
    exit
}

# Get validation details
$validationOptions = Get-ValidationDetails -CertificateArn $certificateArn

# Check for Route 53 hosted zones
$hostedZones = Get-Route53HostedZones

if ($hostedZones) {
    $useRoute53 = Read-Host "`nDo you want to create validation records in Route 53? (y/n)"
    
    if ($useRoute53.ToLower() -eq "y") {
        # If there's more than one hosted zone, ask which one to use
        $zoneId = $null
        if ($hostedZones.Count -gt 1) {
            Write-Host "`nMultiple hosted zones found. Enter the ID of the zone to use:" -ForegroundColor Yellow
            $zoneId = Read-Host "Zone ID"
        }
        else {
            $zoneId = $hostedZones[0].Id -replace "/hostedzone/", ""
        }
        
        if (-not [string]::IsNullOrWhiteSpace($zoneId)) {
            Create-Route53ValidationRecords -CertificateArn $certificateArn -HostedZoneId $zoneId
        }
    }
}

# Check certificate status
Check-CertificateStatus -CertificateArn $certificateArn

# Show instructions
Show-Instructions -CertificateArn $certificateArn

Write-Host "`nPress any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
