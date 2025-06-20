# Check iBridge Website Deployment Status

Write-Host "=== iBridge Website Deployment Status Checker ===" -ForegroundColor Cyan

# Check if the website is accessible
function Test-Website {
    param (
        [string]$URL
    )
    
    try {
        $response = Invoke-WebRequest -Uri $URL -UseBasicParsing -TimeoutSec 15
        return @{
            Success = $true
            StatusCode = $response.StatusCode
            ResponseLength = $response.Content.Length
        }
    }
    catch [System.Net.WebException] {
        if ($_.Exception.Response) {
            return @{
                Success = $false
                StatusCode = $_.Exception.Response.StatusCode
                Error = $_.Exception.Message
            }
        }
        else {
            return @{
                Success = $false
                Error = $_.Exception.Message
            }
        }
    }
}

# Check DNS settings for the domain
function Check-DNS {
    param (
        [string]$Domain
    )
    
    Write-Host "`nChecking DNS records for $Domain..." -ForegroundColor Yellow
    
    # Check A records
    try {
        $aRecords = Resolve-DnsName -Name $Domain -Type A -ErrorAction SilentlyContinue
        if ($aRecords) {
            Write-Host "A records found:" -ForegroundColor Green
            $aRecords | ForEach-Object {
                if ($_.Type -eq "A") {
                    Write-Host "  - $($_.IPAddress)" -ForegroundColor White
                }
            }
        } else {
            Write-Host "No A records found." -ForegroundColor Red
        }
    } catch {
        Write-Host "Error checking A records: $_" -ForegroundColor Red
    }
    
    # Check CNAME record for www subdomain
    try {
        $cnameRecord = Resolve-DnsName -Name "www.$Domain" -Type CNAME -ErrorAction SilentlyContinue
        if ($cnameRecord) {
            Write-Host "CNAME record for www subdomain:" -ForegroundColor Green
            $cnameRecord | ForEach-Object {
                if ($_.Type -eq "CNAME") {
                    Write-Host "  - $($_.NameHost)" -ForegroundColor White
                }
            }
        } else {
            Write-Host "No CNAME record found for www subdomain." -ForegroundColor Red
        }
    } catch {
        Write-Host "Error checking CNAME record: $_" -ForegroundColor Red
    }
}

# Check website status
$domain = "ibridgesolutions.co.za"
Write-Host "`nChecking website status for $domain..." -ForegroundColor Yellow

# Check without redirect
$mainResult = Test-Website -URL "https://$domain"
if ($mainResult.Success) {
    Write-Host "Main website is UP! Status code: $($mainResult.StatusCode)" -ForegroundColor Green
    Write-Host "Response size: $($mainResult.ResponseLength) bytes" -ForegroundColor Green
} else {
    Write-Host "Main website is DOWN. Error: $($mainResult.Error)" -ForegroundColor Red
    Write-Host "Status code: $($mainResult.StatusCode)" -ForegroundColor Red
}

# Check www subdomain
$wwwResult = Test-Website -URL "https://www.$domain"
if ($wwwResult.Success) {
    Write-Host "www subdomain is UP! Status code: $($wwwResult.StatusCode)" -ForegroundColor Green
} else {
    Write-Host "www subdomain is not responding. Error: $($wwwResult.Error)" -ForegroundColor Yellow
    Write-Host "This may be normal if the SSL certificate is still being provisioned." -ForegroundColor Yellow
}

# Check if /lander redirect still exists
$landerResult = Test-Website -URL "https://$domain/lander"
if ($landerResult.Success) {
    Write-Host "WARNING: The /lander page is still accessible." -ForegroundColor Yellow
    Write-Host "This may indicate the redirection fix is not yet fully effective." -ForegroundColor Yellow
} else {
    Write-Host "Good! The /lander page is not accessible (404 error expected)." -ForegroundColor Green
}

# Check DNS settings
Check-DNS -Domain $domain

# Provide next steps
Write-Host "`n=== Summary and Next Steps ===" -ForegroundColor Cyan

if ($mainResult.Success) {
    Write-Host "- Website appears to be UP and RUNNING!" -ForegroundColor Green
    Write-Host "- Check the content to make sure it displays correctly" -ForegroundColor White
    
    if ($landerResult.Success) {
        Write-Host "- You may still need to disable GoDaddy's website redirects or default pages" -ForegroundColor Yellow
        Write-Host "  Log in to GoDaddy and check domain forwarding settings" -ForegroundColor Yellow
    }
    
    Write-Host "`nTo verify DNS configuration is correct for GitHub Pages:" -ForegroundColor White
    Write-Host "1. A records should point to GitHub IPs (185.199.108.153, 185.199.109.153, etc.)" -ForegroundColor White
    Write-Host "2. CNAME for www should point to blxckukno.github.io" -ForegroundColor White
    
    Write-Host "`nTo verify GitHub Pages settings:" -ForegroundColor White
    Write-Host "1. Go to https://github.com/Blxckukno/iBridge/settings/pages" -ForegroundColor White
    Write-Host "2. Check that Custom domain is set to ibridgesolutions.co.za" -ForegroundColor White
    Write-Host "3. Make sure 'Enforce HTTPS' is checked if available" -ForegroundColor White
} else {
    Write-Host "- Website is currently DOWN or not accessible" -ForegroundColor Red
    Write-Host "- Check your GitHub repository and Pages settings" -ForegroundColor Yellow
    Write-Host "- Verify DNS configuration in GoDaddy" -ForegroundColor Yellow
    Write-Host "- It may take up to 24 hours for changes to fully propagate" -ForegroundColor Yellow
    
    Write-Host "`nFor DNS issues, go to GoDaddy account and verify:" -ForegroundColor White
    Write-Host "1. A records are correctly pointing to GitHub Pages IPs" -ForegroundColor White
    Write-Host "2. CNAME record for www is correctly configured" -ForegroundColor White
    Write-Host "3. No website forwarding or redirection is enabled" -ForegroundColor White
}

Write-Host "`nRemember that DNS changes and GitHub Pages updates can take up to 24 hours to fully propagate." -ForegroundColor Cyan
