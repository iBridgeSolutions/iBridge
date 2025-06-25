# Test Custom Domain for iBridgeSolutions.co.za
# This script checks if your custom domain is properly configured and accessible

$domain = "ibridgesolutions.co.za"
$wwwDomain = "www.$domain"

Write-Host "=== Custom Domain Test for $domain ===" -ForegroundColor Cyan
Write-Host "This script will check if your custom domain is properly connected to your GitHub Pages site" -ForegroundColor Cyan
Write-Host

# Function to test a URL
function Test-URL {
    param (
        [string]$URL
    )
    
    try {
        $request = [System.Net.WebRequest]::Create($URL)
        $request.AllowAutoRedirect = $false
        $request.Timeout = 5000
        
        $response = $request.GetResponse()
        $statusCode = [int]$response.StatusCode
        $headers = $response.Headers
        $serverHeader = $headers["Server"]
        
        $response.Close()
        
        return @{
            Success = $true
            StatusCode = $statusCode
            Server = $serverHeader
        }
    }
    catch [System.Net.WebException] {
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            return @{
                Success = $false
                StatusCode = $statusCode
                ErrorMessage = $_.Exception.Message
            }
        } else {
            return @{
                Success = $false
                StatusCode = 0
                ErrorMessage = $_.Exception.Message
            }
        }
    }
    catch {
        return @{
            Success = $false
            StatusCode = 0
            ErrorMessage = $_.Exception.Message
        }
    }
}

# Test HTTP access
Write-Host "Testing HTTP access to $domain..." -ForegroundColor Yellow
$httpResult = Test-URL -URL "http://$domain"

if ($httpResult.Success) {
    if ($httpResult.StatusCode -eq 301) {
        Write-Host "  ✓ HTTP redirects to HTTPS (301 redirect)" -ForegroundColor Green
    } else {
        Write-Host "  ✓ HTTP is accessible (Status code: $($httpResult.StatusCode))" -ForegroundColor Green
    }
} else {
    Write-Host "  ✗ HTTP access failed: $($httpResult.ErrorMessage)" -ForegroundColor Red
}

# Test HTTPS access
Write-Host "`nTesting HTTPS access to $domain..." -ForegroundColor Yellow
$httpsResult = Test-URL -URL "https://$domain"

if ($httpsResult.Success) {
    Write-Host "  ✓ HTTPS is working correctly (Status code: $($httpsResult.StatusCode))" -ForegroundColor Green
    if ($httpsResult.Server -like "*GitHub*") {
        Write-Host "  ✓ Server is GitHub Pages: $($httpsResult.Server)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Server doesn't seem to be GitHub Pages: $($httpsResult.Server)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✗ HTTPS access failed: $($httpsResult.ErrorMessage)" -ForegroundColor Red
    Write-Host "  ⚠ This may indicate HTTPS is not yet enabled in GitHub Pages settings or still being provisioned" -ForegroundColor Yellow
}

# Test www subdomain
Write-Host "`nTesting www subdomain (www.$domain)..." -ForegroundColor Yellow
$wwwResult = Test-URL -URL "https://$wwwDomain"

if ($wwwResult.Success) {
    Write-Host "  ✓ www subdomain is working (Status code: $($wwwResult.StatusCode))" -ForegroundColor Green
} else {
    Write-Host "  ✗ www subdomain access failed: $($wwwResult.ErrorMessage)" -ForegroundColor Red
}

# Summary and Next Steps
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($httpsResult.Success) {
    Write-Host "✅ Your custom domain appears to be working correctly!" -ForegroundColor Green
    Write-Host "`nNext steps:"
    Write-Host "1. Confirm that your website content loads properly at https://$domain"
    Write-Host "2. Ensure HTTPS is enforced in GitHub Pages settings"
    Write-Host "3. Test navigation across different pages of your website"
} else {
    Write-Host "⚠ Your custom domain is not fully configured yet." -ForegroundColor Yellow
    Write-Host "`nPossible reasons:"
    Write-Host "1. DNS propagation is still in progress (can take 24-48 hours)"
    Write-Host "2. DNS records are not configured correctly"
    Write-Host "3. GitHub Pages settings need to be updated"
    Write-Host "4. HTTPS certificate is still being provisioned by GitHub"
    Write-Host "`nRecommended actions:"
    Write-Host "1. Run the check-dns-propagation.ps1 script to verify DNS settings"
    Write-Host "2. Check GitHub Repository → Settings → Pages to ensure custom domain is set"
    Write-Host "3. Wait 24-48 hours for DNS changes and HTTPS provisioning to complete"
}
