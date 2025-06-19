# iBridge Website Status Check
# This script checks the status of your website hosted on AWS CloudFront

$domainName = "ibridgesolutions.co.za"
$wwwDomain = "www.$domainName"

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "   iBRIDGE WEBSITE STATUS CHECK   " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# Function to test website accessibility
function Test-Website {
    param (
        [string]$url,
        [string]$description
    )
    
    Write-Host "Testing $description ($url)..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -MaximumRedirection 5
        $statusCode = $response.StatusCode
        
        if ($statusCode -eq 200) {
            Write-Host "✅ Accessible! Status code: $statusCode" -ForegroundColor Green
            return $true
        } else {
            Write-Host "⚠️ Unusual status code: $statusCode" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "❌ Not accessible: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to check DNS configuration
function Test-DNS {
    param (
        [string]$domain
    )
    
    Write-Host "`nChecking DNS for $domain..." -ForegroundColor Yellow
    
    try {
        $dnsRecords = Resolve-DnsName -Name $domain -ErrorAction Stop
        
        Write-Host "DNS Records:" -ForegroundColor Cyan
        foreach ($record in $dnsRecords) {
            if ($record.IPAddress) {
                Write-Host "  - IP Address: $($record.IPAddress)" -ForegroundColor White
                
                # Check if it's a CloudFront IP
                if ($record.IPAddress -like "52.85.*") {
                    Write-Host "    (CloudFront IP address)" -ForegroundColor Green
                }
            } elseif ($record.NameHost) {
                Write-Host "  - CNAME: $($record.NameHost)" -ForegroundColor White
                
                # Check if it's a CloudFront domain
                if ($record.NameHost -like "*.cloudfront.net") {
                    Write-Host "    (CloudFront domain)" -ForegroundColor Green
                }
            }
        }
        
        return $true
    } catch {
        Write-Host "❌ Could not resolve DNS for $domain" -ForegroundColor Red
        return $false
    }
}

# Function to check for domain forwarding
function Test-Forwarding {
    param (
        [string]$sourceUrl,
        [string]$expectedDestination
    )
    
    Write-Host "`nChecking if $sourceUrl forwards to $expectedDestination..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri $sourceUrl -MaximumRedirection 0 -ErrorAction SilentlyContinue
        Write-Host "❌ No forwarding detected (status code: $($response.StatusCode))" -ForegroundColor Red
        return $false
    } catch {
        if ($_.Exception.Response.StatusCode.Value__ -eq 301 -or $_.Exception.Response.StatusCode.Value__ -eq 302) {
            $location = $_.Exception.Response.Headers.Location
            Write-Host "✅ Forwarding detected!" -ForegroundColor Green
            Write-Host "  - Redirects to: $location" -ForegroundColor White
            
            if ($location -like "*$expectedDestination*") {
                Write-Host "  - Correctly forwarding to expected destination" -ForegroundColor Green
                return $true
            } else {
                Write-Host "  - Warning: Forwarding to unexpected destination" -ForegroundColor Yellow
                return $false
            }
        } else {
            Write-Host "❌ Error checking forwarding: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
}

# Check CloudFront distribution
Write-Host "CLOUDFRONT DISTRIBUTION:" -ForegroundColor Cyan
Write-Host "------------------------" -ForegroundColor Cyan

if (Test-Path ".\cloudfront-info.txt") {
    $cloudFrontInfo = Get-Content -Path ".\cloudfront-info.txt" -Raw
    
    if ($cloudFrontInfo -match "Distribution Domain: (.+)") {
        $distributionDomain = $matches[1].Trim()
        Write-Host "CloudFront Domain: $distributionDomain" -ForegroundColor White
        
        # Test CloudFront URL
        $cloudFrontUrl = "https://$distributionDomain"
        Test-Website -url $cloudFrontUrl -description "CloudFront URL"
    }
}

# Check DNS configuration
Test-DNS -domain $domainName
Test-DNS -domain $wwwDomain

# Check forwarding if configured
Test-Forwarding -sourceUrl "http://$domainName" -expectedDestination $wwwDomain

# Test website accessibility
Write-Host "`nWEBSITE ACCESSIBILITY:" -ForegroundColor Cyan
Write-Host "---------------------" -ForegroundColor Cyan

$rootAccess = Test-Website -url "https://$domainName" -description "Root domain"
$wwwAccess = Test-Website -url "https://$wwwDomain" -description "WWW subdomain"

# Summary
Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host "   SUMMARY   " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

if ($rootAccess -and $wwwAccess) {
    Write-Host "✅ Your website is fully accessible!" -ForegroundColor Green
    Write-Host "Both https://$domainName and https://$wwwDomain are working." -ForegroundColor Green
} elseif ($rootAccess -or $wwwAccess) {
    Write-Host "⚠️ Your website is partially accessible." -ForegroundColor Yellow
    if (-not $rootAccess) {
        Write-Host "❌ https://$domainName is NOT accessible" -ForegroundColor Red
    }
    if (-not $wwwAccess) {
        Write-Host "❌ https://$wwwDomain is NOT accessible" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Your website is NOT accessible!" -ForegroundColor Red
}

Write-Host "`nTo share your website publicly, use:" -ForegroundColor Cyan
Write-Host "https://$domainName" -ForegroundColor White
Write-Host "or" -ForegroundColor White
Write-Host "https://$wwwDomain" -ForegroundColor White
