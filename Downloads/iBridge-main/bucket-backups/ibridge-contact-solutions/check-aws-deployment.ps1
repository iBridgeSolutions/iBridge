# AWS Deployment Status Checker
# This script checks the status of your AWS S3, CloudFront and DNS configuration

# Configuration - use your AWS account ID
$accountId = "640825887118" # Formatted without hyphens
$s3BucketName = "ibridgesolutions-website-$accountId"
$region = "us-east-1"
$domainName = "ibridgesolutions.co.za"
$wwwDomainName = "www.ibridgesolutions.co.za"

function Show-Header {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "       AWS DEPLOYMENT STATUS FOR IBRIDGESOLUTIONS.CO.ZA    " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "Account ID: 6408-2588-7118" -ForegroundColor Yellow
    Write-Host
}

function Check-S3Status {
    Write-Host "Checking S3 bucket status..." -ForegroundColor Yellow
    
    try {
        # Check if bucket exists
        $bucketExists = aws s3api head-bucket --bucket $s3BucketName 2>&1
        if (-not $?) {
            Write-Host "S3 bucket $s3BucketName does not exist." -ForegroundColor Red
            Write-Host "Please run the deployment script first." -ForegroundColor Yellow
            return $false
        }
        
        Write-Host "✓ S3 bucket $s3BucketName exists" -ForegroundColor Green
        
        # Check if bucket is configured for website hosting
        $websiteConfig = aws s3api get-bucket-website --bucket $s3BucketName 2>&1
        if ($?) {
            $indexDocument = $websiteConfig | ConvertFrom-Json | Select-Object -ExpandProperty IndexDocument | Select-Object -ExpandProperty Suffix
            Write-Host "✓ S3 bucket is configured for website hosting with index document: $indexDocument" -ForegroundColor Green
            $s3WebsiteUrl = "http://$s3BucketName.s3-website-$region.amazonaws.com"
            Write-Host "  S3 Website URL: $s3WebsiteUrl" -ForegroundColor Cyan
        } else {
            Write-Host "✗ S3 bucket is not configured for website hosting" -ForegroundColor Red
            Write-Host "  Run the deployment script to configure website hosting." -ForegroundColor Yellow
        }
        
        # Check if there are any files in the bucket
        $files = aws s3 ls s3://$s3BucketName --recursive | Measure-Object | Select-Object -ExpandProperty Count
        if ($files -gt 0) {
            Write-Host "✓ S3 bucket contains $files files" -ForegroundColor Green
        } else {
            Write-Host "✗ S3 bucket is empty" -ForegroundColor Red
            Write-Host "  Run the deployment script to upload website files." -ForegroundColor Yellow
        }
        
        return $true
    } catch {
        Write-Host "Error checking S3 status: $_" -ForegroundColor Red
        return $false
    }
}

function Check-CertificateStatus {
    Write-Host "`nChecking SSL certificate status..." -ForegroundColor Yellow
    
    try {
        $certificates = aws acm list-certificates --region $region | ConvertFrom-Json
        $certificateArn = $null
        
        foreach ($cert in $certificates.CertificateSummaryList) {
            if ($cert.DomainName -eq $domainName) {
                $certificateArn = $cert.CertificateArn
                break
            }
        }
        
        if (-not $certificateArn) {
            Write-Host "✗ No SSL certificate found for $domainName" -ForegroundColor Red
            Write-Host "  Run the deployment script to request a certificate." -ForegroundColor Yellow
            return $null
        }
        
        $certDetails = aws acm describe-certificate --certificate-arn $certificateArn --region $region | ConvertFrom-Json
        $validationStatus = $certDetails.Certificate.Status
        
        Write-Host "Certificate Status: $validationStatus" -ForegroundColor (if ($validationStatus -eq "ISSUED") { "Green" } else { "Yellow" })
        
        if ($validationStatus -eq "ISSUED") {
            Write-Host "✓ SSL certificate has been validated and issued" -ForegroundColor Green
            return $certificateArn
        } else {
            Write-Host "✗ SSL certificate is not yet validated" -ForegroundColor Yellow
            Write-Host "  Run 'check-certificate-validation.ps1' for validation instructions." -ForegroundColor Yellow
            return $certificateArn
        }
    } catch {
        Write-Host "Error checking certificate status: $_" -ForegroundColor Red
        return $null
    }
}

