# Simple AWS Deployment Verification Script
# This script will check your AWS deployment status for ibridgesolutions.co.za

# Configuration
$accountId = "640825887118"
$s3BucketName = "ibridgesolutions-website-$accountId"
$region = "us-east-1" 
$domainName = "ibridgesolutions.co.za"
$wwwDomainName = "www.ibridgesolutions.co.za"

# Header
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "      AWS DEPLOYMENT STATUS FOR IBRIDGESOLUTIONS   " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Account ID: 6408-2588-7118" -ForegroundColor Yellow
Write-Host "Domain: $domainName" -ForegroundColor Yellow
Write-Host

# Check AWS CLI
Write-Host "Checking AWS CLI..." -ForegroundColor Yellow
try {
    $awsVersion = aws --version
    Write-Host "✓ AWS CLI is installed: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ AWS CLI is not installed. Please install AWS CLI first." -ForegroundColor Red
    exit
}

# Check AWS Credentials
Write-Host "`nChecking AWS credentials..." -ForegroundColor Yellow
try {
    $configStatus = aws configure list
    if ($configStatus -match "access_key") {
        Write-Host "✓ AWS credentials are configured" -ForegroundColor Green
    } else {
        Write-Host "✗ AWS credentials are not configured. Run 'aws configure' first." -ForegroundColor Red
        exit
    }
} catch {
    Write-Host "✗ Error checking AWS credentials: $_" -ForegroundColor Red
    exit
}

# Check S3 Bucket
Write-Host "`nChecking S3 bucket ($s3BucketName)..." -ForegroundColor Yellow
try {
    aws s3api head-bucket --bucket $s3BucketName 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ S3 bucket exists" -ForegroundColor Green
        
        # Check for website configuration
        try {
            aws s3api get-bucket-website --bucket $s3BucketName 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ S3 bucket is configured for website hosting" -ForegroundColor Green
            } else {
                Write-Host "✗ S3 bucket is not configured for website hosting" -ForegroundColor Red
            }
        } catch {}
        
        # Check for files
        try {
            $objects = aws s3 ls s3://$s3BucketName --recursive 2>&1
            if ($objects) {
                Write-Host "✓ Files exist in S3 bucket" -ForegroundColor Green
            } else {
                Write-Host "✗ S3 bucket is empty" -ForegroundColor Red
            }
        } catch {}
        
        # Check for index.html
        try {
            aws s3api head-object --bucket $s3BucketName --key "index.html" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ index.html exists in bucket" -ForegroundColor Green
            } else {
                Write-Host "✗ index.html not found in bucket" -ForegroundColor Red
            }
        } catch {}
    } else {
        Write-Host "✗ S3 bucket does not exist" -ForegroundColor Red
        Write-Host "  Run the deployment script to create the S3 bucket" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Error checking S3 bucket: $_" -ForegroundColor Red
}

# Check CloudFront Distribution
Write-Host "`nChecking CloudFront distribution..." -ForegroundColor Yellow
$foundDistribution = $false
$distributionId = ""
$distributionDomain = ""

