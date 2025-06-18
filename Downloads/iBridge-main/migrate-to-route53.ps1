# GoDaddy to AWS Route 53 DNS Migration Script
# This script helps migrate DNS management from GoDaddy to AWS Route 53

# Configuration - use your AWS account ID
$accountId = "640825887118" # Formatted without hyphens
$region = "us-east-1" 
$domainName = "ibridgesolutions.co.za"

function Show-Header {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "      MIGRATE DNS FROM GODADDY TO AWS ROUTE 53           " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "Account ID: 6408-2588-7118" -ForegroundColor Yellow
    Write-Host "Domain: $domainName" -ForegroundColor Yellow
    Write-Host
    Write-Host "This script will help you migrate DNS management from GoDaddy to AWS Route 53."
    Write-Host "Route 53 costs $0.50/month for the hosted zone but provides better control."
    Write-Host "This is recommended for using CloudFront with apex domains (without www)."
    Write-Host
}

function Check-AwsCli {
    Write-Host "Checking AWS CLI installation..." -ForegroundColor Yellow
    
    try {
        $awsVersion = aws --version
        Write-Host "✓ AWS CLI is installed: $awsVersion" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "✗ AWS CLI is not installed." -ForegroundColor Red
        Write-Host "Please install AWS CLI first:" -ForegroundColor Yellow
        Write-Host "1. Download from: https://aws.amazon.com/cli/" -ForegroundColor White
        Write-Host "2. Run the installer" -ForegroundColor White
        Write-Host "3. Run 'aws configure' to set up your AWS credentials" -ForegroundColor White
        return $false
    }
}

function Create-Route53HostedZone {
    Write-Host "`nCreating Route 53 hosted zone for $domainName..." -ForegroundColor Yellow
    
    # Check if hosted zone already exists
    $existingZones = aws route53 list-hosted-zones | ConvertFrom-Json
    $zoneExists = $false
    $zoneId = $null
    
    foreach ($zone in $existingZones.HostedZones) {
        if ($zone.Name -eq "$domainName.") {
            $zoneExists = $true
            $zoneId = $zone.Id.Split("/")[2]  # Extract ID from format "/hostedzone/Z1234567890"
            Write-Host "✓ Hosted zone already exists for $domainName" -ForegroundColor Green
            Write-Host "  Zone ID: $zoneId" -ForegroundColor Cyan
            break
        }
    }
    
    if (-not $zoneExists) {
        # Create new hosted zone
        Write-Host "Creating new hosted zone for $domainName..." -ForegroundColor Yellow
        
        $callerRef = Get-Date -Format "yyyyMMddHHmmss"
        $newZone = aws route53 create-hosted-zone --name $domainName --caller-reference $callerRef | ConvertFrom-Json
        
        $zoneId = $newZone.HostedZone.Id.Split("/")[2]
        Write-Host "✓ Created new hosted zone for $domainName" -ForegroundColor Green
        Write-Host "  Zone ID: $zoneId" -ForegroundColor Cyan
    }
    
    return $zoneId
}

function Get-Route53Nameservers {
    param (
        [string]$zoneId
    )
    
    Write-Host "`nRetrieving Route 53 nameservers..." -ForegroundColor Yellow
    
    $zoneDetails = aws route53 get-hosted-zone --id $zoneId | ConvertFrom-Json
    $nameservers = $zoneDetails.DelegationSet.NameServers
    
    Write-Host "✓ Retrieved nameservers for $domainName" -ForegroundColor Green
    Write-Host "  Use these nameservers in GoDaddy:" -ForegroundColor Cyan
    
    foreach ($ns in $nameservers) {
        Write-Host "  - $ns" -ForegroundColor White
    }
    
    return $nameservers
}

function Find-CloudFrontDistribution {
    Write-Host "`nLooking for CloudFront distribution for $domainName..." -ForegroundColor Yellow
    
    $distributions = aws cloudfront list-distributions | ConvertFrom-Json
    $distribution = $null
    
    if ($distributions.DistributionList.Items) {
        foreach ($dist in $distributions.DistributionList.Items) {
            if ($dist.Aliases.Items -contains $domainName) {
                $distribution = $dist
                Write-Host "✓ Found CloudFront distribution for $domainName" -ForegroundColor Green
                Write-Host "  Distribution ID: $($distribution.Id)" -ForegroundColor Cyan
                Write-Host "  Distribution Domain: $($distribution.DomainName)" -ForegroundColor Cyan
                break
            }
        }
    }
    
    if (-not $distribution) {
        Write-Host "✗ No CloudFront distribution found for $domainName" -ForegroundColor Red
        Write-Host "  Run the deployment script first to create a CloudFront distribution." -ForegroundColor Yellow
    }
    
    return $distribution
}

