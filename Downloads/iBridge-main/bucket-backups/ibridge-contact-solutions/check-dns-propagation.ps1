# DNS Propagation Check Script for iBridgeSolutions.co.za
# This script checks if your DNS settings are properly configured for AWS CloudFront

$domain = "ibridgesolutions.co.za"
$wwwDomain = "www.ibridgesolutions.co.za"

# Get CloudFront domain from info file
$cloudFrontInfo = Get-Content -Path "cloudfront-info.txt" -Raw -ErrorAction SilentlyContinue
$cloudFrontDomain = if ($cloudFrontInfo -match "Distribution Domain: (.+)$") {
    $matches[1].Trim()
} else {
    "diso379wpy1no.cloudfront.net"  # Default from our previous setup
}

Write-Host "=== DNS Propagation Check for $domain ===" -ForegroundColor Cyan
Write-Host "This script checks if your DNS settings are correctly pointing to AWS CloudFront" -ForegroundColor Cyan
Write-Host "Expected CloudFront domain: $cloudFrontDomain" -ForegroundColor Yellow
Write-Host

# Function to check DNS records
function Check-DNSRecord {
    param (
        [string]$Domain,
        [string]$RecordType
    )
    
    try {
        $dnsRecords = Resolve-DnsName -Name $Domain -Type $RecordType -ErrorAction SilentlyContinue
        return $dnsRecords
    }
    catch {
        return $null
    }
}

# Check for Route 53 nameservers (if migrated to Route 53)
$isUsingRoute53 = $false
try {
    $nsRecords = Check-DNSRecord -Domain $domain -RecordType "NS"
    if ($nsRecords) {
        $nameservers = $nsRecords | Where-Object { $_.Type -eq "NS" } | Select-Object -ExpandProperty NameHost
        
        Write-Host "Current nameservers for $domain" -ForegroundColor Cyan
        foreach ($ns in $nameservers) {
            if ($ns -like "*awsdns*") {
                $isUsingRoute53 = $true
                Write-Host "  - $ns ✓ (AWS Route 53)" -ForegroundColor Green
            } else {
                Write-Host "  - $ns" -ForegroundColor White
            }
        }
        
        if ($isUsingRoute53) {
            Write-Host "`n✓ Domain is using Route 53 nameservers" -ForegroundColor Green
        } else {
            Write-Host "`nDomain is not using Route 53 nameservers (using GoDaddy or other provider)" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "Could not check nameservers: $_" -ForegroundColor Red
} # End of try for Route 53 nameservers

# Check ROOT domain records
Write-Host "`nChecking records for ROOT domain ($domain)..." -ForegroundColor Cyan

# First check CNAME (if using GoDaddy)
$rootCname = Check-DNSRecord -Domain $domain -RecordType "CNAME"
if ($rootCname -and !$isUsingRoute53) {
    $cname = $rootCname | Where-Object { $_.Type -eq "CNAME" } | Select-Object -ExpandProperty NameHost -ErrorAction SilentlyContinue
    if ($cname) {
        Write-Host "Found CNAME for root domain: $cname" -ForegroundColor Green
        if ($cname -like "*$cloudFrontDomain*") {
            Write-Host "  ✓ Root domain CNAME correctly points to CloudFront" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Root domain CNAME does not point to CloudFront (Expected: $cloudFrontDomain)" -ForegroundColor Red
        }
    }
}

# Check A records (could be GoDaddy or Route 53)
$aRecords = Check-DNSRecord -Domain $domain -RecordType "A"
if ($aRecords) {
    $foundIPs = $aRecords | Where-Object { $_.Type -eq "A" } | Select-Object -ExpandProperty IPAddress -ErrorAction SilentlyContinue
    
    if ($foundIPs) {
        Write-Host "Found A Records for root domain:" -ForegroundColor Green
        foreach ($ip in $foundIPs) {
            Write-Host "  - $ip" -ForegroundColor White
        }
        
        # If using Route 53, A records should be AWS IPs (we can't easily validate these)
        if ($isUsingRoute53) {
            Write-Host "  These appear to be CloudFront IPs (good)" -ForegroundColor Green
        } else {
            Write-Host "  The root domain is using A records instead of CNAME." -ForegroundColor Yellow
        }
    }
}

if (!$rootCname -and !$aRecords) {
    Write-Host "✗ No valid records found for the root domain." -ForegroundColor Red
}

# Check WWW subdomain records
Write-Host "`nChecking records for WWW subdomain ($wwwDomain)..." -ForegroundColor Cyan
$wwwCname = Check-DNSRecord -Domain $wwwDomain -RecordType "CNAME"

if ($wwwCname) {
    $cname = $wwwCname | Where-Object { $_.Type -eq "CNAME" } | Select-Object -ExpandProperty NameHost -ErrorAction SilentlyContinue
    
    if ($cname) {
        Write-Host "Found CNAME for www subdomain: $cname" -ForegroundColor Green
        
        if ($cname -like "*$cloudFrontDomain*") {
            Write-Host "  ✓ WWW subdomain correctly points to CloudFront" -ForegroundColor Green
        } else {
            Write-Host "  ✗ WWW subdomain does not point to CloudFront (Expected: $cloudFrontDomain)" -ForegroundColor Red
        }
    }
} else {
    # Check for A records as an alternative
    $wwwARecords = Check-DNSRecord -Domain $wwwDomain -RecordType "A"
    
    if ($wwwARecords) {
        $foundIPs = $wwwARecords | Where-Object { $_.Type -eq "A" } | Select-Object -ExpandProperty IPAddress -ErrorAction SilentlyContinue
        
        if ($foundIPs) {
            Write-Host "Found A Records for www subdomain:" -ForegroundColor Yellow
            foreach ($ip in $foundIPs) {
                Write-Host "  - $ip" -ForegroundColor White
            }
            
            if ($isUsingRoute53) {
                Write-Host "  These appear to be CloudFront IPs (good)" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "✗ No DNS records found for www subdomain" -ForegroundColor Red
    }
}

# Check website accessibility
function Try-Website {
    param (
        [string]$Url
    )
    try {
        $request = [System.Net.WebRequest]::Create($Url)
        $request.Method = "HEAD"
        $request.Timeout = 5000
        try {
            $response = $request.GetResponse()
            $statusCode = [int]$response.StatusCode
            $response.Close()
            Write-Host "  ✓ $Url is accessible (Status: $statusCode)" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "  ✗ Cannot access $Url" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  ✗ Error occurred while checking $Url" -ForegroundColor Red
        return $false
    }
}

Write-Host "`nChecking website accessibility..." -ForegroundColor Cyan
Try-Website -Url "https://$domain"
Try-Website -Url "https://$wwwDomain"
Try-Website -Url "https://$domain/index.html"  # Testing the problematic /lander path

Write-Host "`nNote: DNS changes can take 24-48 hours to fully propagate around the world." -ForegroundColor Yellow
Write-Host "If your DNS settings are correct but the website isn't accessible yet, please be patient." -ForegroundColor Yellow
Write-Host "  - https://dnschecker.org/" -ForegroundColor Yellow

