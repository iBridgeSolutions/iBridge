# Check AWS Deployment Status Script
# This script checks the status of your AWS CloudFront/S3 website deployment

$domainName = "ibridgesolutions.co.za"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "     IBRIDGESOLUTIONS AWS DEPLOYMENT STATUS" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host

# Check for CloudFront distribution info
$distributionId = $null
$distributionDomain = $null

if (Test-Path ".\cloudfront-info.txt") {
    $cloudFrontInfo = Get-Content -Path ".\cloudfront-info.txt" -Raw
    
    if ($cloudFrontInfo -match "Distribution ID: (.+)") {
        $distributionId = $matches[1].Trim()
    }
    
    if ($cloudFrontInfo -match "Distribution Domain: (.+)") {
        $distributionDomain = $matches[1].Trim()
    }
}

Write-Host "CLOUDFRONT DISTRIBUTION:" -ForegroundColor Green
Write-Host "------------------------" -ForegroundColor Green

if ($distributionId -and $distributionDomain) {
    Write-Host "Distribution ID: $distributionId" -ForegroundColor White
    Write-Host "Distribution Domain: $distributionDomain" -ForegroundColor White
    
    # Check CloudFront status
    try {
        $distribution = aws cloudfront get-distribution --id $distributionId | ConvertFrom-Json
        $status = $distribution.Distribution.Status
        $enabled = $distribution.Distribution.DistributionConfig.Enabled
        
        Write-Host "Distribution Status: $status" -ForegroundColor $(if ($status -eq "Deployed") { "Green" } else { "Yellow" })
        Write-Host "Distribution Enabled: $enabled" -ForegroundColor $(if ($enabled -eq "True") { "Green" } else { "Red" })
        
        # Check custom domain settings
        $aliases = $distribution.Distribution.DistributionConfig.Aliases
        if ($aliases.Quantity -gt 0) {
            Write-Host "Custom Domains:" -ForegroundColor White
            foreach ($alias in $aliases.Items) {
                Write-Host "  - $alias" -ForegroundColor White
            }
        } else {
            Write-Host "❌ No custom domains configured" -ForegroundColor Red
        }
        
        # Check certificate
        $certificate = $distribution.Distribution.DistributionConfig.ViewerCertificate
        if ($certificate.ACMCertificateArn) {
            $certArn = $certificate.ACMCertificateArn
            Write-Host "SSL Certificate: $certArn" -ForegroundColor Green
            
            # Check certificate status
            $certDetails = aws acm describe-certificate --certificate-arn $certArn --region us-east-1 | ConvertFrom-Json
            $certStatus = $certDetails.Certificate.Status
            
            Write-Host "Certificate Status: $certStatus" -ForegroundColor $(if ($certStatus -eq "ISSUED") { "Green" } else { "Yellow" })
        } else {
            Write-Host "❌ No SSL certificate configured" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "❌ Error retrieving CloudFront distribution details: $_" -ForegroundColor Red
    }
} else {
    Write-Host "❌ CloudFront distribution information not found" -ForegroundColor Red
    Write-Host "Run 'complete-aws-deploy.ps1' to create a CloudFront distribution." -ForegroundColor Yellow
}

Write-Host "`nS3 BUCKET:" -ForegroundColor Green
Write-Host "----------" -ForegroundColor Green

# Check S3 bucket
try {
    aws s3api head-bucket --bucket $domainName 2>$null
    
    if ($?) {
        Write-Host "✅ S3 bucket '$domainName' exists" -ForegroundColor Green
        
        # Check bucket website configuration
        $websiteConfig = aws s3api get-bucket-website --bucket $domainName 2>$null | ConvertFrom-Json
        
        if ($?) {
            Write-Host "✅ S3 bucket configured for website hosting" -ForegroundColor Green
            Write-Host "  - Index Document: $($websiteConfig.IndexDocument.Suffix)" -ForegroundColor White
            if ($websiteConfig.ErrorDocument) {
                Write-Host "  - Error Document: $($websiteConfig.ErrorDocument.Key)" -ForegroundColor White
            }
        } else {
            Write-Host "❌ S3 bucket not configured for website hosting" -ForegroundColor Red
        }
        
        # Check bucket public access settings
        $publicAccessBlock = aws s3api get-public-access-block --bucket $domainName 2>$null | ConvertFrom-Json
        
        if ($?) {
            $blockPublicAcls = $publicAccessBlock.PublicAccessBlockConfiguration.BlockPublicAcls
            $blockPublicPolicy = $publicAccessBlock.PublicAccessBlockConfiguration.BlockPublicPolicy
            
            if (-not $blockPublicAcls -and -not $blockPublicPolicy) {
                Write-Host "✅ S3 bucket public access settings configured correctly" -ForegroundColor Green
            } else {
                Write-Host "❌ S3 bucket has public access blocked" -ForegroundColor Red
            }
        }
        
        # Check bucket contents
        $objects = aws s3 ls "s3://$domainName" --recursive | Select-String -Pattern "index.html"
        
        if ($objects) {
            Write-Host "✅ Website files found in S3 bucket" -ForegroundColor Green
        } else {
            Write-Host "❌ No index.html found in S3 bucket" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ S3 bucket '$domainName' does not exist" -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ Error checking S3 bucket: $_" -ForegroundColor Red
}

Write-Host "`nDNS CONFIGURATION:" -ForegroundColor Green
Write-Host "------------------" -ForegroundColor Green

# Check DNS configuration
Write-Host "Checking DNS for $domainName..." -ForegroundColor Yellow
try {
    $dnsRecords = Resolve-DnsName -Name $domainName -ErrorAction Stop
    
    $pointsToCloudFront = $false
    foreach ($record in $dnsRecords) {
        if ($record.Name -eq "$domainName." -and $record.NameHost) {
            if ($record.NameHost -like "*.cloudfront.net") {
                $pointsToCloudFront = $true
                Write-Host "✅ Domain $domainName correctly points to CloudFront: $($record.NameHost)" -ForegroundColor Green
            }
        }
    }
    
    if (-not $pointsToCloudFront) {
        Write-Host "❌ Domain $domainName does not point to CloudFront" -ForegroundColor Red
        
        Write-Host "`nCurrent DNS configuration:" -ForegroundColor Yellow
        foreach ($record in $dnsRecords) {
            if ($record.IPAddress) {
                Write-Host "  - $($record.Name): $($record.IPAddress)" -ForegroundColor White
            } elseif ($record.NameHost) {
                Write-Host "  - $($record.Name): $($record.NameHost)" -ForegroundColor White
            }
        }
    }
}
catch {
    Write-Host "❌ Error resolving DNS for $($domainName): $($_)" -ForegroundColor Red
}

Write-Host "`nChecking DNS for www.$domainName..." -ForegroundColor Yellow
try {
    $wwwRecords = Resolve-DnsName -Name "www.$domainName" -ErrorAction Stop
    
    $wwwPointsToCloudFront = $false
    foreach ($record in $wwwRecords) {
        if ($record.Name -eq "www.$domainName." -and $record.NameHost) {
            if ($record.NameHost -like "*.cloudfront.net") {
                $wwwPointsToCloudFront = $true
                Write-Host "✅ Domain www.$domainName correctly points to CloudFront: $($record.NameHost)" -ForegroundColor Green
            }
        }
    }
    
    if (-not $wwwPointsToCloudFront) {
        Write-Host "❌ Domain www.$domainName does not point to CloudFront" -ForegroundColor Red
        
        Write-Host "`nCurrent DNS configuration:" -ForegroundColor Yellow
        foreach ($record in $wwwRecords) {
            if ($record.IPAddress) {
                Write-Host "  - $($record.Name): $($record.IPAddress)" -ForegroundColor White
            } elseif ($record.NameHost) {
                Write-Host "  - $($record.Name): $($record.NameHost)" -ForegroundColor White
            }
        }
    }
}
catch {
    Write-Host "❌ Error resolving DNS for www.$($domainName): $($_)" -ForegroundColor Red
}

# Website accessibility test
Write-Host "`nWEBSITE ACCESSIBILITY TEST:" -ForegroundColor Green
Write-Host "-------------------------" -ForegroundColor Green

# Test CloudFront URL
if ($distributionDomain) {
    Write-Host "Testing CloudFront URL (https://$distributionDomain)..." -ForegroundColor Yellow
    try {
        $cloudFrontResponse = Invoke-WebRequest -Uri "https://$distributionDomain" -UseBasicParsing
        Write-Host "✅ CloudFront URL accessible: Status $($cloudFrontResponse.StatusCode)" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error accessing CloudFront URL: $_" -ForegroundColor Red
    }
}

# Test domain URLs
Write-Host "`nTesting main domain (https://$domainName)..." -ForegroundColor Yellow
try {
    $domainResponse = Invoke-WebRequest -Uri "https://$domainName" -UseBasicParsing
    Write-Host "✅ Domain accessible: Status $($domainResponse.StatusCode)" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error accessing domain: $_" -ForegroundColor Red
}

Write-Host "`nTesting www subdomain (https://www.$domainName)..." -ForegroundColor Yellow
try {
    $wwwResponse = Invoke-WebRequest -Uri "https://www.$domainName" -UseBasicParsing
    Write-Host "✅ WWW subdomain accessible: Status $($wwwResponse.StatusCode)" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error accessing www subdomain: $_" -ForegroundColor Red
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "     WHAT TO DO NEXT" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if ($distributionId -and $distributionDomain) {
    Write-Host "✅ CloudFront distribution is set up" -ForegroundColor Green
} else {
    Write-Host "1. Run 'complete-aws-deploy.ps1' to create CloudFront distribution" -ForegroundColor Yellow
}

$dnsConfigured = $pointsToCloudFront -and $wwwPointsToCloudFront
if ($dnsConfigured) {
    Write-Host "✅ DNS is configured correctly" -ForegroundColor Green
} else {
    if ($distributionDomain) {
        Write-Host "1. Configure DNS records at GoDaddy:" -ForegroundColor Yellow
        Write-Host "   - CNAME record for @ pointing to: $distributionDomain" -ForegroundColor White
        Write-Host "   - CNAME record for www pointing to: $distributionDomain" -ForegroundColor White
        Write-Host "   (If @ CNAME is not allowed, use GoDaddy forwarding to www.$domainName instead)" -ForegroundColor White
    } else {
        Write-Host "1. First create CloudFront distribution, then configure DNS" -ForegroundColor Yellow
    }
}

Write-Host "`n⚠️ Remember: DNS changes and CloudFront deployments can take time to propagate (1-48 hours)" -ForegroundColor Yellow