function Create-Route53Records {
    param (
        [string]$zoneId,
        [object]$distribution
    )
    
    if (-not $distribution) {
        Write-Host "`nCannot create DNS records without CloudFront distribution." -ForegroundColor Red
        return
    }
    
    $distributionDomain = $distribution.DomainName
    
    Write-Host "`nCreating Route 53 DNS records to point to CloudFront..." -ForegroundColor Yellow
    
    # Create A record alias for apex domain
    Write-Host "Creating A record alias for apex domain ($domainName)..." -ForegroundColor Yellow
    
    $apexRecordJson = @"
{
    "Changes": [
        {
            "Action": "CREATE",
            "ResourceRecordSet": {
                "Name": "$domainName",
                "Type": "A",
                "AliasTarget": {
                    "HostedZoneId": "Z2FDTNDATAQYW2",
                    "DNSName": "$distributionDomain",
                    "EvaluateTargetHealth": false
                }
            }
        }
    ]
}
"@
    $apexRecordJson | Out-File -FilePath "apex-record.json" -Encoding utf8
    
    try {
        aws route53 change-resource-record-sets --hosted-zone-id $zoneId --change-batch file://apex-record.json
        Write-Host "✓ Created A record alias for apex domain" -ForegroundColor Green
    } catch {
        Write-Host "! Error creating A record: $_" -ForegroundColor Yellow
        Write-Host "  The record might already exist or there was an error." -ForegroundColor Yellow
    }
    
    Remove-Item "apex-record.json" -ErrorAction SilentlyContinue
    
    # Create CNAME record for www subdomain
    Write-Host "Creating CNAME record for www subdomain..." -ForegroundColor Yellow
    
    $wwwRecordJson = @"
{
    "Changes": [
        {
            "Action": "CREATE",
            "ResourceRecordSet": {
                "Name": "www.$domainName",
                "Type": "CNAME",
                "TTL": 300,
                "ResourceRecords": [
                    {
                        "Value": "$distributionDomain"
                    }
                ]
            }
        }
    ]
}
"@
    $wwwRecordJson | Out-File -FilePath "www-record.json" -Encoding utf8
    
    try {
        aws route53 change-resource-record-sets --hosted-zone-id $zoneId --change-batch file://www-record.json
        Write-Host "✓ Created CNAME record for www subdomain" -ForegroundColor Green
    } catch {
        Write-Host "! Error creating CNAME record: $_" -ForegroundColor Yellow
        Write-Host "  The record might already exist or there was an error." -ForegroundColor Yellow
    }
    
    Remove-Item "www-record.json" -ErrorAction SilentlyContinue
}

function Show-GoDaddyInstructions {
    param (
        [array]$nameservers
    )
    
    Write-Host "`n==========================================================" -ForegroundColor Cyan
    Write-Host "              GODADDY NAMESERVER UPDATE INSTRUCTIONS        " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    Write-Host "`nTo complete the DNS migration, update nameservers in GoDaddy:" -ForegroundColor Yellow
    
    Write-Host "`n1. Log in to your GoDaddy account" -ForegroundColor White
    Write-Host "2. Navigate to Domain Manager and select $domainName" -ForegroundColor White
    Write-Host "3. Click 'Manage DNS'" -ForegroundColor White
    Write-Host "4. Scroll down to 'Nameservers' section" -ForegroundColor White
    Write-Host "5. Select 'Change' or 'Custom' nameservers" -ForegroundColor White
    Write-Host "6. Remove any existing nameservers" -ForegroundColor White
    Write-Host "7. Add these four AWS nameservers:" -ForegroundColor White
    
    foreach ($ns in $nameservers) {
        Write-Host "   - $ns" -ForegroundColor Green
    }
    
    Write-Host "`n8. Save changes" -ForegroundColor White
    
    Write-Host "`nIMPORTANT: DNS propagation can take 24-48 hours." -ForegroundColor Yellow
    Write-Host "During this time, some users might see the old DNS and others the new DNS." -ForegroundColor Yellow
}

function Show-Footer {
    Write-Host "`n==========================================================" -ForegroundColor Cyan
    Write-Host "                    MIGRATION COMPLETE                     " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    Write-Host "`nAfter updating GoDaddy nameservers:" -ForegroundColor Yellow
    Write-Host "1. Wait 24-48 hours for DNS propagation" -ForegroundColor White
    Write-Host "2. Run .\check-aws-deployment.ps1 to verify everything is working" -ForegroundColor White
    
    Write-Host "`nBenefits of using Route 53:" -ForegroundColor Yellow
    Write-Host "- Apex domain support with CloudFront" -ForegroundColor White
    Write-Host "- Lower DNS lookup latency globally" -ForegroundColor White
    Write-Host "- Advanced routing policies if needed" -ForegroundColor White
    Write-Host "- AWS health checks and failover capability" -ForegroundColor White
    
    Write-Host "`nNote: Route 53 costs $0.50/month for the hosted zone." -ForegroundColor Cyan
}

# Main execution
Show-Header
if (Check-AwsCli) {
    $zoneId = Create-Route53HostedZone
    $nameservers = Get-Route53Nameservers -zoneId $zoneId
    $distribution = Find-CloudFrontDistribution
    
    if ($distribution) {
        Create-Route53Records -zoneId $zoneId -distribution $distribution
    }
    
    Show-GoDaddyInstructions -nameservers $nameservers
    Show-Footer
}
