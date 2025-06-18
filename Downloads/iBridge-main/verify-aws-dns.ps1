# DNS Verification Script for AWS Deployment

function Get-NameserverInfo {
    param(
        [string]$Domain = "ibridgesolutions.co.za"
    )
    
    Write-Host "`nChecking current nameservers for $Domain..." -ForegroundColor Yellow
    
    try {
        $nsRecords = Resolve-DnsName -Name $Domain -Type NS -ErrorAction Stop
        
        Write-Host "Current nameservers:" -ForegroundColor Green
        foreach ($record in $nsRecords | Where-Object { $_.Type -eq "NS" }) {
            $nsName = $record.NameHost
            
            # Check if this is likely an AWS Route 53 nameserver
            $isAwsNs = $nsName -like "*.awsdns-*.*"
            
            if ($isAwsNs) {
                Write-Host "  ✓ $nsName" -ForegroundColor Green -NoNewline
                Write-Host " (AWS Route 53)" -ForegroundColor Cyan
            } else {
                Write-Host "  ✗ $nsName" -ForegroundColor Red -NoNewline
                Write-Host " (Not AWS Route 53)" -ForegroundColor Yellow
            }
        }
        
        # Determine if migration to AWS is complete
        $awsNsCount = ($nsRecords | Where-Object { $_.Type -eq "NS" -and $_.NameHost -like "*.awsdns-*.*" }).Count
        $totalNsCount = ($nsRecords | Where-Object { $_.Type -eq "NS" }).Count
        
        if ($awsNsCount -eq $totalNsCount -and $totalNsCount -gt 0) {
            Write-Host "`nNameserver Status: " -NoNewline
            Write-Host "GOOD - All nameservers are pointing to AWS Route 53" -ForegroundColor Green
        }
        elseif ($awsNsCount -gt 0) {
            Write-Host "`nNameserver Status: " -NoNewline
            Write-Host "IN PROGRESS - Some nameservers are pointing to AWS Route 53" -ForegroundColor Yellow
            Write-Host "DNS is still propagating. This can take 24-48 hours." -ForegroundColor Yellow
        }
        else {
            Write-Host "`nNameserver Status: " -NoNewline
            Write-Host "NOT STARTED - No AWS Route 53 nameservers found" -ForegroundColor Red
            Write-Host "You need to update your nameservers at GoDaddy to point to AWS Route 53." -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error checking nameservers: $_" -ForegroundColor Red
    }
}

function Get-ARecordInfo {
    param(
        [string]$Domain = "ibridgesolutions.co.za"
    )
    
    Write-Host "`nChecking A records for $Domain..." -ForegroundColor Yellow
    
    try {
        $aRecords = Resolve-DnsName -Name $Domain -Type A -ErrorAction SilentlyContinue
        
        if ($aRecords) {
            Write-Host "Current A records:" -ForegroundColor Green
            
            $cloudFrontIps = @(
                # These are common CloudFront edge IPs but can vary
                # The important part is that they're not the GitHub Pages IPs
                "13.32.", "13.33.", "13.35.", "52.84.", "52.85.", "52.86.", "52.222.", "52.223.", 
                "54.182.", "54.192.", "54.230.", "54.239.", "54.240.", "99.84.", "99.86.",
                "18.64.", "18.65.", "18.66.", "205.251."
            )
            
            $githubIps = @(
                "185.199.108.153",
                "185.199.109.153",
                "185.199.110.153",
                "185.199.111.153"
            )
            
            foreach ($record in $aRecords | Where-Object { $_.Type -eq "A" }) {
                $ip = $record.IPAddress
                
                $isCloudFront = $false
                foreach ($prefix in $cloudFrontIps) {
                    if ($ip.StartsWith($prefix)) {
                        $isCloudFront = $true
                        break
                    }
                }
                
                $isGitHub = $githubIps -contains $ip
                
                if ($isCloudFront) {
                    Write-Host "  ✓ $ip" -ForegroundColor Green -NoNewline
                    Write-Host " (likely AWS CloudFront)" -ForegroundColor Cyan
                }
                elseif ($isGitHub) {
                    Write-Host "  ✗ $ip" -ForegroundColor Red -NoNewline
                    Write-Host " (GitHub Pages)" -ForegroundColor Yellow
                }
                else {
                    Write-Host "  ? $ip" -ForegroundColor Yellow -NoNewline
                    Write-Host " (unknown)" -ForegroundColor Gray
                }
            }
        }
        else {
            Write-Host "No A records found for $Domain" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error checking A records: $_" -ForegroundColor Red
    }
}

function Get-CloudFrontDistribution {
    param(
        [string]$Domain = "ibridgesolutions.co.za"
    )
    
    Write-Host "`nChecking domain's CloudFront connection..." -ForegroundColor Yellow
    
    # Try to resolve CNAME record for potential CloudFront distribution
    try {
        # Function to check HTTP response and look for CloudFront headers
        function Test-CloudFrontHeaders {
            param ([string]$Url)
            
            try {
                $request = [System.Net.WebRequest]::Create($Url)
                $request.Method = "HEAD"
                $request.Timeout = 5000
                $response = $request.GetResponse()
                
                $server = $response.Headers["Server"]
                $cfRay = $response.Headers["cf-ray"]
                $xCache = $response.Headers["X-Cache"]
                $viaCdn = $response.Headers["Via"]
                
                if ($server -eq "CloudFront" -or $xCache -like "*CloudFront*" -or $viaCdn -like "*CloudFront*") {
                    return $true
                }
                return $false
            }
            catch {
                return $false
            }
        }
        
        $hasCloudFront = Test-CloudFrontHeaders -Url "https://$Domain"
        $hasCloudFrontWWW = Test-CloudFrontHeaders -Url "https://www.$Domain"
        
        if ($hasCloudFront) {
            Write-Host "  ✓ CloudFront detected on https://$Domain" -ForegroundColor Green
        }
        elseif (Test-CloudFrontHeaders -Url "http://$Domain") {
            Write-Host "  ! CloudFront detected on http://$Domain but not on HTTPS" -ForegroundColor Yellow
            Write-Host "    SSL certificate might not be properly configured" -ForegroundColor Yellow
        }
        else {
            Write-Host "  ✗ No CloudFront detected on $Domain" -ForegroundColor Red
        }
        
        if ($hasCloudFrontWWW) {
            Write-Host "  ✓ CloudFront detected on https://www.$Domain" -ForegroundColor Green
        }
        elseif (Test-CloudFrontHeaders -Url "http://www.$Domain") {
            Write-Host "  ! CloudFront detected on http://www.$Domain but not on HTTPS" -ForegroundColor Yellow
        }
        else {
            Write-Host "  ✗ No CloudFront detected on www.$Domain" -ForegroundColor Red
        }
        
        if ($hasCloudFront -or $hasCloudFrontWWW) {
            Write-Host "`nTo get your CloudFront Distribution ID:" -ForegroundColor Yellow
            Write-Host "1. Log in to AWS Console" -ForegroundColor White
            Write-Host "2. Navigate to CloudFront service" -ForegroundColor White
            Write-Host "3. Find the distribution associated with $Domain" -ForegroundColor White
            Write-Host "4. Copy the Distribution ID to use in the deployment script" -ForegroundColor White
        }
    }
    catch {
        Write-Host "Error checking CloudFront: $_" -ForegroundColor Red
    }
}

function Test-WebsiteAccess {
    param(
        [string]$Domain = "ibridgesolutions.co.za"
    )
    
    Write-Host "`nTesting website access..." -ForegroundColor Yellow
    
    function Test-Url {
        param(
            [string]$Url,
            [string]$Description
        )
        
        try {
            $request = [System.Net.WebRequest]::Create($Url)
            $request.Timeout = 10000  # 10-second timeout
            $request.AllowAutoRedirect = $false  # Don't follow redirects
            $response = $request.GetResponse()
            
            $statusCode = [int]$response.StatusCode
            $statusDesc = $response.StatusDescription
            
            if ($statusCode -ge 200 -and $statusCode -lt 400) {
                Write-Host "  ✓ $Description ($statusCode $statusDesc)" -ForegroundColor Green
                
                # Check for content type
                $contentType = $response.ContentType
                if ($contentType -like "text/html*") {
                    Write-Host "    Content-Type: $contentType" -ForegroundColor Green
                }
            }
            else {
                Write-Host "  ! $Description ($statusCode $statusDesc)" -ForegroundColor Yellow
            }
            
            # Check for redirects
            if ($response.ResponseUri.ToString() -ne $Url) {
                Write-Host "    Redirects to: $($response.ResponseUri)" -ForegroundColor Yellow
                
                # Check specifically for /lander redirect
                if ($response.ResponseUri.ToString().Contains("/lander")) {
                    Write-Host "    ✗ Redirecting to /lander - GoDaddy's default page is still active!" -ForegroundColor Red
                }
            }
            
            $response.Close()
        }
        catch [System.Net.WebException] {
            $statusCode = [int]$_.Exception.Response.StatusCode
            $statusDesc = $_.Exception.Response.StatusDescription
            
            if ($statusCode) {
                Write-Host "  ✗ $Description ($statusCode $statusDesc)" -ForegroundColor Red
            }
            else {
                Write-Host "  ✗ $Description (Connection failed: $($_.Exception.Message))" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "  ✗ $Description (Error: $($_.Exception.Message))" -ForegroundColor Red
        }
    }
    
    Test-Url -Url "http://$Domain" -Description "HTTP access"
    Test-Url -Url "https://$Domain" -Description "HTTPS access"
    Test-Url -Url "http://www.$Domain" -Description "HTTP www subdomain"
    Test-Url -Url "https://www.$Domain" -Description "HTTPS www subdomain"
}

# Main script
Clear-Host
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "  DNS Verification for AWS Deployment of ibridgesolutions.co.za" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan

# Get domain name
$domain = "ibridgesolutions.co.za"
$customDomain = Read-Host "Enter your domain (default: $domain)"
if (-not [string]::IsNullOrWhiteSpace($customDomain)) {
    $domain = $customDomain
}

# Run checks
Get-NameserverInfo -Domain $domain
Get-ARecordInfo -Domain $domain
Get-CloudFrontDistribution -Domain $domain
Test-WebsiteAccess -Domain $domain

Write-Host "`nVerification complete! Please address any issues reported above.`n" -ForegroundColor Cyan

# Show next steps based on results
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. If nameservers are not pointed to AWS Route 53, update them in GoDaddy" -ForegroundColor White
Write-Host "2. If A records don't point to CloudFront, check your Route 53 configuration" -ForegroundColor White
Write-Host "3. If website access fails, verify S3 bucket configuration and CloudFront settings" -ForegroundColor White
Write-Host "4. Remember DNS changes can take 24-48 hours to fully propagate" -ForegroundColor White
Write-Host "`nRefer to aws-free-hosting-plan.md for detailed instructions." -ForegroundColor Cyan

Write-Host "`nPress any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