try {
    $distributions = aws cloudfront list-distributions 2>&1
    if ($distributions -match [regex]::Escape($domainName)) {
        Write-Host "✓ CloudFront distribution found for $domainName" -ForegroundColor Green
        $foundDistribution = $true
        
        # Try to extract distribution ID and domain
        if ($distributions -match "Id: ([A-Z0-9]+)") {
            $distributionId = $Matches[1]
            Write-Host "  Distribution ID: $distributionId" -ForegroundColor Cyan
        }
        
        if ($distributions -match "DomainName: ([a-z0-9.]+\\.cloudfront\\.net)") {
            $distributionDomain = $Matches[1]
            Write-Host "  Distribution Domain: $distributionDomain" -ForegroundColor Cyan
        }
    } else {
        Write-Host "✗ No CloudFront distribution found for $domainName" -ForegroundColor Red
        Write-Host "  Run the deployment script to create the CloudFront distribution" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Error checking CloudFront: $_" -ForegroundColor Red
}

# Check SSL Certificate
Write-Host "`nChecking SSL certificate..." -ForegroundColor Yellow
try {
    $certificates = aws acm list-certificates --region $region 2>&1
    if ($certificates -match $domainName) {
        Write-Host "✓ SSL certificate found for $domainName" -ForegroundColor Green
    } else {
        Write-Host "✗ No SSL certificate found for $domainName" -ForegroundColor Red
        Write-Host "  Run the deployment script to request an SSL certificate" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Error checking SSL certificate: $_" -ForegroundColor Red
}

# Check DNS Settings
Write-Host "`nChecking DNS settings..." -ForegroundColor Yellow
if ($foundDistribution -and $distributionDomain) {
    # Check apex domain
    try {
        $dnsResults = Resolve-DnsName -Name $domainName -ErrorAction SilentlyContinue
        if ($dnsResults) {
            Write-Host "✓ Domain $domainName resolves successfully" -ForegroundColor Green
        } else {
            Write-Host "✗ Domain $domainName does not resolve" -ForegroundColor Red
            Write-Host "  Update your DNS settings to point to CloudFront" -ForegroundColor Yellow
        }
    } catch {}
    
    # Check www subdomain
    try {
        $dnsWww = Resolve-DnsName -Name $wwwDomainName -ErrorAction SilentlyContinue
        if ($dnsWww) {
            Write-Host "✓ Domain $wwwDomainName resolves successfully" -ForegroundColor Green
        } else {
            Write-Host "✗ Domain $wwwDomainName does not resolve" -ForegroundColor Red
            Write-Host "  Update your DNS settings to point to CloudFront" -ForegroundColor Yellow
        }
    } catch {}
} else {
    Write-Host "  Skipping DNS check (CloudFront distribution not found)" -ForegroundColor Yellow
}

# Check Website Accessibility
Write-Host "`nChecking website accessibility..." -ForegroundColor Yellow
try {
    $request = [System.Net.WebRequest]::Create("https://$domainName")
    $request.AllowAutoRedirect = $false
    try {
        $response = $request.GetResponse()
        Write-Host "✓ Website is accessible at https://$domainName" -ForegroundColor Green
        Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Green
        
        # Check if URL contains /lander
        $url = $response.ResponseUri.ToString()
        if ($url -like "*/lander*") {
            Write-Host "✗ Website is still redirecting to /lander" -ForegroundColor Red
            Write-Host "  Check GoDaddy for redirect settings" -ForegroundColor Yellow
        }
        $response.Close()
    } catch [System.Net.WebException] {
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Found) {
            $location = $_.Exception.Response.Headers["Location"]
            Write-Host "! Website returns a redirect to: $location" -ForegroundColor Yellow
            
            if ($location -like "*/lander*") {
                Write-Host "✗ Website is still redirecting to /lander" -ForegroundColor Red
                Write-Host "  Check GoDaddy for redirect settings" -ForegroundColor Yellow
            }
        } else {
            Write-Host "✗ Website is not accessible: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "✗ Error testing website: $_" -ForegroundColor Red
}

# Summary
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "                   SUMMARY                       " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if ($foundDistribution) {
    Write-Host "Your AWS deployment appears to be set up." -ForegroundColor Green
    Write-Host
    Write-Host "To update your website in the future, use:" -ForegroundColor Yellow
    Write-Host "PowerShell -ExecutionPolicy Bypass -File .\simple-aws-deploy.ps1" -ForegroundColor White
} else {
    Write-Host "Your AWS deployment is not complete." -ForegroundColor Yellow
    Write-Host
    Write-Host "Please run the main deployment script:" -ForegroundColor Yellow
    Write-Host "PowerShell -ExecutionPolicy Bypass -File .\deploy-with-account-id.ps1" -ForegroundColor White
}

Write-Host
Write-Host "For detailed setup information, refer to:" -ForegroundColor Yellow
Write-Host "AWS-DEPLOYMENT-GUIDE.md" -ForegroundColor White

function Show-Header {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   AWS DEPLOYMENT VERIFICATION FOR IBRIDGESOLUTIONS.CO.ZA  " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "Account ID: 6408-2588-7118" -ForegroundColor Yellow
    Write-Host
}

function Test-AwsCli {
    Write-Host "Checking AWS CLI installation..." -ForegroundColor Yellow
    try {
        $awsVersion = aws --version
        Write-Host "✓ AWS CLI is installed: $awsVersion" -ForegroundColor Green
        # Check if credentials are configured
        Write-Host "Checking AWS credentials..."
        $configStatus = aws configure list 2>&1
        if ($configStatus -match "access_key") {
            Write-Host "✓ AWS credentials are configured." -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ AWS credentials are not configured." -ForegroundColor Red
            Write-Host "Please run 'aws configure' to set up your credentials." -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "✗ AWS CLI is not installed." -ForegroundColor Red
        Write-Host "Please install AWS CLI first:" -ForegroundColor Yellow
        Write-Host "1. Download from: https://aws.amazon.com/cli/" -ForegroundColor White
        Write-Host "2. Run the installer" -ForegroundColor White
        Write-Host "3. Run 'aws configure' to set up your AWS credentials" -ForegroundColor White
        return $false
    }
}

function Test-S3Bucket {
    Write-Host "`nChecking S3 bucket..." -ForegroundColor Yellow
    try {
        # Check if bucket exists
        aws s3api head-bucket --bucket $s3BucketName 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ S3 bucket '$s3BucketName' exists" -ForegroundColor Green
            # Check if bucket is configured for website hosting
            aws s3api get-bucket-website --bucket $s3BucketName 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ S3 bucket is configured for website hosting" -ForegroundColor Green
                $s3WebsiteUrl = "http://$s3BucketName.s3-website-$region.amazonaws.com"
                Write-Host "  S3 Website URL: $s3WebsiteUrl" -ForegroundColor Cyan
            } else {
                Write-Host "✗ S3 bucket is not configured for website hosting" -ForegroundColor Red
            }
            # Check for website files
            $objects = aws s3 ls s3://$s3BucketName --recursive 2>&1
            if ($objects) {
                $objectCount = ($objects | Measure-Object -Line).Lines
                Write-Host "✓ S3 bucket contains $objectCount object(s)" -ForegroundColor Green
                # Check for index.html
                aws s3api head-object --bucket $s3BucketName --key "index.html" 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✓ index.html file exists in bucket" -ForegroundColor Green
                } else {
                    Write-Host "✗ index.html file not found in bucket" -ForegroundColor Red
                }
            } else {
                Write-Host "✗ S3 bucket appears to be empty" -ForegroundColor Red
            }
        } else {
            Write-Host "✗ S3 bucket '$s3BucketName' does not exist" -ForegroundColor Red
            Write-Host "  Run the deployment script to create the bucket:" -ForegroundColor Yellow
            Write-Host "  PowerShell -ExecutionPolicy Bypass -File .\deploy-with-account-id.ps1" -ForegroundColor White
        }
    } catch {
        Write-Host "✗ Error checking S3 bucket: $_" -ForegroundColor Red
    }
}

function Test-CloudFrontDistribution {
    Write-Host "`nChecking CloudFront distribution..." -ForegroundColor Yellow
    try {
        $distributions = aws cloudfront list-distributions 2>&1
        if ($distributions.DistributionList.Items) {
            foreach ($dist in $distributions.DistributionList.Items) {
                # Check for domain in aliases
                if ($dist.Aliases.Items -and ($dist.Aliases.Items.Contains($domainName) -or $dist.Aliases.Items.Contains($wwwDomainName))) {
                    $foundDistribution = $dist
                    break
                }
                # Check origin domain for our S3 bucket
                if ($dist.Origins.Items.DomainName -match $s3BucketName) {
                    $foundDistribution = $dist
                    break
                }
            }
            if ($foundDistribution) {
                Write-Host "✓ CloudFront distribution found" -ForegroundColor Green
                Write-Host "  Distribution ID: $($foundDistribution.Id)" -ForegroundColor Cyan
                Write-Host "  Distribution Domain: $($foundDistribution.DomainName)" -ForegroundColor Cyan
                Write-Host "  Status: $($foundDistribution.Status)" -ForegroundColor (if ($foundDistribution.Status -eq "Deployed") { "Green" } else { "Yellow" })
                if ($foundDistribution.Status -ne "Deployed") {
                    Write-Host "  Distribution is currently deploying. This can take 15-30 minutes." -ForegroundColor Yellow
                }
                # Check if HTTPS is enabled
                $viewerProtocolPolicy = $foundDistribution.DefaultCacheBehavior.ViewerProtocolPolicy
                if ($viewerProtocolPolicy -eq "redirect-to-https") {
                    Write-Host "✓ HTTPS is properly configured (redirect-to-https)" -ForegroundColor Green
                } else {
                    Write-Host "! HTTPS configuration: $viewerProtocolPolicy" -ForegroundColor Yellow
                }
                # Check SSL certificate
                if ($foundDistribution.ViewerCertificate.ACMCertificateArn) {
                    Write-Host "✓ SSL certificate is configured" -ForegroundColor Green
                } else {
                    Write-Host "✗ Custom SSL certificate is not configured" -ForegroundColor Red
                }
                # Check domain aliases
                if ($foundDistribution.Aliases.Items) {
                    Write-Host "  Configured domains: $($foundDistribution.Aliases.Items -join ', ')" -ForegroundColor Cyan
                    $hasApexDomain = $foundDistribution.Aliases.Items.Contains($domainName)
                    $hasWwwDomain = $foundDistribution.Aliases.Items.Contains($wwwDomainName)
                    if ($hasApexDomain) {
                        Write-Host "✓ Apex domain ($domainName) is configured" -ForegroundColor Green
                    } else {
                        Write-Host "✗ Apex domain ($domainName) is not configured" -ForegroundColor Red
                    }
                    if ($hasWwwDomain) {
                        Write-Host "✓ WWW domain ($wwwDomainName) is configured" -ForegroundColor Green
                    } else {
                        Write-Host "✗ WWW domain ($wwwDomainName) is not configured" -ForegroundColor Red
                    }
                } else {
                    Write-Host "✗ No custom domain aliases configured" -ForegroundColor Red
                }
                return @{
                    Exists = $true
                    Id = $foundDistribution.Id
                    DomainName = $foundDistribution.DomainName
                    Status = $foundDistribution.Status
                }
            } else {
                Write-Host "✗ No CloudFront distribution found for $domainName or $s3BucketName" -ForegroundColor Red
                Write-Host "  Run the deployment script to create a CloudFront distribution:" -ForegroundColor Yellow
                Write-Host "  PowerShell -ExecutionPolicy Bypass -File .\deploy-with-account-id.ps1" -ForegroundColor White
                return @{
                    Exists = $false
                    Id = $null
                    DomainName = $null
                    Status = $null
                }
            }
        } else {
            Write-Host "✗ No CloudFront distributions found in your account" -ForegroundColor Red
            Write-Host "  Run the deployment script to create a CloudFront distribution:" -ForegroundColor Yellow
            Write-Host "  PowerShell -ExecutionPolicy Bypass -File .\deploy-with-account-id.ps1" -ForegroundColor White
            return @{
                Exists = $false
                Id = $null
                DomainName = $null
                Status = $null
            }
        }
    } catch {
        Write-Host "✗ Error checking CloudFront distributions: $_" -ForegroundColor Red
        return @{
            Exists = $false
            Id = $null
            DomainName = $null
            Status = $null
        }
    }
}

function Test-SSLCertificate {
    Write-Host "`nChecking SSL certificate..." -ForegroundColor Yellow
    
    try {
        # List certificates
        $certificates = aws acm list-certificates --region $region 2>&1 | ConvertFrom-Json
        
        if ($certificates.CertificateSummaryList) {
            $foundCertificate = $null
            
            foreach ($cert in $certificates.CertificateSummaryList) {
                if ($cert.DomainName -eq $domainName) {
                    $foundCertificate = $cert
                    break
                }
            }
            
            if ($foundCertificate) {
                $certArn = $foundCertificate.CertificateArn
                Write-Host "✓ SSL certificate found for $domainName" -ForegroundColor Green
                Write-Host "  Certificate ARN: $certArn" -ForegroundColor Cyan
                
                # Get certificate details
                $certDetails = aws acm describe-certificate --certificate-arn $certArn --region $region 2>&1 | ConvertFrom-Json
                $status = $certDetails.Certificate.Status
                
                Write-Host "  Status: $status" -ForegroundColor (if ($status -eq "ISSUED") { "Green" } else { "Yellow" })
                
                if ($status -eq "PENDING_VALIDATION") {
                    Write-Host "  Certificate needs DNS validation. Run:" -ForegroundColor Yellow
                    Write-Host "  PowerShell -ExecutionPolicy Bypass -File .\check-certificate-validation.ps1" -ForegroundColor White
                }
                
                return @{
                    Exists = $true
                    Arn = $certArn
                    Status = $status
                }
            } else {
                Write-Host "✗ No SSL certificate found for $domainName" -ForegroundColor Red
                Write-Host "  Run the deployment script to request a certificate:" -ForegroundColor Yellow
                Write-Host "  PowerShell -ExecutionPolicy Bypass -File .\deploy-with-account-id.ps1" -ForegroundColor White
                
                return @{
                    Exists = $false
                    Arn = $null
                    Status = $null
                }
            }
        } else {
            Write-Host "✗ No SSL certificates found in your account" -ForegroundColor Red
            Write-Host "  Run the deployment script to request a certificate:" -ForegroundColor Yellow
            Write-Host "  PowerShell -ExecutionPolicy Bypass -File .\deploy-with-account-id.ps1" -ForegroundColor White
            
            return @{
                Exists = $false
                Arn = $null
                Status = $null
            }
        }
    } catch {
        Write-Host "✗ Error checking SSL certificates: $_" -ForegroundColor Red
        return @{
            Exists = $false
            Arn = $null
            Status = $null
        }
    }
}

function Test-Route53 {
    Write-Host "`nChecking Route 53 configuration..." -ForegroundColor Yellow
    
    try {
        # Check if hosted zone exists
        $hostedZones = aws route53 list-hosted-zones 2>&1 | ConvertFrom-Json
        
        if ($hostedZones.HostedZones) {
            $foundZone = $null
            
            foreach ($zone in $hostedZones.HostedZones) {
                if ($zone.Name -eq "$domainName.") {
                    $foundZone = $zone
                    break
                }
            }
            
            if ($foundZone) {
                $zoneId = $foundZone.Id.Split("/")[2]
                Write-Host "✓ Route 53 hosted zone found for $domainName" -ForegroundColor Green
                Write-Host "  Zone ID: $zoneId" -ForegroundColor Cyan
                
                # Check for DNS records
                $records = aws route53 list-resource-record-sets --hosted-zone-id $zoneId 2>&1 | ConvertFrom-Json
                
                if ($records.ResourceRecordSets) {
                    $apexRecord = $null
                    $wwwRecord = $null
                    
                    foreach ($record in $records.ResourceRecordSets) {
                        if ($record.Name -eq "$domainName.") {
                            $apexRecord = $record
                        } elseif ($record.Name -eq "$wwwDomainName.") {
                            $wwwRecord = $record
                        }
                    }
                    
                    if ($apexRecord) {
                        Write-Host "✓ DNS record found for apex domain ($domainName)" -ForegroundColor Green
                        Write-Host "  Type: $($apexRecord.Type)" -ForegroundColor Cyan
                    } else {
                        Write-Host "✗ No DNS record found for apex domain ($domainName)" -ForegroundColor Red
                    }
                    
                    if ($wwwRecord) {
                        Write-Host "✓ DNS record found for www subdomain ($wwwDomainName)" -ForegroundColor Green
                        Write-Host "  Type: $($wwwRecord.Type)" -ForegroundColor Cyan
                    } else {
                        Write-Host "✗ No DNS record found for www subdomain ($wwwDomainName)" -ForegroundColor Red
                    }
                } else {
                    Write-Host "✗ No DNS records found in hosted zone" -ForegroundColor Red
                }
                
                return @{
                    Exists = $true
                    ZoneId = $zoneId
                }
            } else {
                Write-Host "✗ No Route 53 hosted zone found for $domainName" -ForegroundColor Yellow
                Write-Host "  This is optional. If you want to use Route 53 for DNS, run:" -ForegroundColor Yellow
                Write-Host "  PowerShell -ExecutionPolicy Bypass -File .\migrate-to-route53.ps1" -ForegroundColor White
                
                return @{
                    Exists = $false
                    ZoneId = $null
                }
            }
        } else {
            Write-Host "✗ No Route 53 hosted zones found in your account" -ForegroundColor Yellow
            Write-Host "  This is optional. If you want to use Route 53 for DNS, run:" -ForegroundColor Yellow
            Write-Host "  PowerShell -ExecutionPolicy Bypass -File .\migrate-to-route53.ps1" -ForegroundColor White
            
            return @{
                Exists = $false
                ZoneId = $null
            }
        }
    } catch {
        Write-Host "✗ Error checking Route 53: $_" -ForegroundColor Red
        return @{
            Exists = $false
            ZoneId = $null
        }
    }
}

function Test-DomainDNS {
    Write-Host "`nChecking DNS settings for domain..." -ForegroundColor Yellow
    try {
        $dnsResults = Resolve-DnsName -Name $domainName -ErrorAction SilentlyContinue
        if ($dnsResults) {
            Write-Host "✓ Domain $domainName resolves successfully" -ForegroundColor Green
        } else {
            Write-Host "✗ Domain $domainName does not resolve" -ForegroundColor Red
            Write-Host "  Update your DNS settings to point to CloudFront" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ Error checking DNS: $_" -ForegroundColor Red
    }
}

function Test-Websites {
    param (
        [object]$cloudFront
    )
    
    Write-Host "`nTesting website access..." -ForegroundColor Yellow
    
    if (-not $cloudFront.Exists) {
        Write-Host "  Skipping website tests (CloudFront distribution not found)" -ForegroundColor Yellow
        return
    }
    
    $cfDomain = $cloudFront.DomainName
    
    # Test CloudFront directly
    Write-Host "Testing CloudFront URL (https://$cfDomain)..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri "https://$cfDomain" -MaximumRedirection 0 -ErrorAction SilentlyContinue
        Write-Host "✓ CloudFront URL accessible (Status: $($response.StatusCode))" -ForegroundColor Green
    } catch {
        if ($_.Exception.Response.StatusCode.Value__ -eq 301 -or $_.Exception.Response.StatusCode.Value__ -eq 302) {
            Write-Host "✓ CloudFront URL returns redirect (Status: $($_.Exception.Response.StatusCode.Value__))" -ForegroundColor Yellow
            Write-Host "  Redirects to: $($_.Exception.Response.Headers.Location)" -ForegroundColor Yellow
        } else {
            Write-Host "✗ Error accessing CloudFront URL: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "  Status code: $($_.Exception.Response.StatusCode.Value__)" -ForegroundColor Red
        }
    }
    
    # Test apex domain
    Write-Host "`nTesting apex domain (https://$domainName)..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri "https://$domainName" -MaximumRedirection 0 -ErrorAction SilentlyContinue
        Write-Host "✓ Apex domain accessible (Status: $($response.StatusCode))" -ForegroundColor Green
        
        # Check for /lander redirect in the URL
        if ($response.BaseResponse.ResponseUri.AbsolutePath -like "*/lander*") {
            Write-Host "✗ Website still redirects to /lander" -ForegroundColor Red
            Write-Host "  Check GoDaddy for active redirects or website forwarding" -ForegroundColor Yellow
        }
    } catch {
        if ($_.Exception.Response.StatusCode.Value__ -eq 301 -or $_.Exception.Response.StatusCode.Value__ -eq 302) {
            $location = $_.Exception.Response.Headers.Location
            Write-Host "✓ Apex domain returns redirect (Status: $($_.Exception.Response.StatusCode.Value__))" -ForegroundColor Yellow
            Write-Host "  Redirects to: $location" -ForegroundColor Yellow
            
            # Check for /lander redirect in the location
            if ($location -like "*/lander*") {
                Write-Host "✗ Website still redirects to /lander" -ForegroundColor Red
                Write-Host "  Check GoDaddy for active redirects or website forwarding" -ForegroundColor Yellow
            }
        } else {
            Write-Host "✗ Error accessing apex domain: $($_.Exception.Message)" -ForegroundColor Red
            if ($_.Exception.Response) {
                Write-Host "  Status code: $($_.Exception.Response.StatusCode.Value__)" -ForegroundColor Red
            }
        }
    }
    
    # Test www subdomain
    Write-Host "`nTesting www subdomain (https://$wwwDomainName)..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri "https://$wwwDomainName" -MaximumRedirection 0 -ErrorAction SilentlyContinue
        Write-Host "✓ WWW subdomain accessible (Status: $($response.StatusCode))" -ForegroundColor Green
        
        # Check for /lander redirect in the URL
        if ($response.BaseResponse.ResponseUri.AbsolutePath -like "*/lander*") {
            Write-Host "✗ Website still redirects to /lander" -ForegroundColor Red
            Write-Host "  Check GoDaddy for active redirects or website forwarding" -ForegroundColor Yellow
        }
    } catch {
        if ($_.Exception.Response.StatusCode.Value__ -eq 301 -or $_.Exception.Response.StatusCode.Value__ -eq 302) {
            $location = $_.Exception.Response.Headers.Location
            Write-Host "✓ WWW subdomain returns redirect (Status: $($_.Exception.Response.StatusCode.Value__))" -ForegroundColor Yellow
            Write-Host "  Redirects to: $location" -ForegroundColor Yellow
            
            # Check for /lander redirect in the location
            if ($location -like "*/lander*") {
                Write-Host "✗ Website still redirects to /lander" -ForegroundColor Red
                Write-Host "  Check GoDaddy for active redirects or website forwarding" -ForegroundColor Yellow
            }
        } else {
            Write-Host "✗ Error accessing WWW subdomain: $($_.Exception.Message)" -ForegroundColor Red
            if ($_.Exception.Response) {
                Write-Host "  Status code: $($_.Exception.Response.StatusCode.Value__)" -ForegroundColor Red
            }
        }
    }
}