function Check-CloudFrontStatus {
    Write-Host "`nChecking CloudFront distribution status..." -ForegroundColor Yellow
    
    try {
        $distributions = aws cloudfront list-distributions | ConvertFrom-Json
        $distribution = $null
        
        if ($distributions.DistributionList.Items) {
            foreach ($dist in $distributions.DistributionList.Items) {
                if ($dist.Aliases.Items -contains $domainName) {
                    $distribution = $dist
                    break
                }
            }
        }
        
        if (-not $distribution) {
            Write-Host "✗ No CloudFront distribution found for $domainName" -ForegroundColor Red
            Write-Host "  Run the deployment script to create a CloudFront distribution." -ForegroundColor Yellow
            return $null
        }
        
        Write-Host "✓ CloudFront distribution found" -ForegroundColor Green
        Write-Host "  ID: $($distribution.Id)" -ForegroundColor Cyan
        Write-Host "  Domain: $($distribution.DomainName)" -ForegroundColor Cyan
        Write-Host "  Status: $($distribution.Status)" -ForegroundColor (if ($distribution.Status -eq "Deployed") { "Green" } else { "Yellow" })
        Write-Host "  Custom Domains: $($distribution.Aliases.Items -join ', ')" -ForegroundColor Cyan
        
        if ($distribution.Status -ne "Deployed") {
            Write-Host "  Distribution is still deploying. This can take 15-30 minutes." -ForegroundColor Yellow
        }
        
        return $distribution
    } catch {
        Write-Host "Error checking CloudFront status: $_" -ForegroundColor Red
        return $null
    }
}

