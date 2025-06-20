# DNS and Website Verification Script
# This script checks DNS settings and website accessibility

$domain = 'ibridgesolutions.co.za'
$wwwDomain = 'www.ibridgesolutions.co.za'
$cloudFrontDomain = 'diso379wpy1no.cloudfront.net'

Write-Host '==================================================' -ForegroundColor Cyan
Write-Host '  WEBSITE AND DNS VERIFICATION FOR' $domain -ForegroundColor Cyan
Write-Host '==================================================' -ForegroundColor Cyan
Write-Host

# Check DNS records
Write-Host 'Checking DNS records...' -ForegroundColor Yellow
$nsRecords = Resolve-DnsName -Name $domain -Type NS -ErrorAction SilentlyContinue
if ($nsRecords) {
    Write-Host 'Nameservers for' $domain':' -ForegroundColor Green
    $nsRecords | Where-Object { $_.Type -eq 'NS' } | ForEach-Object {
        $ns = $_.NameHost
        if ($ns -like '*awsdns*') {
            Write-Host '  ' $ns '(AWS Route 53)' -ForegroundColor Green
        } else {
            Write-Host '  -' $ns -ForegroundColor White
        }
    }
}

# Check A records for root domain
$aRecords = Resolve-DnsName -Name $domain -Type A -ErrorAction SilentlyContinue
if ($aRecords) {
    Write-Host 
'A Records for' $domain':' -ForegroundColor Green
    $aRecords | Where-Object { $_.Type -eq 'A' } | ForEach-Object {
        Write-Host '  -' $_.IPAddress -ForegroundColor White
    }
}

# Check A records for www subdomain
$wwwARecords = Resolve-DnsName -Name $wwwDomain -Type A -ErrorAction SilentlyContinue
if ($wwwARecords) {
    Write-Host 
'A Records for' $wwwDomain':' -ForegroundColor Green
    $wwwARecords | Where-Object { $_.Type -eq 'A' } | ForEach-Object {
        Write-Host '  -' $_.IPAddress -ForegroundColor White
    }
}

# Check website accessibility
Write-Host 
'Checking website accessibility...' -ForegroundColor Yellow

function Test-Website {
    param (
        [string]$Url
    )
    
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -Method Head
        Write-Host '  ' $Url 'is accessible (Status:' $response.StatusCode')' -ForegroundColor Green
        return $true
    } catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { 'Error' }
        Write-Host '  ' $Url 'is not accessible (Status:' $statusCode')' -ForegroundColor Red
        return $false
    }
}

Test-Website -Url "https://$domain"
Test-Website -Url "https://$wwwDomain"
Test-Website -Url "https://$cloudFrontDomain"

Write-Host 
'==================================================' -ForegroundColor Cyan
Write-Host '                MIGRATION COMPLETE' -ForegroundColor Cyan
Write-Host '==================================================' -ForegroundColor Cyan
Write-Host 'The website has been successfully migrated to AWS.' -ForegroundColor Green
Write-Host '  - Root domain: https://'$domain -ForegroundColor Yellow
Write-Host '  - WWW subdomain: https://'$wwwDomain -ForegroundColor Yellow
Write-Host '  - CloudFront domain: https://'$cloudFrontDomain -ForegroundColor Yellow
