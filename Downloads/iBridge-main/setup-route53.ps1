# Route 53 DNS Migration Script
# This script creates a Route 53 hosted zone for ibridgesolutions.co.za
# and sets up proper records pointing to CloudFront

# Configuration
$accountId = "640825887118"
$domainName = "ibridgesolutions.co.za"
$wwwDomainName = "www.ibridgesolutions.co.za"
$region = "us-east-1"
$awsExePath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"

# Header
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  ROUTE 53 DNS SETUP FOR IBRIDGESOLUTIONS.CO.ZA" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "Account ID: 6408-2588-7118" -ForegroundColor Yellow
Write-Host "Domain: $domainName" -ForegroundColor Yellow
Write-Host

# Step 1: Get CloudFront distribution information
Write-Host "Reading CloudFront distribution information..." -ForegroundColor Yellow
$cloudFrontInfo = Get-Content -Path "cloudfront-info.txt" -Raw -ErrorAction SilentlyContinue

if (-not $cloudFrontInfo) {
    Write-Host "Error: cloudfront-info.txt not found. Please run setup-cloudfront.ps1 first." -ForegroundColor Red
    exit
}

# Extract CloudFront domain
$cloudFrontDomain = $null
foreach ($line in $cloudFrontInfo -split "`n") {
    if ($line -match "Distribution Domain:\s*(.+)") {
        $cloudFrontDomain = $matches[1].Trim()
        break
    }
}
if (-not $cloudFrontDomain) {
    Write-Host "Error: Could not extract CloudFront domain from cloudfront-info.txt" -ForegroundColor Red
    exit
}
Write-Host "CloudFront Domain: $cloudFrontDomain" -ForegroundColor Green

# Step 2: Create Route 53 hosted zone
Write-Host "`nCreating Route 53 hosted zone for $domainName..." -ForegroundColor Yellow
try {
    # Create hosted zone
    $hostedZoneJson = @"
{
  "Name": "$domainName",
  "CallerReference": "ibridgesolutions-$(Get-Date -Format 'yyyyMMddHHmmss')",
  "HostedZoneConfig": {
    "Comment": "Hosted zone for ibridgesolutions.co.za",
    "PrivateZone": false
  }
}
"@
    
    $hostedZoneJson | Out-File -FilePath "hosted-zone-config.json" -Encoding ascii
    Start-Process -FilePath $awsExePath -ArgumentList "route53 create-hosted-zone --name $domainName --caller-reference ibridgesolutions-$(Get-Date -Format 'yyyyMMddHHmmss') --hosted-zone-config Comment=`"Hosted zone for ibridgesolutions.co.za`",PrivateZone=false --region $region" -NoNewWindow -Wait -RedirectStandardOutput "route53-output.txt" -PassThru
    
    if (Test-Path "route53-output.txt") {
        $route53Output = Get-Content -Path "route53-output.txt" -Raw
        
        # Extract Hosted Zone ID
        $hostedZoneId = if ($route53Output -match '"Id":\s*"(.+?)"') {
            $matches[1].Replace("/hostedzone/", "").Trim()
        } else {
            Write-Host "Error: Could not extract Hosted Zone ID from output" -ForegroundColor Red
            exit
        }
        
        Write-Host "Route 53 Hosted Zone created successfully!" -ForegroundColor Green
        Write-Host "Hosted Zone ID: $hostedZoneId" -ForegroundColor Cyan
        
        # Extract nameservers
        $nameservers = @()
        if ($route53Output -match '"NameServers":\s*\[(.*?)\]') {
            $nameserversJson = $matches[1]
            $nameserversJson -split "," | ForEach-Object {
                if ($_ -match '"(.+?)"') {
                    $nameservers += $matches[1].Trim()
                }
            }
        }
        
        Write-Host "`nAWS Nameservers for $($domainName):" -ForegroundColor Yellow
        foreach ($ns in $nameservers) {
            Write-Host "  $($ns)" -ForegroundColor White
        }
        
        # Save nameservers to file
        @"
Route 53 DNS Configuration for ibridgesolutions.co.za
====================================================
Hosted Zone ID: $hostedZoneId

Nameservers:
$($nameservers -join "`n")

CloudFront Domain: $cloudFrontDomain
"@ | Out-File -FilePath "route53-info.txt" -Encoding ascii
        
        # Step 3: Create DNS records pointing to CloudFront
        Write-Host "`nCreating DNS records pointing to CloudFront..." -ForegroundColor Yellow
        
        # Create record change batch
        $recordChangeJson = @"
{
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "$domainName",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "$cloudFrontDomain",
          "EvaluateTargetHealth": false
        }
      }
    },
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "$wwwDomainName",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "$cloudFrontDomain",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
"@
        
        $recordChangeJson | Out-File -FilePath "route53-records.json" -Encoding ascii
        Start-Process -FilePath $awsExePath -ArgumentList "route53 change-resource-record-sets --hosted-zone-id $hostedZoneId --change-batch file://route53-records.json --region $region" -NoNewWindow -Wait -RedirectStandardOutput "route53-records-output.txt" -PassThru
        
        Write-Host "DNS records created successfully!" -ForegroundColor Green
        Write-Host "`nRoute 53 configuration complete!" -ForegroundColor Green
        Write-Host
        
        Write-Host "======================================================" -ForegroundColor Cyan
        Write-Host "  GODADDY NAMESERVER UPDATE INSTRUCTIONS" -ForegroundColor Cyan
        Write-Host "======================================================" -ForegroundColor Cyan
        Write-Host
        Write-Host "To complete the migration, update your domain's nameservers in GoDaddy:" -ForegroundColor Yellow
        Write-Host
        Write-Host "1. Log in to GoDaddy" -ForegroundColor White
        Write-Host "2. Go to your domain (ibridgesolutions.co.za)" -ForegroundColor White
        Write-Host "3. Look for 'Nameservers' or 'DNS' settings" -ForegroundColor White
        Write-Host "4. Choose 'Custom' or 'I'll use my own nameservers'" -ForegroundColor White
        Write-Host "5. Enter these AWS nameservers:" -ForegroundColor White
        foreach ($ns in $nameservers) {
            Write-Host "   $ns" -ForegroundColor Cyan
        }
        Write-Host "6. Save changes" -ForegroundColor White
        Write-Host
        Write-Host "Important: DNS changes may take 24-48 hours to fully propagate" -ForegroundColor Yellow
        Write-Host "You can check the status by running check-dns-propagation.ps1" -ForegroundColor Yellow
    } else {
        Write-Host "Error: Route 53 output not found" -ForegroundColor Red
    }
} catch {
    Write-Host "Error creating Route 53 hosted zone: $_" -ForegroundColor Red
}