function Check-DnsStatus {
    param (
        $distribution
    )
    
    Write-Host "`nChecking DNS status..." -ForegroundColor Yellow
    
    if (-not $distribution) {
        Write-Host "Cannot check DNS status without CloudFront distribution information." -ForegroundColor Red
        return
    }
    
    $cfDomain = $distribution.DomainName
    
    try {
        # Check apex domain
        Write-Host "Checking DNS for $domainName..." -ForegroundColor Yellow
        $dnsApex = Resolve-DnsName -Name $domainName -Type CNAME -ErrorAction SilentlyContinue
        
        if ($dnsApex) {
            $apexTarget = $dnsApex[0].NameHost
            if ($apexTarget -like "*$cfDomain*") {
                Write-Host "✓ $domainName is correctly pointing to CloudFront ($apexTarget)" -ForegroundColor Green
            } else {
                Write-Host "✗ $domainName is pointing to $apexTarget instead of CloudFront" -ForegroundColor Red
                Write-Host "  Update your DNS settings to point to: $cfDomain" -ForegroundColor Yellow
            }
        } else {
            # Try A record for apex domain
            $dnsApexA = Resolve-DnsName -Name $domainName -Type A -ErrorAction SilentlyContinue
            if ($dnsApexA) {
                Write-Host "! $domainName is using A record(s) instead of CNAME" -ForegroundColor Yellow
                Write-Host "  This might be correct if using Route 53 alias records." -ForegroundColor Yellow
                Write-Host "  Current IP(s): $($dnsApexA | ForEach-Object { $_.IPAddress }) (can't verify if pointing to CloudFront)" -ForegroundColor Yellow
            } else {
                Write-Host "✗ No DNS records found for $domainName" -ForegroundColor Red
                Write-Host "  Update your DNS settings according to the instructions." -ForegroundColor Yellow
            }
        }
        
        # Check www subdomain
        Write-Host "`nChecking DNS for $wwwDomainName..." -ForegroundColor Yellow
        $dnsWww = Resolve-DnsName -Name $wwwDomainName -Type CNAME -ErrorAction SilentlyContinue
        
        if ($dnsWww) {
            $wwwTarget = $dnsWww[0].NameHost
            if ($wwwTarget -like "*$cfDomain*") {
                Write-Host "✓ $wwwDomainName is correctly pointing to CloudFront ($wwwTarget)" -ForegroundColor Green
            } else {
                Write-Host "✗ $wwwDomainName is pointing to $wwwTarget instead of CloudFront" -ForegroundColor Red
                Write-Host "  Update your DNS settings to point to: $cfDomain" -ForegroundColor Yellow
            }
        } else {
            Write-Host "✗ No CNAME record found for $wwwDomainName" -ForegroundColor Red
            Write-Host "  Update your DNS settings according to the instructions." -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "Error checking DNS status: $_" -ForegroundColor Red
    }
}

function Test-Website {
    param (
        $distribution
    )
    
    if (-not $distribution) {
        Write-Host "`nCannot test website without CloudFront distribution information." -ForegroundColor Red
        return
    }
    
    $cfDomain = $distribution.DomainName
    
    Write-Host "`nTesting website access..." -ForegroundColor Yellow
    
    # Test CloudFront URL
    Write-Host "Testing CloudFront URL (https://$cfDomain)..." -ForegroundColor Yellow
    try {
        $cfResponse = Invoke-WebRequest -Uri "https://$cfDomain" -UseBasicParsing
        Write-Host "✓ CloudFront URL is accessible (Status: $($cfResponse.StatusCode))" -ForegroundColor Green
    } catch {
        Write-Host "✗ Cannot access CloudFront URL: $_" -ForegroundColor Red
    }
    
    # Test custom domain
    Write-Host "`nTesting primary domain (https://$domainName)..." -ForegroundColor Yellow
    try {
        $domainResponse = Invoke-WebRequest -Uri "https://$domainName" -UseBasicParsing
        Write-Host "✓ Primary domain is accessible (Status: $($domainResponse.StatusCode))" -ForegroundColor Green
        
        # Check for /lander redirect
        if ($domainResponse.BaseResponse.ResponseUri.AbsolutePath -like "*/lander*") {
            Write-Host "✗ The site is still redirecting to /lander" -ForegroundColor Red
            Write-Host "  Check GoDaddy for any active redirects or website builder settings." -ForegroundColor Yellow
        }
    } catch {
        if ($_.Exception.Response.StatusCode.Value__ -eq 403) {
            Write-Host "! Domain returns 403 Forbidden - CloudFront is working but may not be properly configured" -ForegroundColor Yellow
        } else {
            Write-Host "✗ Cannot access primary domain: $_" -ForegroundColor Red
            Write-Host "  DNS might not be propagated yet or SSL certificate issues" -ForegroundColor Yellow
        }
    }
    
    # Test www subdomain
    Write-Host "`nTesting www subdomain (https://$wwwDomainName)..." -ForegroundColor Yellow
    try {
        $wwwResponse = Invoke-WebRequest -Uri "https://$wwwDomainName" -UseBasicParsing
        Write-Host "✓ WWW subdomain is accessible (Status: $($wwwResponse.StatusCode))" -ForegroundColor Green
        
        # Check for /lander redirect
        if ($wwwResponse.BaseResponse.ResponseUri.AbsolutePath -like "*/lander*") {
            Write-Host "✗ The www site is still redirecting to /lander" -ForegroundColor Red
            Write-Host "  Check GoDaddy for any active redirects or website builder settings." -ForegroundColor Yellow
        }
    } catch {
        if ($_.Exception.Response.StatusCode.Value__ -eq 403) {
            Write-Host "! WWW subdomain returns 403 Forbidden - CloudFront is working but may not be properly configured" -ForegroundColor Yellow
        } else {
            Write-Host "✗ Cannot access WWW subdomain: $_" -ForegroundColor Red
            Write-Host "  DNS might not be propagated yet or SSL certificate issues" -ForegroundColor Yellow
        }
    }
}

function Show-NextSteps {
    param (
        [bool]$s3Status,
        [string]$certificateArn,
        [object]$distribution
    )
    
    Write-Host "`n==========================================================" -ForegroundColor Cyan
    Write-Host "                      NEXT STEPS                          " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    if (-not $s3Status) {
        Write-Host "1. Run the deployment script to create and configure S3 bucket:" -ForegroundColor Yellow
        Write-Host "   .\deploy-with-account-id.ps1" -ForegroundColor White
        return
    }
    
    if (-not $certificateArn) {
        Write-Host "1. Run the deployment script to request an SSL certificate:" -ForegroundColor Yellow
        Write-Host "   .\deploy-with-account-id.ps1" -ForegroundColor White
        return
    } elseif ((aws acm describe-certificate --certificate-arn $certificateArn --region $region | ConvertFrom-Json).Certificate.Status -ne "ISSUED") {
        Write-Host "1. Validate your SSL certificate:" -ForegroundColor Yellow
        Write-Host "   .\check-certificate-validation.ps1" -ForegroundColor White
        return
    }
    
    if (-not $distribution) {
        Write-Host "1. Run the deployment script to create a CloudFront distribution:" -ForegroundColor Yellow
        Write-Host "   .\deploy-with-account-id.ps1" -ForegroundColor White
        return
    } elseif ($distribution.Status -ne "Deployed") {
        Write-Host "1. Wait for CloudFront distribution to finish deploying (15-30 minutes)" -ForegroundColor Yellow
        Write-Host "2. Run this script again to check status:" -ForegroundColor Yellow
        Write-Host "   .\check-aws-deployment.ps1" -ForegroundColor White
        return
    }
    
    # If everything is deployed, focus on DNS
    $dnsApex = Resolve-DnsName -Name $domainName -ErrorAction SilentlyContinue
    $dnsWww = Resolve-DnsName -Name $wwwDomainName -ErrorAction SilentlyContinue
    
    if (-not $dnsApex -or -not $dnsWww) {
        Write-Host "1. Update your DNS settings at GoDaddy:" -ForegroundColor Yellow
        Write-Host "   - For apex domain ($domainName):" -ForegroundColor White
        Write-Host "     Type: CNAME | Host: @ | Points to: $($distribution.DomainName)" -ForegroundColor White
        Write-Host "   - For www subdomain:" -ForegroundColor White
        Write-Host "     Type: CNAME | Host: www | Points to: $($distribution.DomainName)" -ForegroundColor White
        Write-Host "`n   Note: If GoDaddy doesn't allow CNAME for apex domain (@), you have two options:" -ForegroundColor Yellow
        Write-Host "   1. Use GoDaddy's domain forwarding to redirect apex to www" -ForegroundColor White
        Write-Host "   2. Move your DNS management to Route 53 (has small cost)" -ForegroundColor White
        return
    }
    
    # Everything looks good!
    Write-Host "✓ Your deployment looks complete! The website should be accessible at:" -ForegroundColor Green
    Write-Host "  - https://$domainName" -ForegroundColor Cyan
    Write-Host "  - https://$wwwDomainName" -ForegroundColor Cyan
    
    Write-Host "`nTo update your website in the future:" -ForegroundColor Yellow
    Write-Host "1. Edit your website files locally" -ForegroundColor White
    Write-Host "2. Run the deployment script to upload changes:" -ForegroundColor White
    Write-Host "   .\deploy-with-account-id.ps1" -ForegroundColor White
}

# Main execution
Show-Header
$s3Status = Check-S3Status
$certificateArn = Check-CertificateStatus
$distribution = Check-CloudFrontStatus

if ($distribution) {
    Check-DnsStatus -distribution $distribution
    Test-Website -distribution $distribution
}

Show-NextSteps -s3Status $s3Status -certificateArn $certificateArn -distribution $distribution
