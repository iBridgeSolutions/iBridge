# DNS Configuration Check Script
# This script verifies if the DNS for ibridgesolutions.co.za is pointing to CloudFront

$domainName = "ibridgesolutions.co.za"
$wwwDomainName = "www.ibridgesolutions.co.za"
$expectedCloudFrontDomain = "diso379wpy1no.cloudfront.net"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "        DNS CONFIGURATION CHECK FOR IBRIDGESOLUTIONS" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Domain: $domainName" -ForegroundColor Yellow
Write-Host "Expected CloudFront: $expectedCloudFrontDomain" -ForegroundColor Yellow
Write-Host

# Function to check a domain
function Check-Domain {
    param (
        [Parameter(Mandatory=$true)][string]$Domain
    )
    
    Write-Host "Checking $Domain..." -ForegroundColor Yellow
    
    try {
        # Try to resolve the hostname
        $dnsResult = Resolve-DnsName -Name $Domain -Type CNAME -ErrorAction SilentlyContinue
        
        if ($dnsResult) {
            $target = $dnsResult.NameHost
            if ($target -like "*$expectedCloudFrontDomain*") {
                Write-Host "✓ $Domain correctly points to CloudFront ($target)" -ForegroundColor Green
                return $true
            } else {
                Write-Host "✗ $Domain points to $target (expected: $expectedCloudFrontDomain)" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "✗ Could not resolve CNAME for $Domain" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "✗ Error checking $Domain: $_" -ForegroundColor Red
        return $false
    }
}

# Check both domains
$rootOk = Check-Domain -Domain $domainName
$wwwOk = Check-Domain -Domain $wwwDomainName

Write-Host "`nSummary:" -ForegroundColor Cyan
if ($rootOk -and $wwwOk) {
    Write-Host "✓ DNS configuration is correct! Both domains point to CloudFront." -ForegroundColor Green
    Write-Host "  You can now verify the website is accessible by visiting:" -ForegroundColor Green
    Write-Host "  - https://$domainName" -ForegroundColor Green 
    Write-Host "  - https://$wwwDomainName" -ForegroundColor Green
    Write-Host "  - https://$domainName/lander (to test the redirect fix)" -ForegroundColor Green
} else {
    Write-Host "✗ DNS configuration is not complete." -ForegroundColor Red
    Write-Host "`nPlease update your DNS settings:" -ForegroundColor Yellow
    
    if (!$rootOk) {
        Write-Host "  For root domain ($domainName):" -ForegroundColor Yellow
        Write-Host "  - Type: CNAME" -ForegroundColor White
        Write-Host "  - Host: @ (or leave blank)" -ForegroundColor White
        Write-Host "  - Points to: $expectedCloudFrontDomain" -ForegroundColor White
        Write-Host "  - TTL: 1 Hour" -ForegroundColor White
        Write-Host "  NOTE: If GoDaddy doesn't allow CNAME for root domains, consider using Route 53." -ForegroundColor White
    }
    
    if (!$wwwOk) {
        Write-Host "`n  For www subdomain ($wwwDomainName):" -ForegroundColor Yellow
        Write-Host "  - Type: CNAME" -ForegroundColor White
        Write-Host "  - Host: www" -ForegroundColor White
        Write-Host "  - Points to: $expectedCloudFrontDomain" -ForegroundColor White
        Write-Host "  - TTL: 1 Hour" -ForegroundColor White
    }
    
    Write-Host "`nSee 'GoDaddy-to-AWS-DNS-Guide.md' for detailed instructions." -ForegroundColor Cyan
}

Write-Host "`nRemember: DNS changes can take 24-48 hours to fully propagate worldwide." -ForegroundColor Yellow