function Show-NextSteps {
    param (
        [object]$s3,
        [object]$cloudFront,
        [object]$ssl,
        [object]$route53
    )
    
    Write-Host "`n==========================================================" -ForegroundColor Cyan
    Write-Host "                      NEXT STEPS                          " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    if (-not $s3.Exists) {
        Write-Host "1. Create S3 bucket and upload website files:" -ForegroundColor Yellow
        Write-Host "   PowerShell -ExecutionPolicy Bypass -File .\deploy-with-account-id.ps1" -ForegroundColor White
        return
    }
    
    if (-not $ssl.Exists) {
        Write-Host "1. Request SSL certificate for your domain:" -ForegroundColor Yellow
        Write-Host "   PowerShell -ExecutionPolicy Bypass -File .\deploy-with-account-id.ps1" -ForegroundColor White
        return
    } elseif ($ssl.Status -ne "ISSUED") {
        Write-Host "1. Validate your SSL certificate:" -ForegroundColor Yellow
        Write-Host "   PowerShell -ExecutionPolicy Bypass -File .\check-certificate-validation.ps1" -ForegroundColor White
        return
    }
    
    if (-not $cloudFront.Exists) {
        Write-Host "1. Create CloudFront distribution:" -ForegroundColor Yellow
        Write-Host "   PowerShell -ExecutionPolicy Bypass -File .\deploy-with-account-id.ps1" -ForegroundColor White
        return
    } elseif ($cloudFront.Status -ne "Deployed") {
        Write-Host "1. Wait for CloudFront distribution to deploy (15-30 minutes)" -ForegroundColor Yellow
        Write-Host "2. Run this script again to check status:" -ForegroundColor Yellow
        Write-Host "   PowerShell -ExecutionPolicy Bypass -File .\verify-aws-deployment.ps1" -ForegroundColor White
        return
    }
    
    # DNS configuration recommendations
    $dnsApex = Resolve-DnsName -Name $domainName -ErrorAction SilentlyContinue
    $dnsWww = Resolve-DnsName -Name $wwwDomainName -ErrorAction SilentlyContinue
    
    if (-not $dnsApex -or -not $dnsWww) {
        if ($route53.Exists) {
            Write-Host "1. Update your Route 53 DNS records:" -ForegroundColor Yellow
            Write-Host "   PowerShell -ExecutionPolicy Bypass -File .\migrate-to-route53.ps1" -ForegroundColor White
        } else {
            Write-Host "1. Update your GoDaddy DNS settings:" -ForegroundColor Yellow
            Write-Host "   - For apex domain ($domainName):" -ForegroundColor White
            Write-Host "     Type: CNAME | Host: @ | Points to: $($cloudFront.DomainName)" -ForegroundColor White
            Write-Host "   - For www subdomain:" -ForegroundColor White
            Write-Host "     Type: CNAME | Host: www | Points to: $($cloudFront.DomainName)" -ForegroundColor White
            
            Write-Host "`n   Note: If GoDaddy doesn't allow CNAME for apex domain (@)," -ForegroundColor Yellow
            Write-Host "   you should migrate DNS to Route 53:" -ForegroundColor Yellow
            Write-Host "   PowerShell -ExecutionPolicy Bypass -File .\migrate-to-route53.ps1" -ForegroundColor White
        }
        
        Write-Host "`n2. After updating DNS, wait for propagation (24-48 hours)" -ForegroundColor White
        Write-Host "3. Run this script again to verify everything is working:" -ForegroundColor White
        Write-Host "   PowerShell -ExecutionPolicy Bypass -File .\verify-aws-deployment.ps1" -ForegroundColor White
        return
    }
    
    # If everything looks good
    Write-Host "✓ Your AWS deployment looks complete!" -ForegroundColor Green
    Write-Host "  Website should be accessible at:" -ForegroundColor Cyan
    Write-Host "  - https://$domainName" -ForegroundColor Cyan
    Write-Host "  - https://$wwwDomainName" -ForegroundColor Cyan
    
    Write-Host "`nTo update your website in the future:" -ForegroundColor Yellow
    Write-Host "1. Run the simple deployment script:" -ForegroundColor White
    Write-Host "   PowerShell -ExecutionPolicy Bypass -File .\simple-aws-deploy.ps1" -ForegroundColor White
}

# Main execution flow
Show-Header
$awsCliOK = Test-AwsCli

if ($awsCliOK) {
    $s3Status = Test-S3Bucket
    $cloudFrontStatus = Test-CloudFrontDistribution
    $sslStatus = Test-SSLCertificate
    $route53Status = Test-Route53
    
    Test-DomainDNS
    Test-Websites -cloudFront $cloudFrontStatus
    
    Show-NextSteps -s3 $s3Status -cloudFront $cloudFrontStatus -ssl $sslStatus -route53 $route53Status
}